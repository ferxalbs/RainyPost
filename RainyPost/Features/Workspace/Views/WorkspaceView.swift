//
//  WorkspaceView.swift
//  RainyPost
//
//  Created by Fer on 1/4/26.
//

import SwiftUI

struct WorkspaceView: View {
    @EnvironmentObject private var appState: AppState
    @State private var sidebarWidth: CGFloat = 260
    
    var body: some View {
        HSplitView {
            // Sidebar
            WorkspaceSidebarView()
                .frame(minWidth: 220, idealWidth: 260, maxWidth: 320)
            
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
                        .font(.system(size: 13))
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
                        .font(.system(size: 13))
                }
                .help("New Request (⌘N)")
                .keyboardShortcut("n", modifiers: .command)
                
                Button(action: {}) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 13))
                }
                .help("Search (⌘K)")
                .keyboardShortcut("k", modifiers: .command)
            }
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.left.circle")
                .font(.system(size: 36, weight: .thin))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("Select a Request")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            Text("Choose from the sidebar or create a new one")
                .font(.system(size: 12))
                .foregroundColor(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    WorkspaceView()
        .environmentObject(AppState())
}