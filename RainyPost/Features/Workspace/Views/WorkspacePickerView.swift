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
        VStack(spacing: 20) {
            // Mode Picker
            Picker("", selection: $isCreatingNew) {
                Text("Create New").tag(true)
                Text("Open Existing").tag(false)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 220)
            
            // Form Content
            VStack(spacing: 16) {
                if isCreatingNew {
                    createNewForm
                } else {
                    openExistingForm
                }
            }
            .frame(maxWidth: .infinity)
            
            // Error Message
            if let error = errorText {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Spacer(minLength: 0)
            
            // Action Buttons
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button(action: performAction) {
                    if isProcessing {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text(isCreatingNew ? "Create" : "Open")
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(!canProceed || isProcessing)
            }
        }
        .padding(24)
        .frame(width: 420, height: 240)
    }
    
    private var createNewForm: some View {
        Form {
            TextField("Name:", text: $workspaceName, prompt: Text("My API Project"))
            
            LabeledContent("Location:") {
                HStack(spacing: 8) {
                    Text(selectedURL?.lastPathComponent ?? "Select folder...")
                        .foregroundColor(selectedURL == nil ? .secondary : .primary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Button("Browse...") {
                        selectFolder()
                    }
                    .controlSize(.small)
                }
            }
        }
        .formStyle(.grouped)
    }
    
    private var openExistingForm: some View {
        Form {
            LabeledContent("Workspace:") {
                HStack(spacing: 8) {
                    Text(selectedURL?.lastPathComponent ?? "Select workspace...")
                        .foregroundColor(selectedURL == nil ? .secondary : .primary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Button("Browse...") {
                        selectWorkspace()
                    }
                    .controlSize(.small)
                }
            }
        }
        .formStyle(.grouped)
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
