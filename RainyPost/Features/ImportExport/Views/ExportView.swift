//
//  ExportView.swift
//  RainyPost
//
//  Created by Fer on 1/4/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct ExportView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var exportType: ExportType = .workspace
    @State private var includeEnvironments = true
    @State private var stripSecrets = true
    @State private var isExporting = false
    @State private var exportSuccess = false
    @State private var errorMessage: String?
    
    enum ExportType: String, CaseIterable {
        case workspace = "Workspace (ZIP)"
        case curl = "cURL Command"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Export")
                    .font(.system(size: 14, weight: .semibold))
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
            
            Divider()
            
            // Content
            VStack(alignment: .leading, spacing: 16) {
                // Export Type
                VStack(alignment: .leading, spacing: 6) {
                    Text("Export Type")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Picker("", selection: $exportType) {
                        ForEach(ExportType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 280)
                }
                
                // Options
                if exportType == .workspace {
                    workspaceOptions
                } else {
                    curlOptions
                }
                
                // Result/Error
                if exportSuccess {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Export successful")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(8)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(4)
                }
                
                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 11))
                        .foregroundColor(.red)
                        .padding(8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(4)
                }
                
                Spacer()
            }
            .padding(16)
            
            Divider()
            
            // Footer
            HStack {
                Spacer()
                
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                
                Button(action: performExport) {
                    if isExporting {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 60)
                    } else {
                        Text("Export")
                            .frame(width: 60)
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(isExporting || (exportType == .curl && appState.selectedRequest == nil))
            }
            .padding(12)
        }
        .frame(width: 380, height: 300)
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    private var workspaceOptions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Options")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
            
            Toggle("Include environments", isOn: $includeEnvironments)
                .font(.system(size: 11))
            
            Toggle("Strip secrets (recommended)", isOn: $stripSecrets)
                .font(.system(size: 11))
            
            if !stripSecrets {
                Text("⚠️ Secrets will be included in the export")
                    .font(.system(size: 10))
                    .foregroundColor(.orange)
            }
        }
    }
    
    private var curlOptions: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let request = appState.selectedRequest {
                Text("Request: \(request.name)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                Text("The cURL command will be copied to clipboard")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.7))
            } else {
                Text("Select a request to export as cURL")
                    .font(.system(size: 11))
                    .foregroundColor(.orange)
            }
        }
    }
    
    private func performExport() {
        isExporting = true
        errorMessage = nil
        exportSuccess = false
        
        Task {
            do {
                switch exportType {
                case .workspace:
                    try await exportWorkspace()
                case .curl:
                    exportCurl()
                }
                exportSuccess = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isExporting = false
        }
    }
    
    private func exportWorkspace() async throws {
        guard let workspace = appState.currentWorkspace,
              let workspaceURL = appState.workspaceURL else {
            throw ExportError.noWorkspace
        }
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.zip]
        panel.nameFieldStringValue = "\(workspace.name).zip"
        panel.message = "Choose where to save the workspace export"
        
        guard panel.runModal() == .OK, let url = panel.url else {
            throw ExportError.cancelled
        }
        
        let exporter = WorkspaceExporter()
        let options = WorkspaceExporter.ExportOptions(
            includeHistory: false,
            includeEnvironments: includeEnvironments,
            stripSecrets: stripSecrets
        )
        
        try await exporter.export(
            workspace: workspace,
            workspaceURL: workspaceURL,
            to: url,
            options: options
        )
    }
    
    private func exportCurl() {
        guard let request = appState.selectedRequest else { return }
        
        let exporter = CurlExporter()
        let curl = exporter.export(request: request, environment: appState.activeEnvironment)
        
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(curl, forType: .string)
    }
    
    enum ExportError: LocalizedError {
        case noWorkspace
        case cancelled
        
        var errorDescription: String? {
            switch self {
            case .noWorkspace:
                return "No workspace is open"
            case .cancelled:
                return "Export was cancelled"
            }
        }
    }
}

#Preview {
    ExportView()
        .environmentObject(AppState())
}
