//
//  PostmanImporter.swift
//  RainyPost
//
//  Created by Fer on 1/4/26.
//

import Foundation

/// Imports Postman Collection v2.1 format
struct PostmanImporter {
    
    struct ImportResult {
        let collections: [Collection]
        let requests: [Request]
        let environments: [APIEnvironment]
        let warnings: [String]
    }
    
    func importCollection(from url: URL) async throws -> ImportResult {
        let data = try Data(contentsOf: url)
        let postman = try JSONDecoder().decode(PostmanCollection.self, from: data)
        
        var warnings: [String] = []
        var collections: [Collection] = []
        var requests: [Request] = []
        
        // Create root collection
        let rootCollection = Collection(
            name: postman.info.name,
            description: postman.info.description
        )
        collections.append(rootCollection)
        
        // Process items recursively
        processItems(
            postman.item,
            parentCollectionId: rootCollection.id,
            collections: &collections,
            requests: &requests,
            warnings: &warnings
        )
        
        return ImportResult(
            collections: collections,
            requests: requests,
            environments: [],
            warnings: warnings
        )
    }
    
    func importEnvironment(from url: URL) async throws -> APIEnvironment {
        let data = try Data(contentsOf: url)
        let postmanEnv = try JSONDecoder().decode(PostmanEnvironment.self, from: data)
        
        let variables = postmanEnv.values.map { value in
            Variable(
                key: value.key,
                value: value.value ?? "",
                isSecret: false,
                isEnabled: value.enabled ?? true
            )
        }
        
        return APIEnvironment(
            name: postmanEnv.name,
            variables: variables
        )
    }
    
