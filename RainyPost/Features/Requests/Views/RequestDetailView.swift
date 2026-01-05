//
//  RequestDetailView.swift
//  RainyPost
//
//  Created by Fer on 1/4/26.
//

import SwiftUI
import SwiftData

struct RequestDetailView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: RequestViewModel
    
    init(request: Request) {
        _viewModel = StateObject(wrappedValue: RequestViewModel(request: request))
    }
    
    var body: some View {
        VSplitView {
            // Request Builder
            VStack(spacing: 0) {
                requestHeader
                Divider()
                requestTabs
            }
            .frame(minHeight: 250)
            
            // Response
            ResponseViewerView(viewModel: viewModel)
                .frame(minHeight: 200)
        }
        .onAppear {
            viewModel.activeEnvironment = appState.activeEnvironment
            viewModel.workspaceId = appState.currentWorkspace?.id
            viewModel.historyService = HistoryService(modelContext: modelContext)
        }
        .onChange(of: appState.activeEnvironment) { _, newValue in
            viewModel.activeEnvironment = newValue
        }
    }
    
    private var requestHeader: some View {
        HStack(spacing: 8) {
            // Method
            Picker("", selection: $viewModel.method) {
                ForEach(HTTPMethod.allCases, id: \.self) { method in
                    Text(method.rawValue).tag(method)
                }
            }
            .labelsHidden()
            .frame(width: 90)
            
            // URL
            TextField("https://api.example.com/endpoint", text: $viewModel.url)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12, design: .monospaced))
            
            // Send
            Button(action: { Task { await viewModel.sendRequest() } }) {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 50)
                } else {
                    Text("Send")
                        .frame(width: 50)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.url.isEmpty || viewModel.isLoading)
            .keyboardShortcut(.return, modifiers: .command)
        }
        .padding(12)
    }
    
    private var requestTabs: some View {
        VStack(spacing: 0) {
            // Tab Bar
            HStack(spacing: 0) {
                ForEach(RequestTab.allCases, id: \.self) { tab in
                    Button(action: { viewModel.selectedTab = tab }) {
                        Text(tab.rawValue)
                            .font(.system(size: 11, weight: viewModel.selectedTab == tab ? .semibold : .regular))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                    .background(viewModel.selectedTab == tab ? Color.accentColor.opacity(0.1) : Color.clear)
                    .cornerRadius(4)
                }
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            
            Divider()
            
            // Tab Content
            ScrollView {
                tabContent
                    .padding(12)
            }
        }
    }
    
    @ViewBuilder
    private var tabContent: some View {
        switch viewModel.selectedTab {
        case .params:
            KeyValueEditor(
                title: "Query Parameters",
                items: $viewModel.queryParams,
                keyPlaceholder: "Key",
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
}

enum RequestTab: String, CaseIterable {
    case params = "Params"
    case headers = "Headers"
    case auth = "Auth"
    case body = "Body"
}

#Preview {
    RequestDetailView(request: Request(name: "Test", method: .GET, url: "https://api.example.com"))
        .environmentObject(AppState())
        .frame(width: 700, height: 500)
}
