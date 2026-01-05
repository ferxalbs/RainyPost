//
//  WorkspacePickerView.swift
//  RainyPost
//
//  Created by Fer on 1/4/26.
//

import SwiftUI

struct WorkspacePickerView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var workspaceName = ""
    @State private var selectedURL: URL?
    @State private var showingFolderPicker = false
    @State private var isCreatingNew = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(isCreatingNew ? "Create Workspace" : "Open Workspace")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(.regularMaterial, in: Rectangle())
            
            Divider()
            
            // Content
            VStack(spacing: 24) {
                // Mode Picker
                Picker("Mode", selection: $isCreatingNew) {
                    Text("Create New").tag(true)
                    Text("Open Existing").tag(false)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 200)
                
                if isCreatingNew {
                    createNewWorkspaceView
                } else {
                    openExistingWorkspaceView
                }
                
                Spacer()
                
                // Action Buttons
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                    
                    Spacer()
                    
                    Button(isCreatingNew ? "Create" : "Open") {
                        Task {
                            if isCreatingNew {
                                await createWorkspace()
                            } else {
                                await openWorkspace()
                            }
                        }
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(isCreatingNew ? (workspaceName.isEmpty || selectedURL == nil) : selectedURL == nil)
                }
            }
            .padding(24)
        }
        .frame(width: 480, height: 320)
        .background(VisualEffectView(material: .windowBackground, blendingMode: .behindWindow))
    }
    
    private var createNewWorkspaceView: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Workspace Name")
                    .font(.headline)
                
                TextField("My API Project", text: $workspaceName)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Location")
                    .font(.headline)
                
                HStack {
                    Text(selectedURL?.path ?? "Choose a folder...")
                        .foregroundColor(selectedURL == nil ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
                    
                    Button("Browse...") {
                        showFolderPicker()
                    }
                }
            }
        }
    }
    
    private var openExistingWorkspaceView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Workspace Folder")
                .font(.headline)
            
            HStack {
                Text(selectedURL?.path ?? "Choose workspace folder...")
                    .foregroundColor(selectedURL == nil ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
                
                Button("Browse...") {
                    showWorkspacePicker()
                }
            }
        }
    }
    
    private func showFolderPicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose Location"
        
        if panel.runModal() == .OK {
            selectedURL = panel.url
        }
    }
    
    private func showWorkspacePicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Open Workspace"
        
        if panel.runModal() == .OK {
            selectedURL = panel.url
        }
    }
    
    private func createWorkspace() async {
        guard let url = selectedURL else { return }
        
        await appState.createWorkspace(name: workspaceName, at: url)
        
        if appState.currentWorkspace != nil {
            dismiss()
        }
    }
    
    private func openWorkspace() async {
        guard let url = selectedURL else { return }
        
        await appState.openWorkspace(at: url)
        
        if appState.currentWorkspace != nil {
            dismiss()
        }
    }
}

#Preview {
    WorkspacePickerView()
        .environmentObject(AppState())
}