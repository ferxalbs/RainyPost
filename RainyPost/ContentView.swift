//
//  ContentView.swift
//  RainyPost
//
//  Created by Fer on 1/4/26.
//

import SwiftUI

struct MainWindowView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showingWorkspacePicker = false
    
    var body: some View {
        Group {
            if appState.currentWorkspace != nil {
                WorkspaceView()
            } else {
                WelcomeView(showingWorkspacePicker: $showingWorkspacePicker)
            }
        }
        .sheet(isPresented: $showingWorkspacePicker) {
            WorkspacePickerView()
        }
        .alert("Error", isPresented: .constant(appState.errorMessage != nil)) {
            Button("OK") {
                appState.errorMessage = nil
            }
        } message: {
            if let errorMessage = appState.errorMessage {
                Text(errorMessage)
            }
        }
    }
}

// MARK: - App Commands

struct AppCommands: Commands {
    @ObservedObject var appState: AppState
    
    var body: some Commands {
        // File Menu
        CommandGroup(replacing: .newItem) {
            Button("New Request") {
                Task {
                    await appState.createRequest(name: "New Request")
                }
            }
            .keyboardShortcut("n", modifiers: .command)
            .disabled(appState.currentWorkspace == nil)
            
            Button("New Collection") {
                Task {
                    await appState.createCollection(name: "New Collection")
                }
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])
            .disabled(appState.currentWorkspace == nil)
            
            Divider()
            
            Button("New Environment") {
                Task {
                    await appState.createEnvironment(name: "New Environment")
                }
            }
            .disabled(appState.currentWorkspace == nil)
        }
        
        // Edit Menu additions
        CommandGroup(after: .pasteboard) {
            Divider()
            
            Button("Copy as cURL") {
                if let request = appState.selectedRequest {
                    let exporter = CurlExporter()
                    let curl = exporter.export(request: request, environment: appState.activeEnvironment)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(curl, forType: .string)
                }
            }
            .keyboardShortcut("c", modifiers: [.command, .shift])
            .disabled(appState.selectedRequest == nil)
        }
        
        // Workspace Menu
        CommandMenu("Workspace") {
            Button("Close Workspace") {
                appState.closeWorkspace()
            }
            .keyboardShortcut("w", modifiers: [.command, .shift])
            .disabled(appState.currentWorkspace == nil)
        }
    }
}
