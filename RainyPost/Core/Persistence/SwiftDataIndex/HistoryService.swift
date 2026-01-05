//
//  HistoryService.swift
//  RainyPost
//
//  Created by Fer on 1/4/26.
//

import Foundation
import SwiftData

@MainActor
class HistoryService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func recordRequest(
        requestId: UUID,
        requestName: String,
        url: String,
        method: String,
        workspaceId: UUID,
        response: HTTPResponse?
    ) {
        let entry = HistoryEntry(
            requestId: requestId,
            requestName: requestName,
            url: url,
            method: method,
            workspaceId: workspaceId
        )
        
        if let response = response {
            entry.statusCode = response.statusCode
            entry.duration = Int(response.duration * 1000)
            entry.responseSize = response.size
        }
        
        modelContext.insert(entry)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save history entry: \(error)")
        }
    }
    
    func fetchHistory(for workspaceId: UUID, limit: Int = 100) -> [HistoryEntry] {
        let descriptor = FetchDescriptor<HistoryEntry>(
            predicate: #Predicate { $0.workspaceId == workspaceId },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            var results = try modelContext.fetch(descriptor)
            if results.count > limit {
                results = Array(results.prefix(limit))
            }
            return results
        } catch {
            print("Failed to fetch history: \(error)")
            return []
        }
    }
    
    func searchHistory(
        query: String,
        workspaceId: UUID,
        statusFilter: StatusFilter? = nil,
        dateRange: DateRange? = nil
    ) -> [HistoryEntry] {
        let lowercasedQuery = query.lowercased()
        
        var predicate: Predicate<HistoryEntry>
        
        if query.isEmpty {
            predicate = #Predicate<HistoryEntry> { entry in
                entry.workspaceId == workspaceId
            }
        } else {
            predicate = #Predicate<HistoryEntry> { entry in
                entry.workspaceId == workspaceId &&
                (entry.searchableUrl.localizedStandardContains(lowercasedQuery) ||
                 entry.searchableName.localizedStandardContains(lowercasedQuery))
            }
        }
        
        let descriptor = FetchDescriptor<HistoryEntry>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            var results = try modelContext.fetch(descriptor)
            
            // Apply status filter
            if let statusFilter = statusFilter {
                results = results.filter { entry in
                    guard let code = entry.statusCode else { return false }
                    switch statusFilter {
                    case .success: return (200..<300).contains(code)
                    case .redirect: return (300..<400).contains(code)
                    case .clientError: return (400..<500).contains(code)
                    case .serverError: return (500..<600).contains(code)
                    }
                }
            }
            
            // Apply date range filter
            if let dateRange = dateRange {
                results = results.filter { entry in
                    entry.timestamp >= dateRange.start && entry.timestamp <= dateRange.end
                }
            }
            
            return results
        } catch {
            print("Failed to search history: \(error)")
            return []
        }
    }
    
    func clearHistory(for workspaceId: UUID) {
        let descriptor = FetchDescriptor<HistoryEntry>(
            predicate: #Predicate { $0.workspaceId == workspaceId }
        )
        
        do {
            let entries = try modelContext.fetch(descriptor)
            for entry in entries {
                modelContext.delete(entry)
            }
            try modelContext.save()
        } catch {
            print("Failed to clear history: \(error)")
        }
    }
    
    func deleteEntry(_ entry: HistoryEntry) {
        modelContext.delete(entry)
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete history entry: \(error)")
        }
    }
    
    func pruneOldEntries(olderThan days: Int = 30, maxEntries: Int = 1000) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        // Delete entries older than cutoff
        let oldDescriptor = FetchDescriptor<HistoryEntry>(
            predicate: #Predicate { $0.timestamp < cutoffDate }
        )
        
        do {
            let oldEntries = try modelContext.fetch(oldDescriptor)
            for entry in oldEntries {
                modelContext.delete(entry)
            }
            
            // If still over max, delete oldest
            let allDescriptor = FetchDescriptor<HistoryEntry>(
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            let allEntries = try modelContext.fetch(allDescriptor)
            
            if allEntries.count > maxEntries {
                let toDelete = allEntries.suffix(from: maxEntries)
                for entry in toDelete {
                    modelContext.delete(entry)
                }
            }
            
            try modelContext.save()
        } catch {
            print("Failed to prune history: \(error)")
        }
    }
}

// MARK: - Supporting Types

enum StatusFilter: String, CaseIterable {
    case success = "2xx"
    case redirect = "3xx"
    case clientError = "4xx"
    case serverError = "5xx"
}

struct DateRange {
    let start: Date
    let end: Date
    
    static var today: DateRange {
        let start = Calendar.current.startOfDay(for: Date())
        return DateRange(start: start, end: Date())
    }
    
    static var lastWeek: DateRange {
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -7, to: end) ?? end
        return DateRange(start: start, end: end)
    }
    
    static var lastMonth: DateRange {
        let end = Date()
        let start = Calendar.current.date(byAdding: .month, value: -1, to: end) ?? end
        return DateRange(start: start, end: end)
    }
}
