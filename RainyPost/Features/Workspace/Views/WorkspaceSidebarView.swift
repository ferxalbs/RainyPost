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
    @State private var hoveredRequestId: UUID?
    
    enum SidebarSection: String, CaseIterable {
        case collections = "Collections"
        case environments = "Environments"
        case history = "History"
    }
    
    var body: some View {
        ZStack {
            VisualEffectView(material: .sidebar, blendingMode: .behindWindow)
            
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    // Workspace Header
                    if let workspace = appState.currentWorkspace {
                        workspaceHeader(workspace)
                    }
                    
                    // Collections Section
                    sectionView(
                        section: .collections,
                        content: {
                            ForEach(appState.collections) { collection in
                                CollectionRowView(collection: collection)
                            }
                            
                            ForEach(appState.requests.filter { $0.collectionId == nil }) { request in
                                RequestRowView(request: request, isHovered: hoveredRequestId == request.id)
                                    .onHover { hovering in
                                        hoveredRequestId = hovering ? request.id : nil
                                    }
                            }
                        },
                        onAdd: {
                            Task { await appState.createCollection(name: "New Collection") }
                        }
                    )
                    
                    // Environments Section
                    sectionView(
                        section: .environments,
                        content: {
                            ForEach(appState.environments) { environment in
                                EnvironmentRowView(environment: environment)
                            }
                        },
                        onAdd: {
                            Task { await appState.createEnvironment(name: "New Environment") }
                        }
                    )
                    
                    // History Section
                    sectionView(
                        section: .history,
                        content: {
                            Text("Recent requests appear here")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary.opacity(0.6))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                        },
                        onAdd: nil
                    )
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    private func workspaceHeader(_ workspace: Workspace) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.8), .purple.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)
                
                Image(systemName: "folder.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 1) {
                Text(workspace.name)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                
                if let description = workspace.description {
                    Text(description)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .padding(.bottom, 4)
    }
    
    @ViewBuilder
    private func sectionView<Content: View>(
        section: SidebarSection,
        @ViewBuilder content: () -> Content,
        onAdd: (() -> Void)?
    ) -> some View {
        VStack(spacing: 0) {
            // Section Header
            HStack(spacing: 6) {
                Button(action: { toggleSection(section) }) {
                    HStack(spacing: 4) {
                        Image(systemName: expandedSections.contains(section) ? "chevron.down" : "chevron.right")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.secondary.opacity(0.6))
                            .frame(width: 10)
                        
                        Text(section.rawValue.uppercased())
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary.opacity(0.7))
                            .tracking(0.5)
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                if let onAdd = onAdd {
                    Button(action: onAdd) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            
            // Section Content
            if expandedSections.contains(section) {
                content()
            }
        }
    }
    
    private func toggleSection(_ section: SidebarSection) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if expandedSections.contains(section) {
                expandedSections.remove(section)
            } else {
                expandedSections.insert(section)
            }
        }
    }
}

struct CollectionRowView: View {
    let collection: Collection
    @EnvironmentObject private var appState: AppState
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "folder.fill")
                .foregroundColor(.blue.opacity(0.8))
                .font(.system(size: 12))
            
            Text(collection.name)
                .font(.system(size: 12))
                .lineLimit(1)
            
            Spacer()
            
            Text("\(appState.requests.filter { $0.collectionId == collection.id }.count)")
                .font(.system(size: 10))
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(isHovered ? Color.white.opacity(0.05) : Color.clear, in: RoundedRectangle(cornerRadius: 5))
        .contentShape(Rectangle())
        .onHover { hovering in isHovered = hovering }
    }
}

struct RequestRowView: View {
    let request: Request
    let isHovered: Bool
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        HStack(spacing: 8) {
            Text(request.method.rawValue)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(methodColor)
                .frame(width: 36, alignment: .leading)
            
            Text(request.name)
                .font(.system(size: 12))
                .lineLimit(1)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(appState.selectedRequest?.id == request.id ? Color.blue.opacity(0.2) : (isHovered ? Color.white.opacity(0.05) : Color.clear))
        )
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
        case .HEAD, .OPTIONS: return .secondary
        }
    }
}

struct EnvironmentRowView: View {
    let environment: APIEnvironment
    @EnvironmentObject private var appState: AppState
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(environment.isActive ? Color.green : Color.secondary.opacity(0.3))
                .frame(width: 6, height: 6)
            
            Text(environment.name)
                .font(.system(size: 12))
                .fontWeight(environment.isActive ? .medium : .regular)
            
            Spacer()
            
            if environment.isActive {
                Text("Active")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.green.opacity(0.8))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(isHovered ? Color.white.opacity(0.05) : Color.clear, in: RoundedRectangle(cornerRadius: 5))
        .contentShape(Rectangle())
        .onHover { hovering in isHovered = hovering }
        .onTapGesture {
            Task { await appState.setActiveEnvironment(environment) }
        }
    }
}

#Preview {
    WorkspaceSidebarView()
        .environmentObject(AppState())
        .frame(width: 260)
}