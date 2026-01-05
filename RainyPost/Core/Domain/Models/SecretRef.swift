//
//  SecretRef.swift
//  RainyPost
//
//  Created by Fer on 1/4/26.
//

import Foundation

struct SecretRef: Codable, Hashable {
    let keychainId: String
    var service: String
    var account: String { keychainId }
    
    init() {
        self.keychainId = UUID().uuidString
        self.service = "com.rainypost.secrets"
    }
    
    init(keychainId: String) {
        self.keychainId = keychainId
        self.service = "com.rainypost.secrets"
    }
}
