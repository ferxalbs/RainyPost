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
    @State private var isCreatingNew = true
    @State private var isProcessing = false
    @State private var errorText: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider().opacity(0.4)
            
            // Content
            VStack(spacing: 16) {
                // Mode Picker
                Picker("", selection: $isCreatingNew) {
                    Text("Create New").tag(true)
                    Text("Open Existing").tag(false)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 200)
                
                // Form
                if isCreatingNew {
                    createNewForm
                } else {
                    openExistingForm
                }
                
                // Error
                if let error = errorText {
                    Text(error)
                        .font(.system(size: 11))
                        .foregroundColor(.red)
                }
                
                Spacer(minLength: 0)
                
                // Buttons
                footerButtons
            }
            .padding(20)
        }
        .frame(width: 380, height: 220)
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    private var headerView: some View {
        HStack {
            Text(isCreatingNew ? "Create Workspace" : "Open Workspace")
                .font(.system(size: 13, weight: .semibold))
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private var createNewForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Name field
            VStack(alignment: .leading, spacing: 4) {
                Text("Name")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                
                TextField("My API Project", text: $workspaceName)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12))
            }
            
            // Location field
            VStack(alignment: .leading, spacing: 4) {
                Text("Location")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    Text(selectedURL?.path ?? "Select folder...")
                        .font(.system(size: 11))
                        .foregroundColor(selectedURL == nil ? .secondary : .primary)
                        .lineLimit(1)
                        .truncationMode(.head)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color(nsColor: .textBackgroundColor))
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
                        )
                    
                    Button("Browse...") {
                        selectFolder()
                    }
                    .font(.system(size: 11))
                }
            }
        }
    }
    
    private var openExistingForm: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Workspace Folder")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
            
            HStack(spacing: 8) {
                Text(selectedURL?.path ?? "Select workspace...")
                    .font(.system(size: 11))
                    .foregroundColor(selectedURL == nil ? .secondary : .primary)
                    .lineLimit(1)
                    .truncationMode(.head)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
                    )
                
                Button("Browse...") {
                    selectWorkspace()
                }
                .font(.system(size: 11))
            }
        }
    }
    
    private var footerButtons: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)
            
            Spacer()
            
            Button(action: performAction) {
                if isProcessing {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 60)
                } else {
                    Text(isCreatingNew ? "Create" : "Open")
                        .frame(width: 60)
                }
            }
            .keyboardShortcut(.defaultAction)
            .disabled(!canProceed || isProcessing)
        }
    }
    
    private var canProceed: Bool {
        if isCreatingNew {
            return !workspaceName.trimmingCharacters(in: .whitespaces).isEmpty && selectedURL != nil
        } else {
            return selectedURL != nil
        }
    }
    
    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose where to create the workspace"
        panel.prompt = "Select"
        
        if panel.runModal() == .OK {
            selectedURL = panel.url
            errorText = nil
        }
    }
    
    private func selectWorkspace() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select a RainyPost workspace folder"
        panel.prompt = "Open"
        
        if panel.runModal() == .OK {
            selectedURL = panel.url
            errorText = nil
        }
    }
    
    private func performAction() {
        guard let url = selectedURL else { return }
        
        isProcessing = true
        errorText = nil
        
        Task {
            if isCreatingNew {
                let name = workspaceName.trimmingCharacters(in: .whitespaces)
                await appState.createWorkspace(name: name, at: url)
            } else {
                await appState.openWorkspace(at: url)
            }
            
            isProcessing = false
            
            if appState.currentWorkspace != nil {
                dismiss()
            } else if let error = appState.errorMessage {
                errorText = error
                appState.errorMessage = nil
            }
        }
    }
}

#Preview {
    WorkspacePickerView()
        .environmentObject(AppState())
}
