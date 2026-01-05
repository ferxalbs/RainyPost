//
//  Request.swift
//  RainyPost
//
//  Created by Fer on 1/4/26.
//

import Foundation

struct Request: Identifiable, Codable {
    let id: UUID
    var name: String
    var method: HTTPMethod
    var url: String
    var headers: [Header]
    var queryParams: [QueryParam]
    var body: RequestBody?
    var auth: AuthConfig?
    var variables: [Variable] // Request-level overrides
    var collectionId: UUID?
    var folderId: UUID?
    let createdAt: Date
    var updatedAt: Date
    
    init(name: String, method: HTTPMethod = .GET, url: String = "", collectionId: UUID? = nil) {
        self.id = UUID()
        self.name = name
        self.method = method
        self.url = url
        self.headers = []
        self.queryParams = []
        self.body = nil
        self.auth = nil
        self.variables = []
        self.collectionId = collectionId
        self.folderId = nil
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

enum HTTPMethod: String, Codable, CaseIterable {
    case GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS
    
    var displayName: String { rawValue }
}

struct Header: Identifiable, Codable {
    let id: UUID
    var key: String
    var value: String
    var isEnabled: Bool = true
    
    init(key: String, value: String, isEnabled: Bool = true) {
        self.id = UUID()
        self.key = key
        self.value = value
        self.isEnabled = isEnabled
    }
}

struct QueryParam: Identifiable, Codable {
    let id: UUID
    var key: String
    var value: String
    var isEnabled: Bool = true
    
    init(key: String, value: String, isEnabled: Bool = true) {
        self.id = UUID()
        self.key = key
        self.value = value
        self.isEnabled = isEnabled
    }
}

// MARK: - Request Body
enum RequestBody: Codable {
    case none
    case raw(content: String, contentType: RawContentType)
    case formUrlEncoded(params: [FormParam])
    case multipart(parts: [MultipartPart])
}

enum RawContentType: String, Codable, CaseIterable {
    case json = "application/json"
    case text = "text/plain"
    case xml = "application/xml"
    case html = "text/html"
    
    var displayName: String {
        switch self {
        case .json: return "JSON"
        case .text: return "Text"
        case .xml: return "XML"
        case .html: return "HTML"
        }
    }
}

struct FormParam: Identifiable, Codable {
    let id: UUID
    var key: String
    var value: String
    var isEnabled: Bool = true
    
    init(key: String, value: String, isEnabled: Bool = true) {
        self.id = UUID()
        self.key = key
        self.value = value
        self.isEnabled = isEnabled
    }
}

struct MultipartPart: Identifiable, Codable {
    let id: UUID
    var key: String
    var type: MultipartType
    var isEnabled: Bool = true
    
    init(key: String, type: MultipartType, isEnabled: Bool = true) {
        self.id = UUID()
        self.key = key
        self.type = type
        self.isEnabled = isEnabled
    }
}

enum MultipartType: Codable {
    case text(value: String)
    case file(path: String, mimeType: String?)
}