//
//  RequestIndex.swift
//  RainyPost
//
//  Created by Fer on 1/4/26.
//

import Foundation
import SwiftData

@Model
final class RequestIndex {
    @Attribute(.unique) var id: UUID
    var name: String
    var url: String
    var method: String
    var collectionId: UUID?
    var workspaceId: UUID
    var lastModified: Date
    var fileHash: String // For sync detection
    
    @Attribute(.spotlight) var searchableContent: String
    
    init(id: UUID, name: String, url: String, method: String, workspaceId: UUID, fileHash: String, collectionId: UUID? = nil) {
        self.id = id
        self.name = name
        self.url = url
        self.method = method
        self.collectionId = collectionId
        self.workspaceId = workspaceId
        self.lastModified = Date()
        self.fileHash = fileHash
        self.searchableContent = "\(name) \(url) \(method)"
    }
}