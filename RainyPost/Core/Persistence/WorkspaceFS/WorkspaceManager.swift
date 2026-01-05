//
//  WorkspaceManager.swift
//  RainyPost
//
//  Created by Fer on 1/4/26.
//

import Foundation

class WorkspaceManager {
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
        let fm = FileManager.default
        
        // Sanitize workspace name for filesystem
        let safeName = workspace.name
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .trimmingCharacters(in: .whitespaces)
        
        guard !safeName.isEmpty else {
            throw WorkspaceError.invalidName
        }
        
        // Create workspace directory with the workspace name
        let workspaceURL = parentURL.appendingPathComponent(safeName)
        
        // Check if directory already exists
        if fm.fileExists(atPath: workspaceURL.path) {
            throw WorkspaceError.alreadyExists(safeName)
        }
        
        // Create main workspace directory
        try fm.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
        
        // Create subdirectories
        try fm.createDirectory(at: workspaceURL.appendingPathComponent("collections"), withIntermediateDirectories: true)
        try fm.createDirectory(at: workspaceURL.appendingPathComponent("environments"), withIntermediateDirectories: true)
        try fm.createDirectory(at: workspaceURL.appendingPathComponent(".rainypost"), withIntermediateDirectories: true)
        
        // Save workspace.json
        let workspaceFileURL = workspaceURL.appendingPathComponent("workspace.json")
        let data = try jsonEncoder.encode(workspace)
        try data.write(to: workspaceFileURL)
        
        // Create a default environment
        var defaultEnv = APIEnvironment(name: "Default")
        defaultEnv.isActive = true
        let envFileURL = workspaceURL.appendingPathComponent("environments").appendingPathComponent("Default.env.json")
        let envData = try jsonEncoder.encode(defaultEnv)
        try envData.write(to: envFileURL)
    }
    
    func loadWorkspace(from url: URL) async throws -> Workspace {
        let workspaceFileURL = url.appendingPathComponent("workspace.json")
        
        guard FileManager.default.fileExists(atPath: workspaceFileURL.path) else {
            throw WorkspaceError.notFound
        }
        
        let data = try Data(contentsOf: workspaceFileURL)
        return try jsonDecoder.decode(Workspace.self, from: data)
    }
    
    // MARK: - Collection Operations
    
    func saveCollection(_ collection: Collection, to workspaceURL: URL) async throws {
        let fm = FileManager.default
        let collectionsURL = workspaceURL.appendingPathComponent("collections")
        let collectionURL = collectionsURL.appendingPathComponent(collection.name)
        
        try fm.createDirectory(at: collectionURL, withIntermediateDirectories: true)
        
        let collectionFileURL = collectionURL.appendingPathComponent("collection.json")
        let data = try jsonEncoder.encode(collection)
        try data.write(to: collectionFileURL)
    }
    
    func loadCollections(from workspaceURL: URL) async throws -> [Collection] {
        let fm = FileManager.default
        let collectionsURL = workspaceURL.appendingPathComponent("collections")
        
        guard fm.fileExists(atPath: collectionsURL.path) else {
            return []
        }
        
        let contents = try fm.contentsOfDirectory(at: collectionsURL, includingPropertiesForKeys: [.isDirectoryKey])
        var collections: [Collection] = []
        
        for collectionURL in contents {
            var isDirectory: ObjCBool = false
            guard fm.fileExists(atPath: collectionURL.path, isDirectory: &isDirectory),
                  isDirectory.boolValue else { continue }
            
            let collectionFileURL = collectionURL.appendingPathComponent("collection.json")
            
            if fm.fileExists(atPath: collectionFileURL.path) {
                let data = try Data(contentsOf: collectionFileURL)
                let collection = try jsonDecoder.decode(Collection.self, from: data)
                collections.append(collection)
            }
        }
        
        return collections
    }
    
    // MARK: - Request Operations
    
    func saveRequest(_ request: Request, to workspaceURL: URL) async throws {
        let fm = FileManager.default
        let collectionsURL = workspaceURL.appendingPathComponent("collections")
        
        var requestURL: URL
        if let collectionId = request.collectionId,
           let collection = try await loadCollections(from: workspaceURL).first(where: { $0.id == collectionId }) {
            requestURL = collectionsURL.appendingPathComponent(collection.name)
        } else {
            requestURL = collectionsURL
        }
        
        try fm.createDirectory(at: requestURL, withIntermediateDirectories: true)
        
        let safeFileName = request.name.replacingOccurrences(of: "/", with: "-")
        let requestFileURL = requestURL.appendingPathComponent("\(safeFileName).request.json")
        let data = try jsonEncoder.encode(request)
        try data.write(to: requestFileURL)
    }
    
    func loadRequests(from workspaceURL: URL) async throws -> [Request] {
        let fm = FileManager.default
        let collectionsURL = workspaceURL.appendingPathComponent("collections")
        
        guard fm.fileExists(atPath: collectionsURL.path) else {
            return []
        }
        
        var requests: [Request] = []
        
        guard let enumerator = fm.enumerator(at: collectionsURL, includingPropertiesForKeys: [.isRegularFileKey]) else {
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
        let fm = FileManager.default
        let environmentsURL = workspaceURL.appendingPathComponent("environments")
        
        try fm.createDirectory(at: environmentsURL, withIntermediateDirectories: true)
        
        let safeFileName = environment.name.replacingOccurrences(of: "/", with: "-")
        let environmentFileURL = environmentsURL.appendingPathComponent("\(safeFileName).env.json")
        
        let data = try jsonEncoder.encode(environment)
        try data.write(to: environmentFileURL)
    }
    
    func loadEnvironments(from workspaceURL: URL) async throws -> [APIEnvironment] {
        let fm = FileManager.default
        let environmentsURL = workspaceURL.appendingPathComponent("environments")
        
        guard fm.fileExists(atPath: environmentsURL.path) else {
            return []
        }
        
        let contents = try fm.contentsOfDirectory(at: environmentsURL, includingPropertiesForKeys: nil)
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
    case invalidName
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Workspace not found"
        case .alreadyExists(let name):
            return "A folder named '\(name)' already exists"
        case .invalidFormat:
            return "Invalid workspace format"
        case .invalidName:
            return "Invalid workspace name"
        }
    }
}
