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
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(isCreatingNew ? "Create Workspace" : "Open Workspace")
                    .font(.system(size: 18, weight: .semibold))
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.secondary.opacity(0.6))
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 20)
            
            Divider().opacity(0.3)
            
            // Content
            VStack(spacing: 28) {
                // Mode Picker
                Picker("Mode", selection: $isCreatingNew) {
                    Text("Create New").tag(true)
                    Text("Open Existing").tag(false)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 280)
                .padding(.top, 12)
                
                if isCreatingNew {
                    createNewWorkspaceView
                } else {
                    openExistingWorkspaceView
                }
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: 16) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .keyboardShortcut(.cancelAction)
                    
                    Spacer()
                    
                    Button(action: {
                        Task {
                            if isCreatingNew {
                                await createWorkspace()
                            } else {
                                await openWorkspace()
                            }
                        }
                    }) {
                        Text(isCreatingNew ? "Create" : "Open")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(canProceed ? Color.blue : Color.blue.opacity(0.4))
                            )
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!canProceed)
                }
            }
            .padding(28)
        }
        .frame(width: 520, height: 360)
        .background(
            VisualEffectView(material: .popover, blendingMode: .behindWindow)
        )
    }
    
    private var canProceed: Bool {
        isCreatingNew ? (!workspaceName.isEmpty && selectedURL != nil) : selectedURL != nil
    }
    
    private var createNewWorkspaceView: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Workspace Name")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                
                TextField("My API Project", text: $workspaceName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                    )
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Location")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    Text(selectedURL?.path ?? "Choose a folder...")
                        .font(.system(size: 14))
                        .foregroundColor(selectedURL == nil ? .secondary.opacity(0.6) : .primary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                        )
                    
                    Button("Browse") {
                        showFolderPicker()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 13, weight: .medium))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
    
    private var openExistingWorkspaceView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Workspace Folder")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                Text(selectedURL?.path ?? "Choose workspace folder...")
                    .font(.system(size: 14))
                    .foregroundColor(selectedURL == nil ? .secondary.opacity(0.6) : .primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                    )
                
                Button("Browse") {
                    showWorkspacePicker()
                }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .medium))
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
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
        if appState.currentWorkspace != nil { dismiss() }
    }
    
    private func openWorkspace() async {
        guard let url = selectedURL else { return }
        await appState.openWorkspace(at: url)
        if appState.currentWorkspace != nil { dismiss() }
    }
}

#Preview {
    WorkspacePickerView()
        .environmentObject(AppState())
}
