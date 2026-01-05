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
                Divider().opacity(0.3)
                requestBuilderView
            }
            .frame(minHeight: 320)
            
            // Response Viewer
            ResponseViewerView(viewModel: viewModel)
                .frame(minHeight: 280)
        }
        .onAppear {
            viewModel.activeEnvironment = appState.activeEnvironment
        }
        .onChange(of: appState.activeEnvironment) { _, newValue in
            viewModel.activeEnvironment = newValue
        }
    }
    
    private var requestHeaderView: some View {
        HStack(spacing: 14) {
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
                HStack(spacing: 6) {
                    Text(viewModel.method.rawValue)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                }
                .foregroundColor(methodColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(methodColor.opacity(0.3), lineWidth: 1)
                )
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            
            // URL Input
            TextField("https://api.example.com/endpoint", text: $viewModel.url)
                .textFieldStyle(.plain)
                .font(.system(size: 14, design: .monospaced))
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                )
            
            // Send Button
            Button(action: { Task { await viewModel.sendRequest() } }) {
                HStack(spacing: 8) {
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.7)
                            .frame(width: 14, height: 14)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 13))
                    }
                    Text("Send")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [.blue, .blue.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    in: RoundedRectangle(cornerRadius: 8)
                )
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoading || viewModel.url.isEmpty)
            .keyboardShortcut(.return, modifiers: .command)
        }
        .padding(18)
    }
    
    private var requestBuilderView: some View {
        VStack(spacing: 0) {
            // Tab Bar
            RequestTabBar(selectedTab: $viewModel.selectedTab)
            
            Divider().opacity(0.2)
            
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
        HStack(spacing: 4) {
            ForEach(RequestTab.allCases, id: \.self) { tab in
                TabButton(tab: tab, isSelected: selectedTab == tab) {
                    selectedTab = tab
                }
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

struct TabButton: View {
    let tab: RequestTab
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 12))
                Text(tab.rawValue)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(isSelected ? .primary : .secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
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
        .padding(18)
    }
}

#Preview {
    RequestDetailView(request: Request(name: "Test", method: .GET, url: "https://api.example.com"))
        .environmentObject(AppState())
        .frame(width: 900, height: 700)
}
