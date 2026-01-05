//
//  HistoryEntry.swift
//  RainyPost
//
//  Created by Fer on 1/4/26.
//

import Foundation
import SwiftData

@Model
final class HistoryEntry {
    @Attribute(.unique) var id: UUID
    var requestId: UUID
    var requestName: String
    var url: String
    var method: String
    var statusCode: Int?
    var duration: Int // milliseconds
    var responseSize: Int // bytes
    var timestamp: Date
    var workspaceId: UUID
    
    // Searchable fields
    @Attribute(.spotlight) var searchableUrl: String
    @Attribute(.spotlight) var searchableName: String
    
    init(requestId: UUID, requestName: String, url: String, method: String, workspaceId: UUID) {
        self.id = UUID()
        self.requestId = requestId
        self.requestName = requestName
        self.url = url
        self.method = method
        self.statusCode = nil
        self.duration = 0
        self.responseSize = 0
        self.timestamp = Date()
        self.workspaceId = workspaceId
        self.searchableUrl = url
        self.searchableName = requestName
    }
}