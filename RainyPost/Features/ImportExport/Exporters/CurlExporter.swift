//
//  CurlExporter.swift
//  RainyPost
//
//  Created by Fer on 1/4/26.
//

import Foundation

/// Exports requests to cURL commands
struct CurlExporter {
    
    func export(request: Request, environment: APIEnvironment? = nil) -> String {
        let interpolator = VariableInterpolator.shared
        
        // Interpolate URL
        var url = request.url
        if let env = environment {
            url = (try? interpolator.interpolate(url, environment: env)) ?? url
        }
        
        var parts: [String] = ["curl"]
        
        // Method
        if request.method != .GET {
            parts.append("-X \(request.method.rawValue)")
        }
        
        // URL
        parts.append("'\(escapeForShell(url))'")
        
        // Headers
        for header in request.headers where header.isEnabled {
            var value = header.value
            if let env = environment {
                value = (try? interpolator.interpolate(value, environment: env)) ?? value
            }
            parts.append("-H '\(escapeForShell(header.key)): \(escapeForShell(value))'")
        }
        
        // Auth
        switch request.auth {
        case .bearer:
            parts.append("-H 'Authorization: Bearer <token>'")
        case .basic(let username, _, _):
            parts.append("-u '\(escapeForShell(username)):<password>'")
        case .apiKey(let key, _, let location, _):
            if location == .header {
                parts.append("-H '\(escapeForShell(key)): <api-key>'")
            }
        default:
            break
        }
        
        // Body
        switch request.body {
        case .raw(let content, let contentType):
            var body = content
            if let env = environment {
                body = (try? interpolator.interpolate(body, environment: env)) ?? body
            }
            parts.append("-H 'Content-Type: \(contentType.rawValue)'")
            parts.append("-d '\(escapeForShell(body))'")
            
        case .formUrlEncoded(let params):
            let enabledParams = params.filter { $0.isEnabled }
            for param in enabledParams {
                var value = param.value
                if let env = environment {
                    value = (try? interpolator.interpolate(value, environment: env)) ?? value
                }
                parts.append("--data-urlencode '\(escapeForShell(param.key))=\(escapeForShell(value))'")
            }
            
        case .multipart(let multiparts):
            for part in multiparts where part.isEnabled {
                switch part.type {
                case .text(let value):
                    parts.append("-F '\(escapeForShell(part.key))=\(escapeForShell(value))'")
                case .file(let path, _):
                    parts.append("-F '\(escapeForShell(part.key))=@\(escapeForShell(path))'")
                }
            }
            
        default:
            break
        }
        
        // Query params (if not already in URL)
        let enabledParams = request.queryParams.filter { $0.isEnabled && !$0.key.isEmpty }
        if !enabledParams.isEmpty && !url.contains("?") {
            var queryParts: [String] = []
            for param in enabledParams {
                var value = param.value
                if let env = environment {
                    value = (try? interpolator.interpolate(value, environment: env)) ?? value
                }
                let encodedKey = param.key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? param.key
                let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
                queryParts.append("\(encodedKey)=\(encodedValue)")
            }
            // Modify URL to include query params
            let queryString = queryParts.joined(separator: "&")
            parts[2] = "'\(escapeForShell(url))?\(queryString)'"
        }
        
        return parts.joined(separator: " \\\n  ")
    }
    
    func exportMultiLine(request: Request, environment: APIEnvironment? = nil) -> String {
        export(request: request, environment: environment)
    }
    
    private func escapeForShell(_ string: String) -> String {
        string
            .replacingOccurrences(of: "'", with: "'\\''")
            .replacingOccurrences(of: "\n", with: "\\n")
    }
}
