//
//  HistoryListView.swift
//  RainyPost
//
//  Created by Fer on 1/4/26.
//

import SwiftUI
import SwiftData

struct HistoryListView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    
    @State private var searchText = ""
    @State private var statusFilter: StatusFilter?
    @State private var selectedEntry: HistoryEntry?
    @State private var historyEntries: [HistoryEntry] = []
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            searchBar
            
            Divider().opacity(0.3)
            
            // History List
            if historyEntries.isEmpty {
                emptyState
            } else {
                historyList
            }
        }
        .onAppear {
            loadHistory()
        }
    }
    
    private var searchBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                TextField("Search history...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 6))
            
            // Status Filter
            Menu {
                Button("All") { statusFilter = nil }
                Divider()
                ForEach(StatusFilter.allCases, id: \.self) { filter in
                    Button(filter.rawValue) { statusFilter = filter }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(statusFilter?.rawValue ?? "All")
                        .font(.system(size: 11))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8))
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 5))
            }
            .menuStyle(.borderlessButton)
        }
        .padding(12)
        .onChange(of: searchText) { _, _ in loadHistory() }
        .onChange(of: statusFilter) { _, _ in loadHistory() }
    }
    
    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 28))
                .foregroundColor(.secondary.opacity(0.3))
            
            Text("No history yet")
                .font(.system(size: 13))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("Requests you send will appear here")
                .font(.system(size: 11))
                .foregroundColor(.secondary.opacity(0.4))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var historyList: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(historyEntries) { entry in
                    HistoryRowView(entry: entry, isSelected: selectedEntry?.id == entry.id)
                        .onTapGesture {
                            selectedEntry = entry
                        }
                        .contextMenu {
                            Button("Copy URL") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(entry.url, forType: .string)
                            }
                            Divider()
                            Button("Delete", role: .destructive) {
                                deleteEntry(entry)
                            }
                        }
                }
            }
            .padding(8)
        }
    }
    
    private func loadHistory() {
        guard let workspaceId = appState.currentWorkspace?.id else {
            historyEntries = []
            return
        }
        
        let service = HistoryService(modelContext: modelContext)
        
        if searchText.isEmpty && statusFilter == nil {
            historyEntries = service.fetchHistory(for: workspaceId)
        } else {
            historyEntries = service.searchHistory(
                query: searchText,
                workspaceId: workspaceId,
                statusFilter: statusFilter
            )
        }
    }
    
    private func deleteEntry(_ entry: HistoryEntry) {
        let service = HistoryService(modelContext: modelContext)
        service.deleteEntry(entry)
        loadHistory()
    }
}

struct HistoryRowView: View {
    let entry: HistoryEntry
    let isSelected: Bool
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 10) {
            // Method
            Text(entry.method)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(methodColor)
                .frame(width: 40, alignment: .leading)
            
            // Status
            if let status = entry.statusCode {
                Text("\(status)")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(statusColor(status))
                    .frame(width: 30)
            } else {
                Text("---")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary.opacity(0.4))
                    .frame(width: 30)
            }
            
            // Name & URL
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.requestName)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                
                Text(entry.url)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Duration & Time
            VStack(alignment: .trailing, spacing: 2) {
                if entry.duration > 0 {
                    Text(formatDuration(entry.duration))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
                Text(formatTime(entry.timestamp))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.6))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.blue.opacity(0.2) : (isHovered ? Color.white.opacity(0.04) : Color.clear))
        )
        .contentShape(Rectangle())
        .onHover { hovering in isHovered = hovering }
    }
    
    private var methodColor: Color {
        switch entry.method {
        case "GET": return .green
        case "POST": return .blue
        case "PUT": return .orange
        case "PATCH": return .purple
        case "DELETE": return .red
        default: return .secondary
        }
    }
    
    private func statusColor(_ code: Int) -> Color {
        switch code {
        case 200..<300: return .green
        case 300..<400: return .blue
        case 400..<500: return .orange
        case 500..<600: return .red
        default: return .secondary
        }
    }
    
    private func formatDuration(_ ms: Int) -> String {
        if ms < 1000 {
            return "\(ms)ms"
        } else {
            return String(format: "%.1fs", Double(ms) / 1000)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    HistoryListView()
        .environmentObject(AppState())
        .frame(width: 400, height: 500)
}
