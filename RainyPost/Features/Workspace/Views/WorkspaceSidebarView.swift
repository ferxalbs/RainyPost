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
                                .font(.system(size: 13))
                                .foregroundColor(.secondary.opacity(0.5))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                        },
                        onAdd: nil
                    )
                }
                .padding(.vertical, 12)
            }
        }
    }
    
    private func workspaceHeader(_ workspace: Workspace) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.8), .purple.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                
                Image(systemName: "folder.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(workspace.name)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                
                if let description = workspace.description {
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .padding(.bottom, 8)
    }
    
    @ViewBuilder
    private func sectionView<Content: View>(
        section: SidebarSection,
        @ViewBuilder content: () -> Content,
        onAdd: (() -> Void)?
    ) -> some View {
        VStack(spacing: 0) {
            // Section Header
            HStack(spacing: 8) {
                Button(action: { toggleSection(section) }) {
                    HStack(spacing: 6) {
                        Image(systemName: expandedSections.contains(section) ? "chevron.down" : "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary.opacity(0.5))
                            .frame(width: 12)
                        
                        Text(section.rawValue.uppercased())
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary.opacity(0.6))
                            .tracking(0.8)
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                if let onAdd = onAdd {
                    Button(action: onAdd) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            
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
        HStack(spacing: 10) {
            Image(systemName: "folder.fill")
                .foregroundColor(.blue.opacity(0.8))
                .font(.system(size: 14))
            
            Text(collection.name)
                .font(.system(size: 14))
                .lineLimit(1)
            
            Spacer()
            
            Text("\(appState.requests.filter { $0.collectionId == collection.id }.count)")
                .font(.system(size: 12))
                .foregroundColor(.secondary.opacity(0.4))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isHovered ? Color.white.opacity(0.05) : Color.clear, in: RoundedRectangle(cornerRadius: 6))
        .contentShape(Rectangle())
        .onHover { hovering in isHovered = hovering }
    }
}

struct RequestRowView: View {
    let request: Request
    let isHovered: Bool
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        HStack(spacing: 10) {
            Text(request.method.rawValue)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(methodColor)
                .frame(width: 44, alignment: .leading)
            
            Text(request.name)
                .font(.system(size: 14))
                .lineLimit(1)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
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
        HStack(spacing: 10) {
            Circle()
                .fill(environment.isActive ? Color.green : Color.secondary.opacity(0.3))
                .frame(width: 8, height: 8)
            
            Text(environment.name)
                .font(.system(size: 14))
                .fontWeight(environment.isActive ? .medium : .regular)
            
            Spacer()
            
            if environment.isActive {
                Text("Active")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.green.opacity(0.8))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isHovered ? Color.white.opacity(0.05) : Color.clear, in: RoundedRectangle(cornerRadius: 6))
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
        .frame(width: 280, height: 600)
}
