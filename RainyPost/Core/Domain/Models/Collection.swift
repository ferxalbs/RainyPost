//
//  Collection.swift
//  RainyPost
//
//  Created by Fer on 1/4/26.
//

import Foundation

struct Collection: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String?
    var parentId: UUID? // For nested collections
    let createdAt: Date
    var updatedAt: Date
    
    init(name: String, description: String? = nil, parentId: UUID? = nil) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.parentId = parentId
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}