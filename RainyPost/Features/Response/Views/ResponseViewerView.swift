//
//  ResponseViewerView.swift
//  RainyPost
//
//  Created by Fer on 1/4/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct ResponseViewerView: View {
    @ObservedObject var viewModel: RequestViewModel
    @State private var selectedTab: ResponseTab = .body
    
    enum ResponseTab: String, CaseIterable {
        case body = "Body"
        case headers = "Headers"
        case cookies = "Cookies"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Response Header
            responseHeader
            
            Divider().opacity(0.2)
            
            // Response Content
            if let response = viewModel.response {
                responseContent(response)
            } else if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.error {
                errorView(error)
            } else {
                emptyView
            }
        }
        .background(VisualEffectView(material: .contentBackground, blendingMode: .behindWindow))
    }
    
    private var responseHeader: some View {
        HStack(spacing: 16) {
            Text("Response")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
            
            if let response = viewModel.response {
                // Status Badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor(response.statusCode))
                        .frame(width: 8, height: 8)
                    
                    Text("\(response.statusCode)")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(statusColor(response.statusCode))
                    
                    Text(response.statusText)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(statusColor(response.statusCode).opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                
                // Timing
                HStack(spacing: 5) {
                    Image(systemName: "clock")
                        .font(.system(size: 11))
                    Text(response.formattedDuration)
                        .font(.system(size: 12, design: .monospaced))
                }
                .foregroundColor(.secondary)
                
                // Size
                HStack(spacing: 5) {
                    Image(systemName: "doc")
                        .font(.system(size: 11))
                    Text(response.formattedSize)
                        .font(.system(size: 12, design: .monospaced))
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if viewModel.response != nil {
                // Tab Picker
                Picker("", selection: $selectedTab) {
                    ForEach(ResponseTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 240)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }
    
    @ViewBuilder
    private func responseContent(_ response: HTTPResponse) -> some View {
        switch selectedTab {
        case .body:
            ResponseBodyView(response: response)
        case .headers:
            ResponseHeadersView(headers: response.headers)
        case .cookies:
            ResponseCookiesView(headers: response.headers)
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.0)
            
            Text("Sending request...")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36))
                .foregroundColor(.red.opacity(0.7))
            
            Text("Request Failed")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
            
            Text(error)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.up.circle")
                .font(.system(size: 36))
                .foregroundColor(.secondary.opacity(0.3))
            
            Text("Send a request to see the response")
                .font(.system(size: 14))
                .foregroundColor(.secondary.opacity(0.5))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func statusColor(_ code: Int) -> Color {
        switch code {
        case 200..<300: return .green
        case 300..<400: return .blue
        case 400..<500: return .orange
        case 500..<600: return .red
        default: return .secondary
        }
    }
}

// MARK: - Response Body View

struct ResponseBodyView: View {
    let response: HTTPResponse
    @State private var viewMode: BodyViewMode = .pretty
    
    enum BodyViewMode: String, CaseIterable {
        case pretty = "Pretty"
        case tree = "Tree"
        case raw = "Raw"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // View Mode Toggle
            HStack {
                Picker("", selection: $viewMode) {
                    ForEach(BodyViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
                
                Spacer()
                
                Button(action: copyToClipboard) {
                    HStack(spacing: 5) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 11))
                        Text("Copy")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                
                Button(action: saveToFile) {
                    HStack(spacing: 5) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 11))
                        Text("Save")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            
            Divider().opacity(0.15)
            
            // Body Content
            switch viewMode {
            case .pretty:
                ScrollView {
                    Text(response.prettyJSON ?? response.bodyString ?? "Unable to decode")
                        .font(.system(size: 12, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                }
            case .tree:
                if response.prettyJSON != nil {
                    JSONTreeView(data: response.body)
                } else {
                    ScrollView {
                        Text(response.bodyString ?? "Unable to decode")
                            .font(.system(size: 12, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                    }
                }
            case .raw:
                ScrollView {
                    Text(response.bodyString ?? "Unable to decode")
                        .font(.system(size: 12, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                }
            }
        }
    }
    
    private func copyToClipboard() {
        let text = viewMode == .raw ? (response.bodyString ?? "") : (response.prettyJSON ?? response.bodyString ?? "")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
    
    private func saveToFile() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json, .plainText]
        panel.nameFieldStringValue = "response.json"
        
        if panel.runModal() == .OK, let url = panel.url {
            try? response.body.write(to: url)
        }
    }
}

// MARK: - Response Headers View

struct ResponseHeadersView: View {
    let headers: [ResponseHeader]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(headers) { header in
                    HStack(alignment: .top) {
                        Text(header.key)
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(.blue)
                            .frame(width: 200, alignment: .leading)
                        
                        Text(header.value)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.primary)
                            .textSelection(.enabled)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    
                    Divider().opacity(0.1)
                }
            }
            .padding(.vertical, 10)
        }
    }
}

// MARK: - Response Cookies View

struct ResponseCookiesView: View {
    let headers: [ResponseHeader]
    
    var cookies: [String] {
        headers
            .filter { $0.key.lowercased() == "set-cookie" }
            .map { $0.value }
    }
    
    var body: some View {
        if cookies.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "tray")
                    .font(.system(size: 32))
                    .foregroundColor(.secondary.opacity(0.3))
                
                Text("No cookies in response")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(cookies, id: \.self) { cookie in
                        Text(cookie)
                            .font(.system(size: 13, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(12)
                            .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 6))
                    }
                }
                .padding(18)
            }
        }
    }
}

#Preview {
    ResponseViewerView(viewModel: RequestViewModel(request: Request(name: "Test", method: .GET, url: "")))
        .frame(width: 700, height: 400)
}
