//
//  EnvironmentEditorView.swift
//  RainyPost
//
//  Created by Fer on 1/4/26.
//

import SwiftUI

struct EnvironmentEditorView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var environment: APIEnvironment
    @State private var isEditing: Bool
    
    init(environment: APIEnvironment? = nil) {
        if let env = environment {
            _environment = State(initialValue: env)
            _isEditing = State(initialValue: true)
        } else {
            _environment = State(initialValue: APIEnvironment(name: "New Environment"))
            _isEditing = State(initialValue: false)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(isEditing ? "Edit Environment" : "New Environment")
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
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Environment Name
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Environment Name")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        TextField("Production", text: $environment.name)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12))
                            .frame(maxWidth: 300)
                    }
                    
                    // Variables Section
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Variables")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button(action: addVariable) {
                                Label("Add Variable", systemImage: "plus")
                                    .font(.system(size: 10))
                            }
                        }
                        
                        if environment.variables.isEmpty {
                            emptyVariablesView
                        } else {
                            variablesListView
                        }
                    }
                }
                .padding(16)
            }
            
            Divider()
            
            // Footer
            HStack {
                if isEditing {
                    Button("Delete") { deleteEnvironment() }
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                
                Button("Save") { saveEnvironment() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(environment.name.isEmpty)
            }
            .padding(12)
        }
        .frame(width: 480, height: 400)
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    private var emptyVariablesView: some View {
        VStack(spacing: 8) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 24))
                .foregroundColor(.secondary.opacity(0.4))
            
            Text("No variables defined")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            Button("Add your first variable") { addVariable() }
                .font(.system(size: 10))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
    
    private var variablesListView: some View {
        VStack(spacing: 6) {
            ForEach($environment.variables) { $variable in
                VariableEditorRow(
                    variable: $variable,
                    onDelete: { deleteVariable(variable) }
                )
            }
        }
    }
    
    private func addVariable() {
        environment.variables.append(Variable(key: "", value: ""))
    }
    
    private func deleteVariable(_ variable: Variable) {
        environment.variables.removeAll { $0.id == variable.id }
    }
    
    private func saveEnvironment() {
        Task {
            guard let workspaceURL = appState.workspaceURL else { return }
            
            let manager = WorkspaceManager()
            try? await manager.saveEnvironment(environment, to: workspaceURL)
            
            if isEditing {
                if let index = appState.environments.firstIndex(where: { $0.id == environment.id }) {
                    appState.environments[index] = environment
                }
            } else {
                appState.environments.append(environment)
            }
            
            dismiss()
        }
    }
    
    private func deleteEnvironment() {
        appState.environments.removeAll { $0.id == environment.id }
        dismiss()
    }
}

struct VariableEditorRow: View {
    @Binding var variable: Variable
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // Enable Toggle
            Toggle("", isOn: $variable.isEnabled)
                .labelsHidden()
                .scaleEffect(0.8)
            
            // Key Field
            TextField("Variable name", text: $variable.key)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 11, design: .monospaced))
                .frame(width: 140)
            
            // Value Field
            if variable.isSecret {
                SecureField("Value", text: $variable.value)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 11, design: .monospaced))
            } else {
                TextField("Value", text: $variable.value)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 11, design: .monospaced))
            }
            
            // Secret Toggle
            Button(action: { variable.isSecret.toggle() }) {
                Image(systemName: variable.isSecret ? "lock.fill" : "lock.open")
                    .font(.system(size: 11))
                    .foregroundColor(variable.isSecret ? .orange : .secondary)
            }
            .buttonStyle(.plain)
            .help(variable.isSecret ? "Secret (stored in Keychain)" : "Plain text")
            
            // Delete Button
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    EnvironmentEditorView()
        .environmentObject(AppState())
}
