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
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: addItem) {
                    HStack(spacing: 5) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Add")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
            
            // Items List
            if items.isEmpty {
                emptyState
            } else {
                VStack(spacing: 8) {
                    ForEach($items) { $item in
                        KeyValueRow(
                            item: $item,
                            keyPlaceholder: keyPlaceholder,
                            valuePlaceholder: valuePlaceholder,
                            onDelete: { deleteItem(item) }
                        )
                    }
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 10) {
            Text("No \(title.lowercased())")
                .font(.system(size: 14))
                .foregroundColor(.secondary.opacity(0.5))
            
            Button(action: addItem) {
                Text("Add \(keyPlaceholder)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
    
    private func addItem() {
        items.append(KeyValueItem())
    }
    
    private func deleteItem(_ item: KeyValueItem) {
        items.removeAll { $0.id == item.id }
    }
}

struct KeyValueRow: View {
    @Binding var item: KeyValueItem
    let keyPlaceholder: String
    let valuePlaceholder: String
    let onDelete: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 10) {
            // Enable Toggle
            Button(action: { item.isEnabled.toggle() }) {
                Image(systemName: item.isEnabled ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundColor(item.isEnabled ? .blue : .secondary.opacity(0.3))
            }
            .buttonStyle(.plain)
            
            // Key Field
            TextField(keyPlaceholder, text: $item.key)
                .textFieldStyle(.plain)
                .font(.system(size: 14, design: .monospaced))
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
                .frame(maxWidth: 220)
            
            // Equals Sign
            Text("=")
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.secondary.opacity(0.4))
            
            // Value Field
            TextField(valuePlaceholder, text: $item.value)
                .textFieldStyle(.plain)
                .font(.system(size: 14, design: .monospaced))
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
            
            // Delete Button
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary.opacity(isHovered ? 0.8 : 0.3))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
        .onHover { hovering in isHovered = hovering }
    }
}

#Preview {
    KeyValueEditor(
        title: "Query Parameters",
        items: .constant([
            KeyValueItem(key: "page", value: "1"),
            KeyValueItem(key: "limit", value: "10")
        ]),
        keyPlaceholder: "Parameter",
        valuePlaceholder: "Value"
    )
    .padding()
    .frame(width: 600)
}
