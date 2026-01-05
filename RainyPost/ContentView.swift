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
