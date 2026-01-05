//
//  RequestViewModel.swift
//  RainyPost
//
//  Created by Fer on 1/4/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class RequestViewModel: ObservableObject {
    // Request Properties
    @Published var name: String
    @Published var method: HTTPMethod
    @Published var url: String
    @Published var queryParams: [KeyValueItem] = []
    @Published var headers: [KeyValueItem] = []
    @Published var authType: AuthType = .none
    @Published var authToken: String = ""
    @Published var authUsername: String = ""
    @Published var authPassword: String = ""
    @Published var apiKeyName: String = ""
    @Published var apiKeyValue: String = ""
    @Published var apiKeyLocation: APIKeyLocation = .header
    @Published var bodyType: BodyType = .none
    @Published var rawBody: String = ""
    @Published var rawContentType: RawContentType = .json
    @Published var formParams: [KeyValueItem] = []
    
    // UI State
    @Published var selectedTab: RequestTab = .params
    @Published var isLoading = false
    @Published var error: String?
    
    // Response
    @Published var response: HTTPResponse?
    
    // Environment reference for interpolation
    var activeEnvironment: APIEnvironment?
    var workspaceId: UUID?
    var historyService: HistoryService?
    
    private let httpEngine = HTTPEngine()
    private let interpolator = VariableInterpolator.shared
    private let originalRequest: Request
    
    init(request: Request) {
        self.originalRequest = request
        self.name = request.name
        self.method = request.method
        self.url = request.url
        
        // Convert headers
        self.headers = request.headers.map { KeyValueItem(key: $0.key, value: $0.value, isEnabled: $0.isEnabled) }
        
        // Convert query params
        self.queryParams = request.queryParams.map { KeyValueItem(key: $0.key, value: $0.value, isEnabled: $0.isEnabled) }
        
        // Load auth config
        if let auth = request.auth {
            switch auth {
            case .none:
                self.authType = .none
            case .bearer:
                self.authType = .bearer
            case .basic(let username, _):
                self.authType = .basic
                self.authUsername = username
            case .apiKey(let key, _, let location):
                self.authType = .apiKey
                self.apiKeyName = key
                self.apiKeyLocation = location
            case .manualOAuth:
                self.authType = .bearer
            }
        }
        
        // Load body
        if let body = request.body {
            switch body {
            case .none:
                self.bodyType = .none
            case .raw(let content, let contentType):
                self.bodyType = .raw
                self.rawBody = content
                self.rawContentType = contentType
            case .formUrlEncoded(let params):
                self.bodyType = .formUrlEncoded
                self.formParams = params.map { KeyValueItem(key: $0.key, value: $0.value, isEnabled: $0.isEnabled) }
            case .multipart:
                self.bodyType = .multipart
            }
        }
    }
    
    func sendRequest() async {
        guard !url.isEmpty else { return }
        
        isLoading = true
        error = nil
        response = nil
        
        defer { isLoading = false }
        
        do {
            let request = try buildURLRequest()
            response = try await httpEngine.execute(request)
            
            // Record to history
            if let workspaceId = workspaceId, let historyService = historyService {
                historyService.recordRequest(
                    requestId: originalRequest.id,
                    requestName: name,
                    url: url,
                    method: method.rawValue,
                    workspaceId: workspaceId,
                    response: response
                )
            }
        } catch {
            self.error = error.localizedDescription
            
            // Record failed request to history
            if let workspaceId = workspaceId, let historyService = historyService {
                historyService.recordRequest(
                    requestId: originalRequest.id,
                    requestName: name,
                    url: url,
                    method: method.rawValue,
                    workspaceId: workspaceId,
                    response: nil
                )
            }
        }
    }
    
    private func buildURLRequest() throws -> URLRequest {
        // Interpolate URL
        let interpolatedURL = try interpolator.interpolate(
            url,
            environment: activeEnvironment,
            requestVariables: originalRequest.variables
        )
        
        var urlString = interpolatedURL
        
        // Add query parameters
        let enabledParams = queryParams.filter { $0.isEnabled && !$0.key.isEmpty }
        if !enabledParams.isEmpty {
            var components = URLComponents(string: interpolatedURL) ?? URLComponents()
            components.queryItems = try enabledParams.map { param in
                let interpolatedKey = try interpolator.interpolate(param.key, environment: activeEnvironment)
                let interpolatedValue = try interpolator.interpolate(param.value, environment: activeEnvironment)
                return URLQueryItem(name: interpolatedKey, value: interpolatedValue)
            }
            urlString = components.url?.absoluteString ?? interpolatedURL
        }
        
        guard let requestURL = URL(string: urlString) else {
            throw HTTPEngineError.invalidURL
        }
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = method.rawValue
        
        // Add headers with interpolation
        for header in headers where header.isEnabled && !header.key.isEmpty {
            let interpolatedKey = try interpolator.interpolate(header.key, environment: activeEnvironment)
            let interpolatedValue = try interpolator.interpolate(header.value, environment: activeEnvironment)
            request.setValue(interpolatedValue, forHTTPHeaderField: interpolatedKey)
        }
        
        // Add auth with interpolation
        switch authType {
        case .none:
            break
        case .bearer:
            if !authToken.isEmpty {
                let interpolatedToken = try interpolator.interpolate(authToken, environment: activeEnvironment)
                request.setValue("Bearer \(interpolatedToken)", forHTTPHeaderField: "Authorization")
            }
        case .basic:
            let interpolatedUsername = try interpolator.interpolate(authUsername, environment: activeEnvironment)
            let interpolatedPassword = try interpolator.interpolate(authPassword, environment: activeEnvironment)
            let credentials = "\(interpolatedUsername):\(interpolatedPassword)"
            if let data = credentials.data(using: .utf8) {
                let base64 = data.base64EncodedString()
                request.setValue("Basic \(base64)", forHTTPHeaderField: "Authorization")
            }
        case .apiKey:
            let interpolatedValue = try interpolator.interpolate(apiKeyValue, environment: activeEnvironment)
            if apiKeyLocation == .header {
                request.setValue(interpolatedValue, forHTTPHeaderField: apiKeyName)
            }
        }
        
        // Add body with interpolation
        switch bodyType {
        case .none:
            break
        case .raw:
            let interpolatedBody = try interpolator.interpolate(rawBody, environment: activeEnvironment)
            request.httpBody = interpolatedBody.data(using: .utf8)
            request.setValue(rawContentType.rawValue, forHTTPHeaderField: "Content-Type")
        case .formUrlEncoded:
            let enabledParams = formParams.filter { $0.isEnabled && !$0.key.isEmpty }
            let bodyParts = try enabledParams.map { param -> String in
                let interpolatedKey = try interpolator.interpolate(param.key, environment: activeEnvironment)
                let interpolatedValue = try interpolator.interpolate(param.value, environment: activeEnvironment)
                return "\(interpolatedKey)=\(interpolatedValue.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? interpolatedValue)"
            }
            request.httpBody = bodyParts.joined(separator: "&").data(using: .utf8)
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        case .multipart:
            break
        }
        
        return request
    }
    
    /// Returns a preview of the interpolated URL
    func getInterpolatedURLPreview() -> String {
        do {
            return try interpolator.interpolate(url, environment: activeEnvironment)
        } catch {
            return url
        }
    }
    
    /// Returns unresolved variables in the current request
    func getUnresolvedVariables() -> [String] {
        var allVariables = Set<String>()
        
        if let env = activeEnvironment {
            for variable in env.variables where variable.isEnabled {
                allVariables.insert(variable.key)
            }
        }
        
        var unresolved: [String] = []
        unresolved.append(contentsOf: interpolator.validateVariables(in: url, availableVariables: allVariables))
        
        for param in queryParams where param.isEnabled {
            unresolved.append(contentsOf: interpolator.validateVariables(in: param.key, availableVariables: allVariables))
            unresolved.append(contentsOf: interpolator.validateVariables(in: param.value, availableVariables: allVariables))
        }
        
        for header in headers where header.isEnabled {
            unresolved.append(contentsOf: interpolator.validateVariables(in: header.key, availableVariables: allVariables))
            unresolved.append(contentsOf: interpolator.validateVariables(in: header.value, availableVariables: allVariables))
        }
        
        return Array(Set(unresolved))
    }
}

// MARK: - Supporting Types

struct KeyValueItem: Identifiable {
    let id = UUID()
    var key: String
    var value: String
    var isEnabled: Bool = true
    
    init(key: String = "", value: String = "", isEnabled: Bool = true) {
        self.key = key
        self.value = value
        self.isEnabled = isEnabled
    }
}

enum AuthType: String, CaseIterable {
    case none = "No Auth"
    case bearer = "Bearer Token"
    case basic = "Basic Auth"
    case apiKey = "API Key"
}

enum BodyType: String, CaseIterable {
    case none = "None"
    case raw = "Raw"
    case formUrlEncoded = "Form URL Encoded"
    case multipart = "Multipart"
}
