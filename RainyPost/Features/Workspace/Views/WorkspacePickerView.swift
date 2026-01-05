//
//  WorkspacePickerView.swift
//  RainyPost
//
//  Created by Fer on 1/4/26.
//

import SwiftUI
import AppKit

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
            VStack(spacing: 4) {
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(.blue)
                
                Text(isCreatingNew ? "Create Workspace" : "Open Workspace")
                    .font(.system(size: 15, weight: .semibold))
            }
            .padding(.top, 24)
            .padding(.bottom, 20)
            
            Picker("", selection: $isCreatingNew) {
                Text("Create New").tag(true)
                Text("Open Existing").tag(false)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 240)
            .padding(.bottom, 20)
            .onChange(of: isCreatingNew) { _, _ in
                selectedURL = nil
                errorText = nil
            }
            
            VStack(alignment: .leading, spacing: 16) {
                if isCreatingNew {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Name")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        TextField("", text: $workspaceName, prompt: Text("My API Project"))
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Location")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 8) {
                            Text(selectedURL?.path ?? "Select folder...")
                                .font(.system(size: 12))
                                .foregroundColor(selectedURL == nil ? .secondary : .primary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(Color(nsColor: .controlBackgroundColor))
                                .cornerRadius(5)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 1)
                                )
                            
                            Button("Browse...") {
                                selectFolder()
                            }
                        }
                    }
                    
                    if let url = selectedURL, !workspaceName.isEmpty {
                        Text("Will create: \(url.appendingPathComponent(workspaceName).path)")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Workspace Folder")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 8) {
                            Text(selectedURL?.path ?? "Select workspace folder...")
                                .font(.system(size: 12))
                                .foregroundColor(selectedURL == nil ? .secondary : .primary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(Color(nsColor: .controlBackgroundColor))
                                .cornerRadius(5)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 1)
                                )
                            
                            Button("Browse...") {
                                selectWorkspace()
                            }
                        }
                    }
                }
                
                if let error = errorText {
                    Text(error)
                        .font(.system(size: 11))
                        .foregroundColor(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 28)
            
            Spacer()
            
            HStack(spacing: 12) {
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button(action: performAction) {
                    if isProcessing {
                        ProgressView()
                            .controlSize(.small)
                            .frame(width: 50)
                    } else {
                        Text(isCreatingNew ? "Create" : "Open")
                            .frame(width: 50)
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(!canProceed || isProcessing)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(width: 400, height: isCreatingNew ? 320 : 240)
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
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
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
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
        panel.prompt = "Open"
        
        if panel.runModal() == .OK, let url = panel.url {
            let workspaceFile = url.appendingPathComponent("workspace.json")
            if FileManager.default.fileExists(atPath: workspaceFile.path) {
                selectedURL = url
                errorText = nil
            } else {
                errorText = "Not a valid workspace (missing workspace.json)"
                selectedURL = nil
            }
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
