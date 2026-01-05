//
//  Workspace.swift
//  RainyPost
//
//  Created by Fer on 1/4/26.
//

import Foundation

struct Workspace: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String?
    let createdAt: Date
    var updatedAt: Date
    var settings: WorkspaceSettings
    
    init(name: String, description: String? = nil) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.createdAt = Date()
        self.updatedAt = Date()
        self.settings = WorkspaceSettings()
    }
}

struct WorkspaceSettings: Codable {
    var defaultEnvironmentId: UUID?
    var timeout: Int = 30000 // ms
    var followRedirects: Bool = true
    var validateSSL: Bool = true
}