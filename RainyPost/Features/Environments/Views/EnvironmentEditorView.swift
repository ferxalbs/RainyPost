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
                    .font(.system(size: 18, weight: .semibold))
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.secondary.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 20)
            
            Divider().opacity(0.3)
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    // Environment Name
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Environment Name")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        TextField("Production", text: $environment.name)
                            .textFieldStyle(.plain)
                            .font(.system(size: 15))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                            )
                            .frame(maxWidth: 400)
                    }
                    
                    // Variables Section
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Variables")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button(action: addVariable) {
                                HStack(spacing: 5) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 11, weight: .semibold))
                                    Text("Add Variable")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        if environment.variables.isEmpty {
                            emptyVariablesView
                        } else {
                            variablesListView
                        }
                    }
                }
                .padding(28)
            }
            
            Divider().opacity(0.3)
            
            // Footer
            HStack {
                if isEditing {
                    Button(action: deleteEnvironment) {
                        Text("Delete")
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.plain)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                
                Button(action: saveEnvironment) {
                    Text("Save")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(environment.name.isEmpty ? Color.blue.opacity(0.4) : Color.blue)
                        )
                }
                .buttonStyle(.plain)
                .disabled(environment.name.isEmpty)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 18)
        }
        .frame(width: 600, height: 520)
        .background(
            VisualEffectView(material: .popover, blendingMode: .behindWindow)
        )
    }
    
    private var emptyVariablesView: some View {
        VStack(spacing: 12) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 28))
                .foregroundColor(.secondary.opacity(0.3))
            
            Text("No variables defined")
                .font(.system(size: 14))
                .foregroundColor(.secondary.opacity(0.5))
            
            Button(action: addVariable) {
                Text("Add your first variable")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
    }
    
    private var variablesListView: some View {
        VStack(spacing: 10) {
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
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Enable Toggle
            Button(action: { variable.isEnabled.toggle() }) {
                Image(systemName: variable.isEnabled ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundColor(variable.isEnabled ? .blue : .secondary.opacity(0.3))
            }
            .buttonStyle(.plain)
            
            // Key Field
            TextField("Variable name", text: $variable.key)
                .textFieldStyle(.plain)
                .font(.system(size: 14, design: .monospaced))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
                .frame(width: 180)
            
            // Value Field
            HStack(spacing: 8) {
                if variable.isSecret {
                    SecureField("Value", text: $variable.value)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14, design: .monospaced))
                } else {
                    TextField("Value", text: $variable.value)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14, design: .monospaced))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
            
            // Secret Toggle
            Button(action: { variable.isSecret.toggle() }) {
                Image(systemName: variable.isSecret ? "lock.fill" : "lock.open")
                    .font(.system(size: 13))
                    .foregroundColor(variable.isSecret ? .orange : .secondary.opacity(0.4))
            }
            .buttonStyle(.plain)
            .help(variable.isSecret ? "Secret (stored in Keychain)" : "Plain text")
            
            // Delete Button
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary.opacity(isHovered ? 0.8 : 0.3))
            }
            .buttonStyle(.plain)
        }
        .onHover { hovering in isHovered = hovering }
    }
}

#Preview {
    EnvironmentEditorView()
        .environmentObject(AppState())
}
