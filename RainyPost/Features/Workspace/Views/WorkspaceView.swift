//
//  WorkspaceView.swift
//  RainyPost
//
//  Created by Fer on 1/4/26.
//

import SwiftUI

struct WorkspaceView: View {
    @EnvironmentObject private var appState: AppState
    @State private var sidebarWidth: CGFloat = 280
    
    var body: some View {
        NavigationSplitView {
            WorkspaceSidebarView()
                .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 400)
        } detail: {
            if let selectedRequest = appState.selectedRequest {
                RequestDetailView(request: selectedRequest)
            } else {
                EmptyStateView()
            }
        }
        .navigationSplitViewStyle(.balanced)
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button(action: {
                    // Toggle sidebar
                }) {
                    Image(systemName: "sidebar.left")
                }
                .help("Toggle Sidebar")
            }
            
            ToolbarItemGroup(placement: .principal) {
                if let environment = appState.activeEnvironment {
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
                }
                .help("New Request")
                
                Button(action: {
                    // Command palette
                }) {
                    Image(systemName: "magnifyingglass")
                }
                .help("Search")
                .keyboardShortcut("k", modifiers: .command)
            }
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Request Selected")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Select a request from the sidebar or create a new one")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(VisualEffectView(material: .windowBackground, blendingMode: .behindWindow))
    }
}

#Preview {
    WorkspaceView()
        .environmentObject(AppState())
}