    private func processItems(
        _ items: [PostmanItem],
        parentCollectionId: UUID,
        collections: inout [Collection],
        requests: inout [Request],
        warnings: inout [String]
    ) {
        for item in items {
            if let subItems = item.item {
                // This is a folder
                let folder = Collection(
                    name: item.name,
                    parentId: parentCollectionId
                )
                collections.append(folder)
                
                processItems(
                    subItems,
                    parentCollectionId: folder.id,
                    collections: &collections,
                    requests: &requests,
                    warnings: &warnings
                )
            } else if let postmanRequest = item.request {
                // This is a request
                do {
                    let request = try convertRequest(item.name, postmanRequest, collectionId: parentCollectionId)
                    requests.append(request)
                } catch {
                    warnings.append("Failed to import request '\(item.name)': \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func convertRequest(_ name: String, _ postman: PostmanRequest, collectionId: UUID) throws -> Request {
        let method = HTTPMethod(rawValue: postman.method.uppercased()) ?? .GET
        
        let url: String
        if let urlObj = postman.url.value as? PostmanURL {
            url = urlObj.raw ?? ""
        } else if let urlString = postman.url.value as? String {
            url = urlString
        } else {
            url = ""
        }
        
        // Convert headers
        let headers: [Header] = (postman.header ?? []).map { header in
            Header(
                key: header.key,
                value: header.value,
                isEnabled: !(header.disabled ?? false)
            )
        }
        
        // Convert body
        let body: RequestBody
        if let postmanBody = postman.body {
            body = convertBody(postmanBody)
        } else {
            body = .none
        }
        
        // Convert auth
        let auth: AuthConfig
        if let postmanAuth = postman.auth {
            auth = convertAuth(postmanAuth)
        } else {
            auth = .none
        }
        
        return Request(
            name: name,
            method: method,
            url: url,
            headers: headers,
            body: body,
            auth: auth,
            collectionId: collectionId
        )
    }
    
    private func convertBody(_ postman: PostmanBody) -> RequestBody {
        switch postman.mode {
        case "raw":
            let contentType: RawContentType
            if let options = postman.options, let rawOptions = options["raw"] as? [String: Any] {
                let language = rawOptions["language"] as? String ?? "json"
                switch language {
                case "json": contentType = .json
                case "xml": contentType = .xml
                case "html": contentType = .html
                default: contentType = .text
                }
            } else {
                contentType = .json
            }
            return .raw(content: postman.raw ?? "", contentType: contentType)
            
        case "urlencoded":
            let params = (postman.urlencoded ?? []).map { param in
                FormParam(
                    key: param.key,
                    value: param.value ?? "",
                    isEnabled: !(param.disabled ?? false)
                )
            }
            return .formUrlEncoded(params: params)
            
        case "formdata":
            return .multipart(parts: [])
            
        default:
            return .none
        }
    }
    
    private func convertAuth(_ postman: PostmanAuth) -> AuthConfig {
        switch postman.type {
        case "bearer":
            let token = postman.bearer?.first { $0.key == "token" }?.value ?? ""
            return .bearer(token: SecretRef(keychainId: UUID().uuidString), tokenValue: token)
            
        case "basic":
            let username = postman.basic?.first { $0.key == "username" }?.value ?? ""
            let password = postman.basic?.first { $0.key == "password" }?.value ?? ""
            return .basic(username: username, password: SecretRef(keychainId: UUID().uuidString), passwordValue: password)
            
        case "apikey":
            let key = postman.apikey?.first { $0.key == "key" }?.value ?? "X-API-Key"
            let value = postman.apikey?.first { $0.key == "value" }?.value ?? ""
            let inHeader = postman.apikey?.first { $0.key == "in" }?.value != "query"
            return .apiKey(key: key, value: SecretRef(keychainId: UUID().uuidString), location: inHeader ? .header : .query, keyValue: value)
            
        default:
            return .none
        }
    }
}

// MARK: - Postman JSON Models

struct PostmanCollection: Codable {
    let info: PostmanInfo
    let item: [PostmanItem]
    let variable: [PostmanVariable]?
}

struct PostmanInfo: Codable {
    let name: String
    let description: String?
    let schema: String?
}

struct PostmanItem: Codable {
    let name: String
    let item: [PostmanItem]?
    let request: PostmanRequest?
}

struct PostmanRequest: Codable {
    let method: String
    let url: AnyCodable
    let header: [PostmanHeader]?
    let body: PostmanBody?
    let auth: PostmanAuth?
}

struct PostmanURL: Codable {
    let raw: String?
    let host: [String]?
    let path: [String]?
}

struct PostmanHeader: Codable {
    let key: String
    let value: String
    let disabled: Bool?
}

struct PostmanBody: Codable {
    let mode: String?
    let raw: String?
    let urlencoded: [PostmanFormParam]?
    let formdata: [PostmanFormParam]?
    let options: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
        case mode, raw, urlencoded, formdata, options
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mode = try container.decodeIfPresent(String.self, forKey: .mode)
        raw = try container.decodeIfPresent(String.self, forKey: .raw)
        urlencoded = try container.decodeIfPresent([PostmanFormParam].self, forKey: .urlencoded)
        formdata = try container.decodeIfPresent([PostmanFormParam].self, forKey: .formdata)
        options = nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(mode, forKey: .mode)
        try container.encodeIfPresent(raw, forKey: .raw)
        try container.encodeIfPresent(urlencoded, forKey: .urlencoded)
        try container.encodeIfPresent(formdata, forKey: .formdata)
    }
}

struct PostmanFormParam: Codable {
    let key: String
    let value: String?
    let disabled: Bool?
}

struct PostmanAuth: Codable {
    let type: String
    let bearer: [PostmanAuthParam]?
    let basic: [PostmanAuthParam]?
    let apikey: [PostmanAuthParam]?
}

struct PostmanAuthParam: Codable {
    let key: String
    let value: String?
}

struct PostmanVariable: Codable {
    let key: String
    let value: String?
}

struct PostmanEnvironment: Codable {
    let name: String
    let values: [PostmanEnvValue]
}

struct PostmanEnvValue: Codable {
    let key: String
    let value: String?
    let enabled: Bool?
}

// Helper for dynamic JSON
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            value = string
        } else if let urlObj = try? container.decode(PostmanURL.self) {
            value = urlObj
        } else {
            value = ""
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let string = value as? String {
            try container.encode(string)
        }
    }
}
