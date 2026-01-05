//
//  RequestDetailView.swift
//  RainyPost
//
//  Created by Fer on 1/4/26.
//

import SwiftUI

struct RequestDetailView: View {
    let request: Request
    @State private var selectedTab: RequestTab = .params
    
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
    
    var body: some View {
        VStack(spacing: 0) {
            // Request Header
            requestHeaderView
            
            Divider()
            
            // Request Builder Tabs
            requestBuilderView
            
            Divider()
            
            // Response Area (placeholder)
            responseAreaView
        }
        .background(VisualEffectView(material: .windowBackground, blendingMode: .behindWindow))
    }
    
    private var requestHeaderView: some View {
        HStack(spacing: 12) {
            // Method Picker
            Menu {
                ForEach(HTTPMethod.allCases, id: \.self) { method in
                    Button(method.rawValue) {
                        // TODO: Update request method
                    }
                }
            } label: {
                Text(request.method.rawValue)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(methodColor, in: RoundedRectangle(cornerRadius: 6))
            }
            .menuStyle(.borderlessButton)
            
            // URL Input
            TextField("Enter URL", text: .constant(request.url))
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 13).monospaced())
            
            // Send Button
            Button("Send") {
                // TODO: Execute request
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.return, modifiers: .command)
        }
        .padding(16)
    }
    
    private var requestBuilderView: some View {
        VStack(spacing: 0) {
            // Tab Bar
            tabBarView
            
            Divider()
            
            // Tab Content
            tabContentView
        }
        .frame(height: 300)
    }
    
    private var tabBarView: some View {
        HStack(spacing: 0) {
            ForEach(RequestTab.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    private func tabButton(for tab: RequestTab) -> some View {
        Button(action: {
            selectedTab = tab
        }) {
            HStack(spacing: 6) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 11))
                
                Text(tab.rawValue)
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(selectedTab == tab ? AnyShapeStyle(.quaternary) : AnyShapeStyle(.clear))
            )
            .foregroundColor(selectedTab == tab ? .primary : .secondary)
        }
        .buttonStyle(.plain)
    }
    
    private var tabContentView: some View {
        Group {
            switch selectedTab {
            case .params:
                ParamsTabView(queryParams: request.queryParams)
            case .headers:
                HeadersTabView(headers: request.headers)
            case .auth:
                AuthTabView(auth: request.auth)
            case .body:
                BodyTabView(requestBody: request.body)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(16)
    }
    
    private var responseAreaView: some View {
        VStack {
            HStack {
                Text("Response")
                    .font(.headline)
                
                Spacer()
                
                Text("Ready to send request")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            Spacer()
            
            Text("Response will appear here")
                .foregroundColor(.secondary)
                .font(.system(size: 14))
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

// MARK: - Tab Views

struct ParamsTabView: View {
    let queryParams: [QueryParam]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Query Parameters")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
            
            if queryParams.isEmpty {
                Text("No parameters")
                    .foregroundColor(.secondary)
                    .font(.system(size: 13))
            } else {
                // TODO: Parameter editor
                ForEach(queryParams) { param in
                    HStack {
                        Text(param.key)
                        Text("=")
                        Text(param.value)
                    }
                    .font(.system(size: 13).monospaced())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

struct HeadersTabView: View {
    let headers: [Header]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Headers")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
            
            if headers.isEmpty {
                Text("No headers")
                    .foregroundColor(.secondary)
                    .font(.system(size: 13))
            } else {
                // TODO: Header editor
                ForEach(headers) { header in
                    HStack {
                        Text(header.key)
                        Text(":")
                        Text(header.value)
                    }
                    .font(.system(size: 13).monospaced())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

struct AuthTabView: View {
    let auth: AuthConfig?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Authentication")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
            
            if auth == nil {
                Text("No authentication")
                    .foregroundColor(.secondary)
                    .font(.system(size: 13))
            } else {
                Text("Authentication configured")
                    .font(.system(size: 13))
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

struct BodyTabView: View {
    let requestBody: RequestBody?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Request Body")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
            
            if requestBody == nil {
                Text("No body")
                    .foregroundColor(.secondary)
                    .font(.system(size: 13))
            } else {
                Text("Body configured")
                    .font(.system(size: 13))
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

#Preview {
    RequestDetailView(request: Request(name: "Test Request", method: .GET, url: "https://api.example.com/users"))
        .frame(width: 800, height: 600)
}