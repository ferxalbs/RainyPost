//
//  KeychainService.swift
//  RainyPost
//
//  Created by Fer on 1/4/26.
//

import Foundation
import Security

class KeychainService {
    static let shared = KeychainService()
    
    private init() {}
    
    enum KeychainError: Error {
        case itemNotFound
        case duplicateItem
        case invalidData
        case unexpectedStatus(OSStatus)
    }
    
    func store(secret: String, for secretRef: SecretRef) throws {
        let data = secret.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: secretRef.service,
            kSecAttrAccount as String: secretRef.account,
            kSecValueData as String: data
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    func retrieve(for secretRef: SecretRef) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: secretRef.service,
            kSecAttrAccount as String: secretRef.account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unexpectedStatus(status)
        }
        
        guard let data = result as? Data,
              let secret = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        
        return secret
    }
    
    func delete(for secretRef: SecretRef) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: secretRef.service,
            kSecAttrAccount as String: secretRef.account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    func exists(for secretRef: SecretRef) -> Bool {
        do {
            _ = try retrieve(for: secretRef)
            return true
        } catch {
            return false
        }
    }
}