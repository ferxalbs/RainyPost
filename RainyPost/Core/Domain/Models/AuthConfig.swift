//
//  AuthConfig.swift
//  RainyPost
//
//  Created by Fer on 1/4/26.
//

import Foundation

enum AuthConfig: Codable {
    case none
    case bearer(token: SecretRef)
    case basic(username: String, password: SecretRef)
    case apiKey(key: String, value: SecretRef, location: APIKeyLocation)
    case manualOAuth(token: SecretRef)
}

enum APIKeyLocation: String, Codable {
    case header, query
    
    var displayName: String {
        switch self {
        case .header: return "Header"
        case .query: return "Query Parameter"
        }
    }
}