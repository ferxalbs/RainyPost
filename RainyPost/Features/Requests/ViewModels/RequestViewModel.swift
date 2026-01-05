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
    
    private let httpEngine = HTTPEngine()
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
            case .bearer(let tokenRef):
                self.authType = .bearer
                // Load from keychain if needed
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
            let request = buildURLRequest()
            response = try await httpEngine.execute(request)
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    private func buildURLRequest() -> URLRequest {
        var urlString = url
        
        // Add query parameters
        let enabledParams = queryParams.filter { $0.isEnabled && !$0.key.isEmpty }
        if !enabledParams.isEmpty {
            var components = URLComponents(string: url) ?? URLComponents()
            components.queryItems = enabledParams.map { URLQueryItem(name: $0.key, value: $0.value) }
            urlString = components.url?.absoluteString ?? url
        }
        
        var request = URLRequest(url: URL(string: urlString) ?? URL(string: "https://invalid")!)
        request.httpMethod = method.rawValue
        
        // Add headers
        for header in headers where header.isEnabled && !header.key.isEmpty {
            request.setValue(header.value, forHTTPHeaderField: header.key)
        }
        
        // Add auth
        switch authType {
        case .none:
            break
        case .bearer:
            if !authToken.isEmpty {
                request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
            }
        case .basic:
            let credentials = "\(authUsername):\(authPassword)"
            if let data = credentials.data(using: .utf8) {
                let base64 = data.base64EncodedString()
                request.setValue("Basic \(base64)", forHTTPHeaderField: "Authorization")
            }
        case .apiKey:
            if apiKeyLocation == .header {
                request.setValue(apiKeyValue, forHTTPHeaderField: apiKeyName)
            }
        }
        
        // Add body
        switch bodyType {
        case .none:
            break
        case .raw:
            request.httpBody = rawBody.data(using: .utf8)
            request.setValue(rawContentType.rawValue, forHTTPHeaderField: "Content-Type")
        case .formUrlEncoded:
            let enabledParams = formParams.filter { $0.isEnabled && !$0.key.isEmpty }
            let bodyString = enabledParams.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }.joined(separator: "&")
            request.httpBody = bodyString.data(using: .utf8)
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        case .multipart:
            // TODO: Implement multipart
            break
        }
        
        return request
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
