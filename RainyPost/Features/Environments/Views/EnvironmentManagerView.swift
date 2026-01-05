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
            HStack(spacing: 0) {
                // Environment List
                environmentListView
                    .frame(width: 240)
                
                Divider().opacity(0.3)
                
                // Environment Detail
                if let environment = selectedEnvironment {
                    environmentDetailView(environment)
                } else {
                    emptyDetailView
                }
            }
            
            Divider().opacity(0.3)
            
            // Footer
            HStack {
                Button(action: createEnvironment) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .semibold))
                        Text("New Environment")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.plain)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.blue)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 18)
        }
        .frame(width: 720, height: 520)
        .background(
            VisualEffectView(material: .popover, blendingMode: .behindWindow)
        )
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
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(appState.environments) { environment in
                    EnvironmentListRow(
                        environment: environment,
                        isSelected: selectedEnvironment?.id == environment.id,
                        isActive: environment.isActive
                    )
                    .onTapGesture {
                        selectedEnvironment = environment
                    }
                }
            }
            .padding(12)
        }
    }
    
    private func environmentDetailView(_ environment: APIEnvironment) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Environment Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 10) {
                        Text(environment.name)
                            .font(.system(size: 16, weight: .semibold))
                        
                        if environment.isActive {
                            Text("Active")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(.green.opacity(0.15), in: RoundedRectangle(cornerRadius: 4))
                        }
                    }
                    
                    Text("\(environment.variables.count) variables")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    if !environment.isActive {
                        Button("Set Active") {
                            Task {
                                await appState.setActiveEnvironment(environment)
                            }
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.blue)
                    }
                    
                    Button(action: { editEnvironment(environment) }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
            
            Divider().opacity(0.2)
            
            // Variables List
            if environment.variables.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary.opacity(0.3))
                    
                    Text("No variables")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary.opacity(0.5))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(environment.variables) { variable in
                            VariableDisplayRow(variable: variable)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyDetailView: some View {
        VStack(spacing: 12) {
            Image(systemName: "globe")
                .font(.system(size: 36))
                .foregroundColor(.secondary.opacity(0.3))
            
            Text("Select an environment")
                .font(.system(size: 14))
                .foregroundColor(.secondary.opacity(0.5))
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

struct EnvironmentListRow: View {
    let environment: APIEnvironment
    let isSelected: Bool
    let isActive: Bool
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(isActive ? Color.green : Color.secondary.opacity(0.3))
                .frame(width: 8, height: 8)
            
            Text(environment.name)
                .font(.system(size: 14))
                .fontWeight(isActive ? .medium : .regular)
                .lineLimit(1)
            
            Spacer()
            
            Text("\(environment.variables.count)")
                .font(.system(size: 11))
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.blue.opacity(0.2) : (isHovered ? Color.white.opacity(0.05) : Color.clear))
        )
        .contentShape(Rectangle())
        .onHover { hovering in isHovered = hovering }
    }
}

struct VariableDisplayRow: View {
    let variable: Variable
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                if !variable.isEnabled {
                    Image(systemName: "circle")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.3))
                }
                
                Text(variable.key)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(variable.isEnabled ? .blue : .secondary.opacity(0.5))
            }
            .frame(width: 160, alignment: .leading)
            
            if variable.isSecret {
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                    Text("••••••••")
                }
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.orange.opacity(0.7))
            } else {
                Text(variable.value)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(variable.isEnabled ? .primary : .secondary.opacity(0.5))
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .opacity(variable.isEnabled ? 1 : 0.6)
    }
}

#Preview {
    EnvironmentManagerView()
        .environmentObject(AppState())
}
