//
//  VariableInterpolator.swift
//  RainyPost
//
//  Created by Fer on 1/4/26.
//

import Foundation

class VariableInterpolator {
    static let shared = VariableInterpolator()
    
    private let pattern = "\\{\\{([^}]+)\\}\\}"
    private let maxDepth = 10
    
    private init() {}
    
    /// Interpolates variables in a string using the provided variable scopes
    /// Scope priority: request > collection > environment > workspace (later overrides earlier)
    func interpolate(
        _ input: String,
        workspaceVariables: [String: String] = [:],
        environmentVariables: [String: String] = [:],
        collectionVariables: [String: String] = [:],
        requestVariables: [String: String] = [:]
    ) throws -> String {
        // Merge variables with proper scope priority
        var mergedVariables: [String: String] = [:]
        mergedVariables.merge(workspaceVariables) { _, new in new }
        mergedVariables.merge(environmentVariables) { _, new in new }
        mergedVariables.merge(collectionVariables) { _, new in new }
        mergedVariables.merge(requestVariables) { _, new in new }
        
        return try interpolateWithDepth(input, variables: mergedVariables, depth: 0, visited: [])
    }
    
    /// Interpolates variables from Variable array
    func interpolate(
        _ input: String,
        environment: APIEnvironment?,
        requestVariables: [Variable] = []
    ) throws -> String {
        var envVars: [String: String] = [:]
        if let env = environment {
            for variable in env.variables where variable.isEnabled {
                envVars[variable.key] = variable.value
            }
        }
        
        var reqVars: [String: String] = [:]
        for variable in requestVariables where variable.isEnabled {
            reqVars[variable.key] = variable.value
        }
        
        return try interpolate(
            input,
            environmentVariables: envVars,
            requestVariables: reqVars
        )
    }
    
    private func interpolateWithDepth(
        _ input: String,
        variables: [String: String],
        depth: Int,
        visited: Set<String>
    ) throws -> String {
        guard depth < maxDepth else {
            throw InterpolationError.maxDepthExceeded
        }
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return input
        }
        
        var result = input
        let range = NSRange(input.startIndex..., in: input)
        let matches = regex.matches(in: input, options: [], range: range)
        
        // Process matches in reverse order to maintain correct indices
        for match in matches.reversed() {
            guard let variableRange = Range(match.range(at: 1), in: input) else { continue }
            let variableName = String(input[variableRange]).trimmingCharacters(in: .whitespaces)
            
            // Check for circular reference
            if visited.contains(variableName) {
                throw InterpolationError.circularReference(variableName)
            }
            
            if let value = variables[variableName] {
                // Check if the value itself contains variables
                var newVisited = visited
                newVisited.insert(variableName)
                
                let interpolatedValue = try interpolateWithDepth(
                    value,
                    variables: variables,
                    depth: depth + 1,
                    visited: newVisited
                )
                
                guard let fullRange = Range(match.range, in: result) else { continue }
                result.replaceSubrange(fullRange, with: interpolatedValue)
            }
            // If variable not found, leave it as-is ({{variableName}})
        }
        
        return result
    }
    
    /// Extracts all variable names from a string
    func extractVariables(from input: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }
        
        let range = NSRange(input.startIndex..., in: input)
        let matches = regex.matches(in: input, options: [], range: range)
        
        return matches.compactMap { match -> String? in
            guard let variableRange = Range(match.range(at: 1), in: input) else { return nil }
            return String(input[variableRange]).trimmingCharacters(in: .whitespaces)
        }
    }
    
    /// Validates that all variables in the input can be resolved
    func validateVariables(
        in input: String,
        availableVariables: Set<String>
    ) -> [String] {
        let usedVariables = extractVariables(from: input)
        return usedVariables.filter { !availableVariables.contains($0) }
    }
}

// MARK: - Errors

enum InterpolationError: LocalizedError {
    case circularReference(String)
    case maxDepthExceeded
    case invalidVariable(String)
    
    var errorDescription: String? {
        switch self {
        case .circularReference(let variable):
            return "Circular reference detected for variable: \(variable)"
        case .maxDepthExceeded:
            return "Maximum variable nesting depth exceeded (limit: 10)"
        case .invalidVariable(let variable):
            return "Invalid variable: \(variable)"
        }
    }
}
