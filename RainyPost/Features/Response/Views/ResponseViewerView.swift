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
            responseHeader
            Divider()
            
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
    }
    
    private var responseHeader: some View {
        HStack(spacing: 12) {
            Text("Response")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
            
            if let response = viewModel.response {
                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor(response.statusCode))
                        .frame(width: 6, height: 6)
                    
                    Text("\(response.statusCode)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(statusColor(response.statusCode))
                    
                    Text(response.statusText)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(statusColor(response.statusCode).opacity(0.1))
                .cornerRadius(4)
                
                HStack(spacing: 3) {
                    Image(systemName: "clock")
                        .font(.system(size: 9))
                    Text(response.formattedDuration)
                        .font(.system(size: 10, design: .monospaced))
                }
                .foregroundColor(.secondary)
                
                HStack(spacing: 3) {
                    Image(systemName: "doc")
                        .font(.system(size: 9))
                    Text(response.formattedSize)
                        .font(.system(size: 10, design: .monospaced))
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if viewModel.response != nil {
                Picker("", selection: $selectedTab) {
                    ForEach(ResponseTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
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
        VStack(spacing: 12) {
            ProgressView()
            Text("Sending request...")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28))
                .foregroundColor(.red.opacity(0.7))
            
            Text("Request Failed")
                .font(.system(size: 13, weight: .medium))
            
            Text(error)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyView: some View {
        VStack(spacing: 10) {
            Image(systemName: "arrow.up.circle")
                .font(.system(size: 28))
                .foregroundColor(.secondary.opacity(0.4))
            
            Text("Send a request to see the response")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
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
            HStack {
                Picker("", selection: $viewMode) {
                    ForEach(BodyViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
                
                Spacer()
                
                Button("Copy") { copyToClipboard() }
                    .font(.system(size: 10))
                
                Button("Save") { saveToFile() }
                    .font(.system(size: 10))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            
            Divider()
            
            switch viewMode {
            case .pretty:
                ScrollView {
                    Text(response.prettyJSON ?? response.bodyString ?? "Unable to decode")
                        .font(.system(size: 11, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                }
                .scrollContentBackground(.hidden)
            case .tree:
                if response.prettyJSON != nil {
                    JSONTreeView(data: response.body)
                } else {
                    ScrollView {
                        Text(response.bodyString ?? "Unable to decode")
                            .font(.system(size: 11, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                    }
                    .scrollContentBackground(.hidden)
                }
            case .raw:
                ScrollView {
                    Text(response.bodyString ?? "Unable to decode")
                        .font(.system(size: 11, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                }
                .scrollContentBackground(.hidden)
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
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.blue)
                            .frame(width: 180, alignment: .leading)
                        
                        Text(header.value)
                            .font(.system(size: 11, design: .monospaced))
                            .textSelection(.enabled)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    
                    Divider()
                }
            }
            .padding(.vertical, 6)
        }
        .scrollContentBackground(.hidden)
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
            VStack(spacing: 10) {
                Image(systemName: "tray")
                    .font(.system(size: 28))
                    .foregroundColor(.secondary.opacity(0.4))
                
                Text("No cookies in response")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(cookies, id: \.self) { cookie in
                        Text(cookie)
                            .font(.system(size: 11, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(8)
                            .background(Color(nsColor: .textBackgroundColor))
                            .cornerRadius(4)
                    }
                }
                .padding(12)
            }
            .scrollContentBackground(.hidden)
        }
    }
}

#Preview {
    ResponseViewerView(viewModel: RequestViewModel(request: Request(name: "Test", method: .GET, url: "")))
        .frame(width: 700, height: 400)
}
