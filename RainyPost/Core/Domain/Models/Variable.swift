//
//  Variable.swift
//  RainyPost
//
//  Created by Fer on 1/4/26.
//

import Foundation

struct Variable: Identifiable, Codable {
    let id: UUID
    var key: String
    var value: String
    var isSecret: Bool = false
    var secretRef: SecretRef?
    var isEnabled: Bool = true
    
    init(key: String, value: String, isSecret: Bool = false, secretRef: SecretRef? = nil, isEnabled: Bool = true) {
        self.id = UUID()
        self.key = key
        self.value = value
        self.isSecret = isSecret
        self.secretRef = secretRef
        self.isEnabled = isEnabled
    }
}