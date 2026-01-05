//
//  WorkspaceSidebarView.swift
//  RainyPost
//
//  Created by Fer on 1/4/26.
//

import SwiftUI
import SwiftData

struct WorkspaceSidebarView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @State private var recentHistory: [HistoryEntry] = []
    
    var body: some View {
        List(selection: Binding(
            get: { appState.selectedRequest?.id },
            set: { id in
                appState.selectedRequest = appState.requests.first { $0.id == id }
            }
        )) {
            // Workspace Header
            if let workspace = appState.currentWorkspace {
                Section {
                    HStack(spacing: 10) {
                        Image(systemName: "folder.fill")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(workspace.name)
                                .font(.system(size: 12, weight: .semibold))
                            if let desc = workspace.description {
                                Text(desc)
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // Collections
            Section("Collections") {
                ForEach(appState.collections) { collection in
                    Label(collection.name, systemImage: "folder")
                }
                
                ForEach(appState.requests.filter { $0.collectionId == nil }) { request in
                    RequestSidebarRow(request: request)
                        .tag(request.id)
                }
                
                if appState.collections.isEmpty && appState.requests.isEmpty {
                    Text("No requests yet")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            
            // Environments
            Section("Environments") {
                ForEach(appState.environments) { environment in
                    HStack {
                        Circle()
                            .fill(environment.isActive ? Color.green : Color.secondary.opacity(0.3))
                            .frame(width: 6, height: 6)
                        Text(environment.name)
                            .font(.system(size: 12))
                        Spacer()
                        if environment.isActive {
                            Text("Active")
                                .font(.system(size: 9))
                                .foregroundColor(.green)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        Task { await appState.setActiveEnvironment(environment) }
                    }
                }
                
                if appState.environments.isEmpty {
                    Text("No environments")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            
            // History
            Section("Recent") {
                ForEach(recentHistory.prefix(8)) { entry in
                    HStack(spacing: 6) {
                        Text(entry.method)
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(methodColor(entry.method))
                        Text(entry.requestName)
                            .font(.system(size: 11))
                            .lineLimit(1)
                        Spacer()
                        if let status = entry.statusCode {
                            Text("\(status)")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(statusColor(status))
                        }
                    }
                }
                
                if recentHistory.isEmpty {
                    Text("No history yet")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .onAppear { loadHistory() }
    }
    
    private func loadHistory() {
        guard let workspaceId = appState.currentWorkspace?.id else { return }
        let service = HistoryService(modelContext: modelContext)
        recentHistory = service.fetchHistory(for: workspaceId, limit: 8)
    }
    
    private func methodColor(_ method: String) -> Color {
        switch method {
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
}

struct RequestSidebarRow: View {
    let request: Request
    
    var body: some View {
        HStack(spacing: 6) {
            Text(request.method.rawValue)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(methodColor)
            Text(request.name)
                .font(.system(size: 12))
        }
    }
    
    private var methodColor: Color {
        switch request.method {
        case .GET: return .green
        case .POST: return .blue
        case .PUT: return .orange
        case .PATCH: return .purple
        case .DELETE: return .red
        case .HEAD, .OPTIONS: return .secondary
        }
    }
}

#Preview {
    WorkspaceSidebarView()
        .environmentObject(AppState())
        .frame(width: 240, height: 500)
}
