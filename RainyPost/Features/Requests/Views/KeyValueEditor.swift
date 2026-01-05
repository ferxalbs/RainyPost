//
//  KeyValueEditor.swift
//  RainyPost
//
//  Created by Fer on 1/4/26.
//

import SwiftUI

struct KeyValueEditor: View {
    let title: String
    @Binding var items: [KeyValueItem]
    let keyPlaceholder: String
    let valuePlaceholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Button("Add", systemImage: "plus.circle") {
                    items.append(KeyValueItem())
                }
                .buttonStyle(.borderless)
                .controlSize(.small)
            }
            
            if items.isEmpty {
                Text("No \(title.lowercased())")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ForEach($items) { $item in
                    HStack(spacing: 6) {
                        Toggle("", isOn: $item.isEnabled)
                            .labelsHidden()
                            .scaleEffect(0.8)
                        
                        TextField(keyPlaceholder, text: $item.key)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 11, design: .monospaced))
                            .frame(maxWidth: 150)
                        
                        Text("=")
                            .foregroundColor(.secondary)
                        
                        TextField(valuePlaceholder, text: $item.value)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 11, design: .monospaced))
                        
                        Button(role: .destructive) {
                            items.removeAll { $0.id == item.id }
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                        .controlSize(.small)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    KeyValueEditor(
        title: "Query Parameters",
        items: .constant([KeyValueItem(key: "page", value: "1")]),
        keyPlaceholder: "Key",
        valuePlaceholder: "Value"
    )
    .padding()
    .frame(width: 500)
}
