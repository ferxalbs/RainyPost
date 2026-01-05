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
                    .font(.system(size: 14, weight: .semibold))
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            
            Divider().opacity(0.3)
            
            // Content
            VStack(spacing: 18) {
                // Mode Picker
                Picker("Mode", selection: $isCreatingNew) {
                    Text("Create New").tag(true)
                    Text("Open Existing").tag(false)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 220)
                .padding(.top, 6)
                
                if isCreatingNew {
                    createNewWorkspaceView
                } else {
                    openExistingWorkspaceView
                }
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: 12) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    
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
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 7)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(canProceed ? Color.blue : Color.blue.opacity(0.4))
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(!canProceed)
                }
            }
            .padding(20)
        }
        .frame(width: 400, height: 240)
        .background(
            VisualEffectView(material: .popover, blendingMode: .behindWindow)
        )
    }
    
    private var canProceed: Bool {
        isCreatingNew ? (!workspaceName.isEmpty && selectedURL != nil) : selectedURL != nil
    }
    
    private var createNewWorkspaceView: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Workspace Name")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                
                TextField("My API Project", text: $workspaceName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                    )
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Location")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    Text(selectedURL?.path ?? "Choose a folder...")
                        .font(.system(size: 12))
                        .foregroundColor(selectedURL == nil ? .secondary.opacity(0.5) : .primary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                        )
                    
                    Button("Browse") {
                        showFolderPicker()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                }
            }
        }
    }
    
    private var openExistingWorkspaceView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Workspace Folder")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
            
            HStack(spacing: 8) {
                Text(selectedURL?.path ?? "Choose workspace folder...")
                    .font(.system(size: 12))
                    .foregroundColor(selectedURL == nil ? .secondary.opacity(0.5) : .primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                    )
                
                Button("Browse") {
                    showWorkspacePicker()
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
            }
        }
    }
    
    private func showFolderPicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"
        
        if panel.runModal() == .OK {
            selectedURL = panel.url
        }
    }
    
    private func showWorkspacePicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Open"
        
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
