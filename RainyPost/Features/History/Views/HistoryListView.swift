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
            searchBar
            Divider()
            
            if historyEntries.isEmpty {
                emptyState
            } else {
                historyList
            }
        }
        .onAppear { loadHistory() }
    }
    
    private var searchBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                
                TextField("Search history...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(Color(nsColor: .textBackgroundColor))
            .cornerRadius(4)
            
            Menu {
                Button("All") { statusFilter = nil }
                Divider()
                ForEach(StatusFilter.allCases, id: \.self) { filter in
                    Button(filter.rawValue) { statusFilter = filter }
                }
            } label: {
                HStack(spacing: 3) {
                    Text(statusFilter?.rawValue ?? "All")
                        .font(.system(size: 10))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 7))
                }
            }
            .menuStyle(.borderlessButton)
        }
        .padding(8)
        .onChange(of: searchText) { _, _ in loadHistory() }
        .onChange(of: statusFilter) { _, _ in loadHistory() }
    }
    
    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 24))
                .foregroundColor(.secondary.opacity(0.4))
            
            Text("No history yet")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            Text("Requests you send will appear here")
                .font(.system(size: 10))
                .foregroundColor(.secondary.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var historyList: some View {
        List(selection: Binding(
            get: { selectedEntry?.id },
            set: { id in
                selectedEntry = historyEntries.first { $0.id == id }
            }
        )) {
            ForEach(historyEntries) { entry in
                HistoryRowView(entry: entry)
                    .tag(entry.id)
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
        .listStyle(.plain)
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
    
    var body: some View {
        HStack(spacing: 8) {
            Text(entry.method)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(methodColor)
                .frame(width: 36, alignment: .leading)
            
            if let status = entry.statusCode {
                Text("\(status)")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundColor(statusColor(status))
                    .frame(width: 28)
            } else {
                Text("---")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.secondary.opacity(0.5))
                    .frame(width: 28)
            }
            
            VStack(alignment: .leading, spacing: 1) {
                Text(entry.requestName)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                
                Text(entry.url)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 1) {
                if entry.duration > 0 {
                    Text(formatDuration(entry.duration))
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
                Text(formatTime(entry.timestamp))
                    .font(.system(size: 9))
                    .foregroundColor(.secondary.opacity(0.7))
            }
        }
        .padding(.vertical, 2)
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
