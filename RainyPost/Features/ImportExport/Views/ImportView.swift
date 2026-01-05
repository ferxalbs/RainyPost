//
//  ImportView.swift
//  RainyPost
//
//  Created by Fer on 1/4/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct ImportView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var importType: ImportType = .postmanCollection
    @State private var selectedFileURL: URL?
    @State private var isImporting = false
    @State private var importResult: ImportResultState?
    @State private var errorMessage: String?
    
    enum ImportType: String, CaseIterable {
        case postmanCollection = "Postman Collection"
        case postmanEnvironment = "Postman Environment"
    }
    
    enum ImportResultState {
        case success(collections: Int, requests: Int, warnings: [String])
        case environmentSuccess(name: String)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Import")
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
                // Import Type
                VStack(alignment: .leading, spacing: 6) {
                    Text("Import Type")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Picker("", selection: $importType) {
                        ForEach(ImportType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 300)
                }
                
                // File Selection
                VStack(alignment: .leading, spacing: 6) {
                    Text("File")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        Text(selectedFileURL?.lastPathComponent ?? "No file selected")
                            .font(.system(size: 11))
                            .foregroundColor(selectedFileURL == nil ? .secondary : .primary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color(nsColor: .textBackgroundColor))
                            .cornerRadius(4)
                        
                        Button("Browse...") { selectFile() }
                            .font(.system(size: 11))
                    }
                }
                
                // Result/Error
                if let result = importResult {
                    resultView(result)
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
                
                Button(action: performImport) {
                    if isImporting {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 60)
                    } else {
                        Text("Import")
                            .frame(width: 60)
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(selectedFileURL == nil || isImporting)
            }
            .padding(12)
        }
        .frame(width: 420, height: 320)
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    @ViewBuilder
    private func resultView(_ result: ImportResultState) -> some View {
        switch result {
        case .success(let collections, let requests, let warnings):
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Import successful")
                        .font(.system(size: 12, weight: .medium))
                }
                
                Text("\(collections) collections, \(requests) requests imported")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                if !warnings.isEmpty {
                    Text("\(warnings.count) warnings")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                }
            }
            .padding(8)
            .background(Color.green.opacity(0.1))
            .cornerRadius(4)
            
        case .environmentSuccess(let name):
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Environment '\(name)' imported")
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(8)
            .background(Color.green.opacity(0.1))
            .cornerRadius(4)
        }
    }
    
    private func selectFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.json]
        panel.message = "Select a Postman export file"
        
        if panel.runModal() == .OK {
            selectedFileURL = panel.url
            importResult = nil
            errorMessage = nil
        }
    }
    
    private func performImport() {
        guard let url = selectedFileURL, let workspaceURL = appState.workspaceURL else { return }
        
        isImporting = true
        errorMessage = nil
        importResult = nil
        
        Task {
            do {
                switch importType {
                case .postmanCollection:
                    let importer = PostmanImporter()
                    let result = try await importer.importCollection(from: url)
                    
                    // Save imported items
                    let manager = WorkspaceManager()
                    for collection in result.collections {
                        try await manager.saveCollection(collection, to: workspaceURL)
                        appState.collections.append(collection)
                    }
                    for request in result.requests {
                        try await manager.saveRequest(request, to: workspaceURL)
                        appState.requests.append(request)
                    }
                    
                    importResult = .success(
                        collections: result.collections.count,
                        requests: result.requests.count,
                        warnings: result.warnings
                    )
                    
                case .postmanEnvironment:
                    let importer = PostmanImporter()
                    let environment = try await importer.importEnvironment(from: url)
                    
                    let manager = WorkspaceManager()
                    try await manager.saveEnvironment(environment, to: workspaceURL)
                    appState.environments.append(environment)
                    
                    importResult = .environmentSuccess(name: environment.name)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            
            isImporting = false
        }
    }
}

#Preview {
    ImportView()
        .environmentObject(AppState())
}
