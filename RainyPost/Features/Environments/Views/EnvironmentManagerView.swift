//
//  EnvironmentManagerView.swift
//  RainyPost
//
//  Created by Fer on 1/4/26.
//

import SwiftUI

struct EnvironmentManagerView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedEnvironment: APIEnvironment?
    @State private var showingEditor = false
    @State private var editingEnvironment: APIEnvironment?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Manage Environments")
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
            HStack(spacing: 0) {
                environmentListView
                    .frame(width: 200)
                
                Divider()
                
                if let environment = selectedEnvironment {
                    environmentDetailView(environment)
                } else {
                    emptyDetailView
                }
            }
            
            Divider()
            
            // Footer
            HStack {
                Button(action: createEnvironment) {
                    Label("New Environment", systemImage: "plus")
                        .font(.system(size: 11))
                }
                
                Spacer()
                
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(12)
        }
        .frame(width: 560, height: 400)
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(isPresented: $showingEditor) {
            if let env = editingEnvironment {
                EnvironmentEditorView(environment: env)
            } else {
                EnvironmentEditorView()
            }
        }
        .onAppear {
            selectedEnvironment = appState.environments.first
        }
    }
    
    private var environmentListView: some View {
        List(selection: Binding(
            get: { selectedEnvironment?.id },
            set: { id in
                selectedEnvironment = appState.environments.first { $0.id == id }
            }
        )) {
            ForEach(appState.environments) { environment in
                HStack(spacing: 8) {
                    Circle()
                        .fill(environment.isActive ? Color.green : Color.secondary.opacity(0.3))
                        .frame(width: 6, height: 6)
                    
                    Text(environment.name)
                        .font(.system(size: 11))
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text("\(environment.variables.count)")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .tag(environment.id)
            }
        }
        .listStyle(.sidebar)
    }
    
    private func environmentDetailView(_ environment: APIEnvironment) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(environment.name)
                            .font(.system(size: 13, weight: .semibold))
                        
                        if environment.isActive {
                            Text("Active")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.green)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.15))
                                .cornerRadius(3)
                        }
                    }
                    
                    Text("\(environment.variables.count) variables")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    if !environment.isActive {
                        Button("Set Active") {
                            Task { await appState.setActiveEnvironment(environment) }
                        }
                        .font(.system(size: 10))
                    }
                    
                    Button(action: { editEnvironment(environment) }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 11))
                    }
                }
            }
            .padding(12)
            
            Divider()
            
            if environment.variables.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("No variables")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(environment.variables) { variable in
                            VariableDisplayRow(variable: variable)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyDetailView: some View {
        VStack(spacing: 8) {
            Image(systemName: "globe")
                .font(.system(size: 28))
                .foregroundColor(.secondary.opacity(0.4))
            Text("Select an environment")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func createEnvironment() {
        editingEnvironment = nil
        showingEditor = true
    }
    
    private func editEnvironment(_ environment: APIEnvironment) {
        editingEnvironment = environment
        showingEditor = true
    }
}

struct VariableDisplayRow: View {
    let variable: Variable
    
    var body: some View {
        HStack {
            HStack(spacing: 6) {
                if !variable.isEnabled {
                    Image(systemName: "circle")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary.opacity(0.4))
                }
                
                Text(variable.key)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(variable.isEnabled ? .blue : .secondary)
            }
            .frame(width: 120, alignment: .leading)
            
            if variable.isSecret {
                HStack(spacing: 3) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 9))
                    Text("••••••••")
                }
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.orange.opacity(0.8))
            } else {
                Text(variable.value)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(variable.isEnabled ? .primary : .secondary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .opacity(variable.isEnabled ? 1 : 0.6)
    }
}

#Preview {
    EnvironmentManagerView()
        .environmentObject(AppState())
}
