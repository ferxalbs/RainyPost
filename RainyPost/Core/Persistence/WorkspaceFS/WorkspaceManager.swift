//
//  WorkspaceManager.swift
//  RainyPost
//
//  Created by Fer on 1/4/26.
//

import Foundation

class WorkspaceManager {
    private let fileManager = FileManager.default
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder
    
    init() {
        jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        jsonEncoder.dateEncodingStrategy = .iso8601
        
        jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - Workspace Operations
    
    func createWorkspace(_ workspace: Workspace, at url: URL) async throws {
        // Create workspace directory structure
        let workspaceURL = url.appendingPathComponent(workspace.name)
        try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
        
        // Create subdirectories
        let collectionsURL = workspaceURL.appendingPathComponent("collections")
        let environmentsURL = workspaceURL.appendingPathComponent("environments")
        let hiddenURL = workspaceURL.appendingPathComponent(".rainypost")
        
        try fileManager.createDirectory(at: collectionsURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: environmentsURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: hiddenURL, withIntermediateDirectories: true)
        
        // Save workspace.json
        let workspaceFileURL = workspaceURL.appendingPathComponent("workspace.json")
        let data = try jsonEncoder.encode(workspace)
        try data.write(to: workspaceFileURL)
    }
    
    func loadWorkspace(from url: URL) async throws -> Workspace {
        let workspaceFileURL = url.appendingPathComponent("workspace.json")
        let data = try Data(contentsOf: workspaceFileURL)
        return try jsonDecoder.decode(Workspace.self, from: data)
    }
    
    // MARK: - Collection Operations
    
    func saveCollection(_ collection: Collection, to workspaceURL: URL) async throws {
        let collectionsURL = workspaceURL.appendingPathComponent("collections")
        let collectionURL = collectionsURL.appendingPathComponent(collection.name)
        
        try fileManager.createDirectory(at: collectionURL, withIntermediateDirectories: true)
        
        let collectionFileURL = collectionURL.appendingPathComponent("collection.json")
        let data = try jsonEncoder.encode(collection)
        try data.write(to: collectionFileURL)
    }
    
    func loadCollections(from workspaceURL: URL) async throws -> [Collection] {
        let collectionsURL = workspaceURL.appendingPathComponent("collections")
        
        guard fileManager.fileExists(atPath: collectionsURL.path) else {
            return []
        }
        
        let contents = try fileManager.contentsOfDirectory(at: collectionsURL, includingPropertiesForKeys: nil)
        var collections: [Collection] = []
        
        for collectionURL in contents {
            let collectionFileURL = collectionURL.appendingPathComponent("collection.json")
            
            if fileManager.fileExists(atPath: collectionFileURL.path) {
                let data = try Data(contentsOf: collectionFileURL)
                let collection = try jsonDecoder.decode(Collection.self, from: data)
                collections.append(collection)
            }
        }
        
        return collections
    }
    
    // MARK: - Request Operations
    
    func saveRequest(_ request: Request, to workspaceURL: URL) async throws {
        let collectionsURL = workspaceURL.appendingPathComponent("collections")
        
        // Find the collection directory
        var requestURL: URL
        if let collectionId = request.collectionId,
           let collection = try await loadCollections(from: workspaceURL).first(where: { $0.id == collectionId }) {
            requestURL = collectionsURL.appendingPathComponent(collection.name)
        } else {
            // Save to root collections directory
            requestURL = collectionsURL
        }
        
        let requestFileURL = requestURL.appendingPathComponent("\(request.name).request.json")
        let data = try jsonEncoder.encode(request)
        try data.write(to: requestFileURL)
    }
    
    func loadRequests(from workspaceURL: URL) async throws -> [Request] {
        let collectionsURL = workspaceURL.appendingPathComponent("collections")
        
        guard fileManager.fileExists(atPath: collectionsURL.path) else {
            return []
        }
        
        var requests: [Request] = []
        
        // Recursively search for .request.json files
        let enumerator = fileManager.enumerator(at: collectionsURL, includingPropertiesForKeys: nil)
        
        while let fileURL = enumerator?.nextObject() as? URL {
            if fileURL.pathExtension == "json" && fileURL.lastPathComponent.contains(".request.") {
                let data = try Data(contentsOf: fileURL)
                let request = try jsonDecoder.decode(Request.self, from: data)
                requests.append(request)
            }
        }
        
        return requests
    }
    
    // MARK: - Environment Operations
    
    func saveEnvironment(_ environment: APIEnvironment, to workspaceURL: URL) async throws {
        let environmentsURL = workspaceURL.appendingPathComponent("environments")
        let environmentFileURL = environmentsURL.appendingPathComponent("\(environment.name).env.json")
        
        let data = try jsonEncoder.encode(environment)
        try data.write(to: environmentFileURL)
    }
    
    func loadEnvironments(from workspaceURL: URL) async throws -> [APIEnvironment] {
        let environmentsURL = workspaceURL.appendingPathComponent("environments")
        
        guard fileManager.fileExists(atPath: environmentsURL.path) else {
            return []
        }
        
        let contents = try fileManager.contentsOfDirectory(at: environmentsURL, includingPropertiesForKeys: nil)
        var environments: [APIEnvironment] = []
        
        for fileURL in contents {
            if fileURL.pathExtension == "json" && fileURL.lastPathComponent.contains(".env.") {
                let data = try Data(contentsOf: fileURL)
                let environment = try jsonDecoder.decode(APIEnvironment.self, from: data)
                environments.append(environment)
            }
        }
        
        return environments
    }
}