//
//  Environment.swift
//  RainyPost
//
//  Created by Fer on 1/4/26.
//

import Foundation

struct APIEnvironment: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var variables: [Variable]
    var isActive: Bool = false
    let createdAt: Date
    var updatedAt: Date
    
    init(name: String, variables: [Variable] = []) {
        self.id = UUID()
        self.name = name
        self.variables = variables
        self.isActive = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    static func == (lhs: APIEnvironment, rhs: APIEnvironment) -> Bool {
        lhs.id == rhs.id
    }
}