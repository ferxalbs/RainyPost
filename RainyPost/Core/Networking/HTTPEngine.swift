//
//  HTTPEngine.swift
//  RainyPost
//
//  Created by Fer on 1/4/26.
//

import Foundation

class HTTPEngine {
    private let session: URLSession
    private let configuration: URLSessionConfiguration
    
    init() {
        configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        configuration.httpCookieAcceptPolicy = .always
        configuration.httpShouldSetCookies = true
        
        session = URLSession(configuration: configuration)
    }
    
    func execute(_ request: URLRequest) async throws -> HTTPResponse {
        let startTime = Date()
        
        let (data, urlResponse) = try await session.data(for: request)
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw HTTPEngineError.invalidResponse
        }
        
        let headers = httpResponse.allHeaderFields.compactMap { key, value -> ResponseHeader? in
            guard let keyString = key as? String, let valueString = value as? String else { return nil }
            return ResponseHeader(key: keyString, value: valueString)
        }
        
        return HTTPResponse(
            statusCode: httpResponse.statusCode,
            statusText: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode),
            headers: headers,
            body: data,
            duration: duration,
            size: data.count,
            url: request.url?.absoluteString ?? ""
        )
    }
}

// MARK: - Response Model

struct HTTPResponse {
    let statusCode: Int
    let statusText: String
    let headers: [ResponseHeader]
    let body: Data
    let duration: TimeInterval
    let size: Int
    let url: String
    
    var isSuccess: Bool {
        (200...299).contains(statusCode)
    }
    
    var bodyString: String? {
        String(data: body, encoding: .utf8)
    }
    
    var prettyJSON: String? {
        guard let json = try? JSONSerialization.jsonObject(with: body),
              let prettyData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
              let prettyString = String(data: prettyData, encoding: .utf8) else {
            return nil
        }
        return prettyString
    }
    
    var formattedDuration: String {
        if duration < 1 {
            return String(format: "%.0f ms", duration * 1000)
        } else {
            return String(format: "%.2f s", duration)
        }
    }
    
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }
}

struct ResponseHeader: Identifiable {
    let id = UUID()
    let key: String
    let value: String
}

// MARK: - Errors

enum HTTPEngineError: LocalizedError {
    case invalidResponse
    case invalidURL
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return error.localizedDescription
        }
    }
}
