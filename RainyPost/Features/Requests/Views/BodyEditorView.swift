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
        VStack(alignment: .leading, spacing: 12) {
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
                .frame(maxWidth: 400)
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
        VStack(spacing: 8) {
            Image(systemName: "doc")
                .font(.system(size: 24))
                .foregroundColor(.secondary.opacity(0.4))
            
            Text("No request body")
                .font(.system(size: 12))
                .foregroundColor(.secondary.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var rawBodyView: some View {
        VStack(alignment: .leading, spacing: 8) {
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
                .frame(width: 100)
                
                Spacer()
                
                Button(action: formatJSON) {
                    HStack(spacing: 4) {
                        Image(systemName: "text.alignleft")
                            .font(.system(size: 10))
                        Text("Format")
                            .font(.system(size: 10, weight: .medium))
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
        VStack(spacing: 8) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 24))
                .foregroundColor(.secondary.opacity(0.4))
            
            Text("Multipart form data")
                .font(.system(size: 12))
                .foregroundColor(.secondary.opacity(0.6))
            
            Text("Coming soon")
                .font(.system(size: 10))
                .foregroundColor(.secondary.opacity(0.4))
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
            .font(.system(size: 12, design: .monospaced))
            .scrollContentBackground(.hidden)
            .padding(8)
            .background(.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(.white.opacity(0.1), lineWidth: 1)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    BodyEditorView(viewModel: RequestViewModel(request: Request(name: "Test", method: .POST, url: "")))
        .padding()
        .frame(width: 500, height: 400)
}
