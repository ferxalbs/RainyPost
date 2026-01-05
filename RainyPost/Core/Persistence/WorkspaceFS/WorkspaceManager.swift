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
    
    func createWorkspace(_ workspace: Workspace, at parentURL: URL) async throws {
        // Create workspace directory with the workspace name
        let workspaceURL = parentURL.appendingPathComponent(workspace.name)
        
        // Check if directory already exists
        if fileManager.fileExists(atPath: workspaceURL.path) {
            throw WorkspaceError.alreadyExists(workspace.name)
        }
        
        // Create main workspace directory
        try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true, attributes: nil)
        
        // Create subdirectories
        let collectionsURL = workspaceURL.appendingPathComponent("collections")
        let environmentsURL = workspaceURL.appendingPathComponent("environments")
        let rainypostURL = workspaceURL.appendingPathComponent(".rainypost")
        
        try fileManager.createDirectory(at: collectionsURL, withIntermediateDirectories: true, attributes: nil)
        try fileManager.createDirectory(at: environmentsURL, withIntermediateDirectories: true, attributes: nil)
        try fileManager.createDirectory(at: rainypostURL, withIntermediateDirectories: true, attributes: nil)
        
        // Save workspace.json
        let workspaceFileURL = workspaceURL.appendingPathComponent("workspace.json")
        let data = try jsonEncoder.encode(workspace)
        try data.write(to: workspaceFileURL, options: .atomic)
        
        // Create a default environment
        var defaultEnv = APIEnvironment(name: "Default")
        defaultEnv.isActive = true
        let envFileURL = environmentsURL.appendingPathComponent("Default.env.json")
        let envData = try jsonEncoder.encode(defaultEnv)
        try envData.write(to: envFileURL)
    }
    
    func loadWorkspace(from url: URL) async throws -> Workspace {
        let workspaceFileURL = url.appendingPathComponent("workspace.json")
        
        guard fileManager.fileExists(atPath: workspaceFileURL.path) else {
            throw WorkspaceError.notFound
        }
        
        let data = try Data(contentsOf: workspaceFileURL)
        return try jsonDecoder.decode(Workspace.self, from: data)
    }
    
    // MARK: - Collection Operations
    
    func saveCollection(_ collection: Collection, to workspaceURL: URL) async throws {
        let collectionsURL = workspaceURL.appendingPathComponent("collections")
        let collectionURL = collectionsURL.appendingPathComponent(collection.name)
        
        try fileManager.createDirectory(at: collectionURL, withIntermediateDirectories: true, attributes: nil)
        
        let collectionFileURL = collectionURL.appendingPathComponent("collection.json")
        let data = try jsonEncoder.encode(collection)
        try data.write(to: collectionFileURL, options: .atomic)
    }
    
    func loadCollections(from workspaceURL: URL) async throws -> [Collection] {
        let collectionsURL = workspaceURL.appendingPathComponent("collections")
        
        guard fileManager.fileExists(atPath: collectionsURL.path) else {
            return []
        }
        
        let contents = try fileManager.contentsOfDirectory(at: collectionsURL, includingPropertiesForKeys: [.isDirectoryKey])
        var collections: [Collection] = []
        
        for collectionURL in contents {
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: collectionURL.path, isDirectory: &isDirectory),
                  isDirectory.boolValue else { continue }
            
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
        
        // Ensure directory exists
        try fileManager.createDirectory(at: requestURL, withIntermediateDirectories: true, attributes: nil)
        
        let safeFileName = request.name.replacingOccurrences(of: "/", with: "-")
        let requestFileURL = requestURL.appendingPathComponent("\(safeFileName).request.json")
        let data = try jsonEncoder.encode(request)
        try data.write(to: requestFileURL, options: .atomic)
    }
    
    func loadRequests(from workspaceURL: URL) async throws -> [Request] {
        let collectionsURL = workspaceURL.appendingPathComponent("collections")
        
        guard fileManager.fileExists(atPath: collectionsURL.path) else {
            return []
        }
        
        var requests: [Request] = []
        
        // Recursively search for .request.json files
        guard let enumerator = fileManager.enumerator(at: collectionsURL, includingPropertiesForKeys: [.isRegularFileKey]) else {
            return []
        }
        
        while let fileURL = enumerator.nextObject() as? URL {
            if fileURL.pathExtension == "json" && fileURL.lastPathComponent.contains(".request.") {
                do {
                    let data = try Data(contentsOf: fileURL)
                    let request = try jsonDecoder.decode(Request.self, from: data)
                    requests.append(request)
                } catch {
                    print("Failed to load request from \(fileURL): \(error)")
                }
            }
        }
        
        return requests
    }
    
    // MARK: - Environment Operations
    
    func saveEnvironment(_ environment: APIEnvironment, to workspaceURL: URL) async throws {
        let environmentsURL = workspaceURL.appendingPathComponent("environments")
        
        // Ensure directory exists
        try fileManager.createDirectory(at: environmentsURL, withIntermediateDirectories: true, attributes: nil)
        
        let safeFileName = environment.name.replacingOccurrences(of: "/", with: "-")
        let environmentFileURL = environmentsURL.appendingPathComponent("\(safeFileName).env.json")
        
        let data = try jsonEncoder.encode(environment)
        try data.write(to: environmentFileURL, options: .atomic)
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
                do {
                    let data = try Data(contentsOf: fileURL)
                    let environment = try jsonDecoder.decode(APIEnvironment.self, from: data)
                    environments.append(environment)
                } catch {
                    print("Failed to load environment from \(fileURL): \(error)")
                }
            }
        }
        
        return environments
    }
}

// MARK: - Errors

enum WorkspaceError: LocalizedError {
    case notFound
    case alreadyExists(String)
    case invalidFormat
    case accessDenied
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Workspace not found"
        case .alreadyExists(let name):
            return "A folder named '\(name)' already exists at this location"
        case .invalidFormat:
            return "Invalid workspace format"
        case .accessDenied:
            return "Access denied to the selected folder"
        }
    }
}
