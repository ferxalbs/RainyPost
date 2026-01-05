//
//  WorkspaceExporter.swift
//  RainyPost
//
//  Created by Fer on 1/4/26.
//

import Foundation
import Compression

/// Exports workspace as ZIP archive (excluding secrets)
@MainActor
struct WorkspaceExporter {
    
    struct ExportOptions {
        var includeHistory: Bool = false
        var includeEnvironments: Bool = true
        var stripSecrets: Bool = true
    }
    
    func export(
        workspace: Workspace,
        workspaceURL: URL,
        to destinationURL: URL,
        options: ExportOptions = ExportOptions()
    ) async throws {
        let fileManager = FileManager.default
        
        // Create temp directory for export
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? fileManager.removeItem(at: tempDir)
        }
        
        // Copy workspace.json
        let workspaceFile = workspaceURL.appendingPathComponent("workspace.json")
        if fileManager.fileExists(atPath: workspaceFile.path) {
            try fileManager.copyItem(
                at: workspaceFile,
                to: tempDir.appendingPathComponent("workspace.json")
            )
        }
        
        // Copy collections
        let collectionsDir = workspaceURL.appendingPathComponent("collections")
        if fileManager.fileExists(atPath: collectionsDir.path) {
            try copyDirectory(
                from: collectionsDir,
                to: tempDir.appendingPathComponent("collections"),
                stripSecrets: options.stripSecrets
            )
        }
        
        // Copy environments (with secrets stripped)
        if options.includeEnvironments {
            let environmentsDir = workspaceURL.appendingPathComponent("environments")
            if fileManager.fileExists(atPath: environmentsDir.path) {
                try copyEnvironments(
                    from: environmentsDir,
                    to: tempDir.appendingPathComponent("environments"),
                    stripSecrets: options.stripSecrets
                )
            }
        }
        
        // Create ZIP
        try createZip(from: tempDir, to: destinationURL)
    }
    
    private func copyDirectory(from source: URL, to destination: URL, stripSecrets: Bool) throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)
        
        let contents = try fileManager.contentsOfDirectory(at: source, includingPropertiesForKeys: nil)
        
        for item in contents {
            let destItem = destination.appendingPathComponent(item.lastPathComponent)
            
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: item.path, isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                    try copyDirectory(from: item, to: destItem, stripSecrets: stripSecrets)
                } else if item.pathExtension == "json" && stripSecrets {
                    try copyJSONStrippingSecrets(from: item, to: destItem)
                } else {
                    try fileManager.copyItem(at: item, to: destItem)
                }
            }
        }
    }
    
    private func copyEnvironments(from source: URL, to destination: URL, stripSecrets: Bool) throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)
        
        let contents = try fileManager.contentsOfDirectory(at: source, includingPropertiesForKeys: nil)
        
        for item in contents where item.pathExtension == "json" {
            let destItem = destination.appendingPathComponent(item.lastPathComponent)
            
            if stripSecrets {
                try copyEnvironmentStrippingSecrets(from: item, to: destItem)
            } else {
                try fileManager.copyItem(at: item, to: destItem)
            }
        }
    }
    
    private func copyJSONStrippingSecrets(from source: URL, to destination: URL) throws {
        let data = try Data(contentsOf: source)
        
        guard var json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            try data.write(to: destination)
            return
        }
        
        // Strip auth secrets
        if var auth = json["auth"] as? [String: Any] {
            auth["tokenRef"] = nil
            auth["passwordRef"] = nil
            auth["valueRef"] = nil
            json["auth"] = auth
        }
        
        let strippedData = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
        try strippedData.write(to: destination)
    }
    
    private func copyEnvironmentStrippingSecrets(from source: URL, to destination: URL) throws {
        let data = try Data(contentsOf: source)
        
        guard var json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            try data.write(to: destination)
            return
        }
        
        // Strip secret variable values
        if var variables = json["variables"] as? [[String: Any]] {
            for i in 0..<variables.count {
                if variables[i]["isSecret"] as? Bool == true {
                    variables[i]["value"] = ""
                    variables[i]["secretRef"] = nil
                }
            }
            json["variables"] = variables
        }
        
        let strippedData = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
        try strippedData.write(to: destination)
    }
    
    private func createZip(from sourceDir: URL, to destinationURL: URL) throws {
        let fileManager = FileManager.default
        
        // Remove existing file if present
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        
        // Use ditto command for ZIP creation (macOS native)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = ["-c", "-k", "--sequesterRsrc", sourceDir.path, destinationURL.path]
        
        try process.run()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else {
            throw ExportError.zipCreationFailed
        }
    }
    
    enum ExportError: LocalizedError {
        case zipCreationFailed
        
        var errorDescription: String? {
            switch self {
            case .zipCreationFailed:
                return "Failed to create ZIP archive"
            }
        }
    }
}
