//
//  WorkspaceView.swift
//  RainyPost
//
//  Created by Fer on 1/4/26.
//

import SwiftUI

struct WorkspaceView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showingImport = false
    @State private var showingExport = false
    
    var body: some View {
        NavigationSplitView {
            WorkspaceSidebarView()
                .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 320)
        } detail: {
            if let selectedRequest = appState.selectedRequest {
                RequestDetailView(request: selectedRequest)
            } else {
                EmptyStateView()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .principal) {
                if appState.currentWorkspace != nil {
                    EnvironmentPickerView()
                }
            }
            
            ToolbarItemGroup(placement: .primaryAction) {
                Button("New Request", systemImage: "plus") {
                    Task {
                        await appState.createRequest(name: "New Request")
                    }
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Menu {
                    Button("Import...", systemImage: "square.and.arrow.down") {
                        showingImport = true
                    }
                    Button("Export...", systemImage: "square.and.arrow.up") {
                        showingExport = true
                    }
                    Divider()
                    Button("Copy as cURL", systemImage: "doc.on.doc", action: copyCurl)
                        .disabled(appState.selectedRequest == nil)
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
                }
            }
        }
        .frame(minWidth: 800, minHeight: 400)
        .sheet(isPresented: $showingImport) {
            ImportView()
        }
        .sheet(isPresented: $showingExport) {
            ExportView()
        }
    }
    
    private func copyCurl() {
        guard let request = appState.selectedRequest else { return }
        let exporter = CurlExporter()
        let curl = exporter.export(request: request, environment: appState.activeEnvironment)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(curl, forType: .string)
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.left.circle")
                .font(.system(size: 40, weight: .thin))
                .foregroundColor(.secondary.opacity(0.4))
            
            Text("Select a Request")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)
            
            Text("Choose from the sidebar or create a new one")
                .font(.system(size: 12))
                .foregroundColor(.secondary.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    WorkspaceView()
        .environmentObject(AppState())
        .frame(width: 1000, height: 600)
}
