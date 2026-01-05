//
//  RequestDetailView.swift
//  RainyPost
//
//  Created by Fer on 1/4/26.
//

import SwiftUI

struct RequestDetailView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: RequestViewModel
    
    init(request: Request) {
        _viewModel = StateObject(wrappedValue: RequestViewModel(request: request))
    }
    
    var body: some View {
        VSplitView {
            // Request Builder
            VStack(spacing: 0) {
                requestHeaderView
                Divider().opacity(0.5)
                requestBuilderView
            }
            .frame(minHeight: 280)
            
            // Response Viewer
            ResponseViewerView(viewModel: viewModel)
                .frame(minHeight: 200)
        }
    }
    
    private var requestHeaderView: some View {
        HStack(spacing: 10) {
            // Method Picker
            Menu {
                ForEach(HTTPMethod.allCases, id: \.self) { method in
                    Button(action: { viewModel.method = method }) {
                        HStack {
                            Text(method.rawValue)
                            if viewModel.method == method {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(viewModel.method.rawValue)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .semibold))
                }
                .foregroundColor(methodColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(methodColor.opacity(0.3), lineWidth: 1)
                )
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            
            // URL Input
            TextField("https://api.example.com/endpoint", text: $viewModel.url)
                .textFieldStyle(.plain)
                .font(.system(size: 13, design: .monospaced))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                )
            
            // Send Button
            Button(action: { Task { await viewModel.sendRequest() } }) {
                HStack(spacing: 5) {
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 12, height: 12)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 11))
                    }
                    Text("Send")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    LinearGradient(
                        colors: [.blue, .blue.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    in: RoundedRectangle(cornerRadius: 6)
                )
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoading || viewModel.url.isEmpty)
            .keyboardShortcut(.return, modifiers: .command)
        }
        .padding(12)
    }
    
    private var requestBuilderView: some View {
        VStack(spacing: 0) {
            // Tab Bar
            RequestTabBar(selectedTab: $viewModel.selectedTab)
            
            Divider().opacity(0.3)
            
            // Tab Content
            TabContentView(viewModel: viewModel)
        }
    }
    
    private var methodColor: Color {
        switch viewModel.method {
        case .GET: return .green
        case .POST: return .blue
        case .PUT: return .orange
        case .PATCH: return .purple
        case .DELETE: return .red
        case .HEAD, .OPTIONS: return .secondary
        }
    }
}

// MARK: - Request Tab Bar

struct RequestTabBar: View {
    @Binding var selectedTab: RequestTab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(RequestTab.allCases, id: \.self) { tab in
                TabButton(tab: tab, isSelected: selectedTab == tab) {
                    selectedTab = tab
                }
            }
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }
}

struct TabButton: View {
    let tab: RequestTab
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 10))
                Text(tab.rawValue)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(isSelected ? .primary : .secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(isSelected ? Color.white.opacity(0.1) : (isHovered ? Color.white.opacity(0.05) : Color.clear))
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in isHovered = hovering }
    }
}

enum RequestTab: String, CaseIterable {
    case params = "Params"
    case headers = "Headers"
    case auth = "Auth"
    case body = "Body"
    
    var systemImage: String {
        switch self {
        case .params: return "questionmark.circle"
        case .headers: return "list.bullet"
        case .auth: return "key"
        case .body: return "doc.text"
        }
    }
}

// MARK: - Tab Content

struct TabContentView: View {
    @ObservedObject var viewModel: RequestViewModel
    
    var body: some View {
        Group {
            switch viewModel.selectedTab {
            case .params:
                KeyValueEditor(
                    title: "Query Parameters",
                    items: $viewModel.queryParams,
                    keyPlaceholder: "Parameter",
                    valuePlaceholder: "Value"
                )
            case .headers:
                KeyValueEditor(
                    title: "Headers",
                    items: $viewModel.headers,
                    keyPlaceholder: "Header",
                    valuePlaceholder: "Value"
                )
            case .auth:
                AuthConfigView(viewModel: viewModel)
            case .body:
                BodyEditorView(viewModel: viewModel)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(12)
    }
}

#Preview {
    RequestDetailView(request: Request(name: "Test", method: .GET, url: "https://api.example.com"))
        .environmentObject(AppState())
        .frame(width: 800, height: 600)
}
