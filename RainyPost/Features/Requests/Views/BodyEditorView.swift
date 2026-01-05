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
        VStack(alignment: .leading, spacing: 18) {
            // Body Type Picker
            VStack(alignment: .leading, spacing: 10) {
                Text("Body Type")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Picker("", selection: $viewModel.bodyType) {
                    ForEach(BodyType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 420)
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
        VStack(spacing: 12) {
            Image(systemName: "doc")
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.3))
            
            Text("No request body")
                .font(.system(size: 14))
                .foregroundColor(.secondary.opacity(0.5))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var rawBodyView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Content Type Picker
            HStack {
                Text("Content Type")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Picker("", selection: $viewModel.rawContentType) {
                    ForEach(RawContentType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 120)
                
                Spacer()
                
                Button(action: formatJSON) {
                    HStack(spacing: 6) {
                        Image(systemName: "text.alignleft")
                            .font(.system(size: 12))
                        Text("Format")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
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
        VStack(spacing: 12) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.3))
            
            Text("Multipart form data")
                .font(.system(size: 14))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("Coming soon")
                .font(.system(size: 12))
                .foregroundColor(.secondary.opacity(0.3))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            .font(.system(size: 13, design: .monospaced))
            .scrollContentBackground(.hidden)
            .padding(12)
            .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(.white.opacity(0.1), lineWidth: 1)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    BodyEditorView(viewModel: RequestViewModel(request: Request(name: "Test", method: .POST, url: "")))
        .padding()
        .frame(width: 600, height: 500)
}
