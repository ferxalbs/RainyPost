//
//  WorkspaceSidebarView.swift
//  RainyPost
//
//  Created by Fer on 1/4/26.
//

import SwiftUI

struct WorkspaceSidebarView: View {
    @EnvironmentObject private var appState: AppState
    @State private var expandedSections: Set<SidebarSection> = [.collections, .environments]
    
    enum SidebarSection: String, CaseIterable {
        case collections = "Collections"
        case environments = "Environments"
        case history = "History"
    }
    
    var body: some View {
        List(selection: .constant(appState.selectedRequest?.id)) {
            // Workspace Header
            Section {
                if let workspace = appState.currentWorkspace {
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(workspace.name)
                                .font(.headline)
                                .lineLimit(1)
                            
                            if let description = workspace.description {
                                Text(description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // Collections Section
            Section(isExpanded: .constant(expandedSections.contains(.collections))) {
                ForEach(appState.collections) { collection in
                    CollectionRowView(collection: collection)
                }
                
                ForEach(appState.requests.filter { $0.collectionId == nil }) { request in
                    RequestRowView(request: request)
                }
            } header: {
                SectionHeaderView(
                    title: "Collections",
                    systemImage: "folder",
                    isExpanded: expandedSections.contains(.collections),
                    onToggle: { toggleSection(.collections) },
                    onAdd: {
                        Task {
                            await appState.createCollection(name: "New Collection")
                        }
                    }
                )
            }
            
            // Environments Section
            Section(isExpanded: .constant(expandedSections.contains(.environments))) {
                ForEach(appState.environments) { environment in
                    EnvironmentRowView(environment: environment)
                }
            } header: {
                SectionHeaderView(
                    title: "Environments",
                    systemImage: "globe",
                    isExpanded: expandedSections.contains(.environments),
                    onToggle: { toggleSection(.environments) },
                    onAdd: {
                        Task {
                            await appState.createEnvironment(name: "New Environment")
                        }
                    }
                )
            }
            
            // History Section
            Section(isExpanded: .constant(expandedSections.contains(.history))) {
                // TODO: History items
                Text("Recent requests will appear here")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } header: {
                SectionHeaderView(
                    title: "History",
                    systemImage: "clock",
                    isExpanded: expandedSections.contains(.history),
                    onToggle: { toggleSection(.history) },
                    onAdd: nil
                )
            }
        }
        .listStyle(.sidebar)
        .background(VisualEffectView(material: .sidebar, blendingMode: .behindWindow))
    }
    
    private func toggleSection(_ section: SidebarSection) {
        if expandedSections.contains(section) {
            expandedSections.remove(section)
        } else {
            expandedSections.insert(section)
        }
    }
}

struct SectionHeaderView: View {
    let title: String
    let systemImage: String
    let isExpanded: Bool
    let onToggle: () -> Void
    let onAdd: (() -> Void)?
    
    var body: some View {
        HStack {
            Button(action: onToggle) {
                HStack(spacing: 6) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Image(systemName: systemImage)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text(title)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                }
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            if let onAdd = onAdd {
                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .opacity(0.7)
                .onHover { hovering in
                    // Add hover effect
                }
            }
        }
        .padding(.horizontal, 4)
    }
}

struct CollectionRowView: View {
    let collection: Collection
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        HStack {
            Image(systemName: "folder.fill")
                .foregroundColor(.blue)
                .font(.system(size: 14))
            
            Text(collection.name)
                .font(.system(size: 13))
            
            Spacer()
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }
}

struct RequestRowView: View {
    let request: Request
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        HStack {
            // HTTP Method Badge
            Text(request.method.rawValue)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(methodColor, in: RoundedRectangle(cornerRadius: 3))
            
            Text(request.name)
                .font(.system(size: 13))
                .lineLimit(1)
            
            Spacer()
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture {
            appState.selectedRequest = request
        }
    }
    
    private var methodColor: Color {
        switch request.method {
        case .GET: return .green
        case .POST: return .blue
        case .PUT: return .orange
        case .PATCH: return .purple
        case .DELETE: return .red
        case .HEAD: return .gray
        case .OPTIONS: return .gray
        }
    }
}

struct EnvironmentRowView: View {
    let environment: APIEnvironment
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        HStack {
            Image(systemName: environment.isActive ? "circle.fill" : "circle")
                .foregroundColor(environment.isActive ? .green : .secondary)
                .font(.system(size: 8))
            
            Text(environment.name)
                .font(.system(size: 13))
                .fontWeight(environment.isActive ? .medium : .regular)
            
            Spacer()
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture {
            Task {
                await appState.setActiveEnvironment(environment)
            }
        }
    }
}

#Preview {
    WorkspaceSidebarView()
        .environmentObject(AppState())
        .frame(width: 280)
}