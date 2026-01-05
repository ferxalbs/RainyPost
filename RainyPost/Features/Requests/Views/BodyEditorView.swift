//
//  BodyEditorView.swift
//  RainyPost
//
//  Created by Fer on 1/4/26.
//

import SwiftUI

struct BodyEditorView: View {
    @ObservedObject var viewModel: RequestViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Body Type Picker
            VStack(alignment: .leading, spacing: 6) {
                Text("Body Type")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Picker("", selection: $viewModel.bodyType) {
                    ForEach(BodyType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 350)
            }
            
            // Body Content based on type
            switch viewModel.bodyType {
            case .none:
                noBodyView
            case .raw:
                rawBodyView
            case .formUrlEncoded:
                formBodyView
            case .multipart:
                multipartBodyView
            }
        }
    }
    
    private var noBodyView: some View {
        VStack(spacing: 10) {
            Image(systemName: "doc")
                .font(.system(size: 28))
                .foregroundColor(.secondary.opacity(0.4))
            
            Text("No request body")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
    }
    
    private var rawBodyView: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Content Type Picker
            HStack {
                Text("Content Type")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Picker("", selection: $viewModel.rawContentType) {
                    ForEach(RawContentType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 120)
                
                Spacer()
                
                Button("Format JSON") {
                    formatJSON()
                }
                .font(.system(size: 11))
                .disabled(viewModel.rawContentType != .json)
            }
            
            // Code Editor
            CodeEditor(text: $viewModel.rawBody, language: viewModel.rawContentType)
        }
    }
    
    private var formBodyView: some View {
        KeyValueEditor(
            title: "Form Parameters",
            items: $viewModel.formParams,
            keyPlaceholder: "Key",
            valuePlaceholder: "Value"
        )
    }
    
    private var multipartBodyView: some View {
        VStack(spacing: 10) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 28))
                .foregroundColor(.secondary.opacity(0.4))
            
            Text("Multipart form data")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            Text("Coming soon")
                .font(.system(size: 10))
                .foregroundColor(.secondary.opacity(0.6))
        }
        .frame(maxWidth: .infinity, minHeight: 100)
    }
    
    private func formatJSON() {
        guard let data = viewModel.rawBody.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let prettyData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
              let prettyString = String(data: prettyData, encoding: .utf8) else {
            return
        }
        viewModel.rawBody = prettyString
    }
}

struct CodeEditor: View {
    @Binding var text: String
    let language: RawContentType
    
    var body: some View {
        TextEditor(text: $text)
            .font(.system(size: 12, design: .monospaced))
            .padding(8)
            .background(Color(nsColor: .textBackgroundColor))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
            )
            .frame(minHeight: 120)
    }
}

#Preview {
    BodyEditorView(viewModel: RequestViewModel(request: Request(name: "Test", method: .POST, url: "")))
        .padding()
        .frame(width: 600, height: 400)
}
