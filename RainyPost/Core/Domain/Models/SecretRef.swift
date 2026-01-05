//
//  SecretRef.swift
//  RainyPost
//
//  Created by Fer on 1/4/26.
//

import Foundation

struct SecretRef: Codable, Hashable {
    let keychainId: String // UUID stored in file
    let service: String = "com.rainypost.secrets"
    var account: String { keychainId }
    
    init() {
        self.keychainId = UUID().uuidString
    }
    
    init(keychainId: String) {
        self.keychainId = keychainId
    }
}