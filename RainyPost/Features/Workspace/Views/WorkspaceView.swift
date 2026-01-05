//
//  WorkspaceView.swift
//  RainyPost
//
//  Created by Fer on 1/4/26.
//

import SwiftUI

struct WorkspaceView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        HSplitView {
            // Sidebar
            WorkspaceSidebarView()
                .frame(minWidth: 260, idealWidth: 300, maxWidth: 380)
            
            // Main Content
            ZStack {
                VisualEffectView(material: .contentBackground, blendingMode: .behindWindow)
                
                if let selectedRequest = appState.selectedRequest {
                    RequestDetailView(request: selectedRequest)
                } else {
                    EmptyStateView()
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button(action: {}) {
                    Image(systemName: "sidebar.left")
                        .font(.system(size: 14))
                }
                .help("Toggle Sidebar")
            }
            
            ToolbarItemGroup(placement: .principal) {
                if appState.currentWorkspace != nil {
                    EnvironmentPickerView()
                }
            }
            
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: {
                    Task {
                        await appState.createRequest(name: "New Request")
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 14))
                }
                .help("New Request (⌘N)")
                .keyboardShortcut("n", modifiers: .command)
                
                Button(action: {}) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                }
                .help("Search (⌘K)")
                .keyboardShortcut("k", modifiers: .command)
            }
        }
        .frame(minWidth: 800, minHeight: 400)
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.left.circle")
                .font(.system(size: 48, weight: .thin))
                .foregroundColor(.secondary.opacity(0.4))
            
            Text("Select a Request")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.secondary)
            
            Text("Choose from the sidebar or create a new one")
                .font(.system(size: 14))
                .foregroundColor(.secondary.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    WorkspaceView()
        .environmentObject(AppState())
        .frame(width: 1200, height: 800)
}
