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
                Button(action: { items.append(KeyValueItem()) }) {
                    Label("Add", systemImage: "plus")
                        .font(.system(size: 10))
                }
                .buttonStyle(.plain)
                .foregroundColor(.blue)
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
                        
                        Button(action: { items.removeAll { $0.id == item.id } }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
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
