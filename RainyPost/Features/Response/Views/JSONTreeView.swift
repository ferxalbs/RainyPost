//
//  JSONTreeView.swift
//  RainyPost
//
//  Created by Fer on 1/4/26.
//

import SwiftUI

struct JSONTreeView: View {
    let data: Data
    @State private var rootNode: JSONNode?
    
    var body: some View {
        ScrollView {
            if let node = rootNode {
                JSONNodeView(node: node, depth: 0)
                    .padding(12)
            } else {
                Text("Unable to parse JSON")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .onAppear {
            parseJSON()
        }
    }
    
    private func parseJSON() {
        guard let json = try? JSONSerialization.jsonObject(with: data) else {
            return
        }
        rootNode = JSONNode(key: nil, value: json)
    }
}

struct JSONNodeView: View {
    let node: JSONNode
    let depth: Int
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                // Expand/Collapse button for containers
                if node.isContainer {
                    Button(action: { isExpanded.toggle() }) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(.secondary.opacity(0.5))
                            .frame(width: 12)
                    }
                    .buttonStyle(.plain)
                } else {
                    Spacer().frame(width: 12)
                }
                
                // Key
                if let key = node.key {
                    Text("\"\(key)\"")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.purple)
                    
                    Text(":")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
                // Value or container indicator
                if node.isContainer {
                    Text(node.containerPrefix)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.secondary)
                    
                    if !isExpanded {
                        Text("...")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary.opacity(0.5))
                        
                        Text(node.containerSuffix)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                } else {
                    valueView
                }
            }
            
            // Children
            if isExpanded && node.isContainer {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(node.children.indices, id: \.self) { index in
                        HStack(spacing: 0) {
                            Spacer().frame(width: 16)
                            JSONNodeView(node: node.children[index], depth: depth + 1)
                        }
                    }
                }
                
                HStack(spacing: 4) {
                    Spacer().frame(width: 12)
                    Text(node.containerSuffix)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    @ViewBuilder
    private var valueView: some View {
        switch node.valueType {
        case .string(let value):
            Text("\"\(value)\"")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.green)
                .textSelection(.enabled)
        case .number(let value):
            Text(value)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.blue)
        case .bool(let value):
            Text(value ? "true" : "false")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.orange)
        case .null:
            Text("null")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.red.opacity(0.7))
        case .array, .object:
            EmptyView()
        }
    }
}

// MARK: - JSON Node Model

class JSONNode: Identifiable {
    let id = UUID()
    let key: String?
    let valueType: JSONValueType
    var children: [JSONNode] = []
    
    var isContainer: Bool {
        switch valueType {
        case .array, .object: return true
        default: return false
        }
    }
    
    var containerPrefix: String {
        switch valueType {
        case .array: return "["
        case .object: return "{"
        default: return ""
        }
    }
    
    var containerSuffix: String {
        switch valueType {
        case .array: return "]"
        case .object: return "}"
        default: return ""
        }
    }
    
    init(key: String?, value: Any) {
        self.key = key
        
        if let dict = value as? [String: Any] {
            self.valueType = .object
            self.children = dict.sorted { $0.key < $1.key }.map { JSONNode(key: $0.key, value: $0.value) }
        } else if let array = value as? [Any] {
            self.valueType = .array
            self.children = array.enumerated().map { JSONNode(key: "[\($0.offset)]", value: $0.element) }
        } else if let string = value as? String {
            self.valueType = .string(string)
        } else if let number = value as? NSNumber {
            if CFBooleanGetTypeID() == CFGetTypeID(number) {
                self.valueType = .bool(number.boolValue)
            } else {
                self.valueType = .number(number.stringValue)
            }
        } else if value is NSNull {
            self.valueType = .null
        } else {
            self.valueType = .string(String(describing: value))
        }
    }
}

enum JSONValueType {
    case string(String)
    case number(String)
    case bool(Bool)
    case null
    case array
    case object
}

#Preview {
    let json = """
    {
        "name": "John Doe",
        "age": 30,
        "active": true,
        "email": null,
        "tags": ["developer", "swift"],
        "address": {
            "city": "New York",
            "zip": "10001"
        }
    }
    """.data(using: .utf8)!
    
    return JSONTreeView(data: json)
        .frame(width: 400, height: 400)
}
