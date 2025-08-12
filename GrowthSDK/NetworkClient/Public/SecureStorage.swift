//
//  SecureStorage.swift
//  GrowthSDK
//
//  Created by arvin on 2025/7/20.
//

import Foundation
import Security

// MARK: -
internal struct SecureStorage {
    
    public enum StorageError: Error, LocalizedError {
        case unexpectedStatus(OSStatus)
        case invalidItemFormat
        case duplicateItem
        case itemNotFound
        case invalidData
        case encodingFailed
        case decodingFailed
        
        public var errorDescription: String? {
            switch self {
            case .unexpectedStatus(let status):
                return "Keychain operation failed with status: \(status)"
            case .invalidItemFormat:
                return "Invalid item format in keychain"
            case .duplicateItem:
                return "Item already exists in keychain"
            case .itemNotFound:
                return "Item not found in keychain"
            case .invalidData:
                return "Invalid data format"
            case .encodingFailed:
                return "Failed to encode data"
            case .decodingFailed:
                return "Failed to decode data"
            }
        }
    }
    
    // MARK: -
    private let service: String
    public init(service: String) {
        self.service = service
    }
    
}

// MARK: -
private extension SecureStorage {
    
    func save(value: Data, account: String) throws {
        let query: [String: AnyObject] = [
            kSecAttrService as String: service as AnyObject,
            kSecAttrAccount as String: account as AnyObject,
            kSecClass as String: kSecClassGenericPassword,
            kSecValueData as String: value as AnyObject
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            throw StorageError.duplicateItem
        }
        
        guard status == errSecSuccess else {
            throw StorageError.unexpectedStatus(status)
        }
    }
    
    func update(value: Data, account: String) throws {
        let query: [String: AnyObject] = [
            kSecAttrService as String: service as AnyObject,
            kSecAttrAccount as String: account as AnyObject,
            kSecClass as String: kSecClassGenericPassword
        ]
        
        let attributes: [String: AnyObject] = [
            kSecValueData as String: value as AnyObject
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        
        guard status != errSecItemNotFound else {
            throw StorageError.itemNotFound
        }
        
        guard status == errSecSuccess else {
            throw StorageError.unexpectedStatus(status)
        }
    }
    
    func setData(_ value: Data, forKey key: String) throws {
        do {
            try save(value: value, account: key)
            
        } catch StorageError.duplicateItem {
            try update(value: value, account: key)
        }
    }
    
    func removeValue(for account: String) throws {
        let query: [String: AnyObject] = [
            kSecAttrService as String: service as AnyObject,
            kSecAttrAccount as String: account as AnyObject,
            kSecClass as String: kSecClassGenericPassword
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess else {
            throw StorageError.unexpectedStatus(status)
        }
    }
    
    func readValue(for account: String) throws -> Data {
        let query: [String: AnyObject] = [
            kSecAttrService as String: service as AnyObject,
            kSecAttrAccount as String: account as AnyObject,
            kSecClass as String: kSecClassGenericPassword,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: kCFBooleanTrue
        ]
        
        var itemCopy: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &itemCopy)
        
        guard status != errSecItemNotFound else {
            throw StorageError.itemNotFound
        }
        
        guard status == errSecSuccess else {
            throw StorageError.unexpectedStatus(status)
        }
        
        guard let value = itemCopy as? Data else {
            throw StorageError.invalidItemFormat
        }
        
        return value
    }
    
}

// MARK: -
internal extension SecureStorage {
    
    func setValue<T: Codable>(_ value: T?, forKey key: String) throws {
        guard let value = value else {
            try? remove(forKey: key)
            return
        }
        
        let data: Data
        switch value {
        case let stringValue as String:
            guard let stringData = stringValue.data(using: .utf8) else {
                throw StorageError.encodingFailed
            }
            data = stringData
        case let dataValue as Data:
            data = dataValue
        default:
            do {
                data = try JSONEncoder().encode(value)
            } catch {
                throw StorageError.encodingFailed
            }
        }
        
        try setData(data, forKey: key)
    }
    
    func getValue<T: Codable>(_ type: T.Type, forKey key: String) throws -> T? {
        do {
            let data = try readValue(for: key)
            switch type {
            case is String.Type:
                guard let string = String(data: data, encoding: .utf8) else {
                    throw StorageError.decodingFailed
                }
                return string as? T
            case is Data.Type:
                return data as? T
            default:
                do {
                    return try JSONDecoder().decode(type, from: data)
                } catch {
                    throw StorageError.decodingFailed
                }
            }
        } catch StorageError.itemNotFound {
            return nil
        }
    }
    
    // MARK: -
    func setString(_ value: String?, forKey key: String) {
        try? setValue(value, forKey: key)
    }
    
    func string(forKey key: String) -> String? {
        return try? getValue(String.self, forKey: key)
    }
    
    func remove(forKey key: String) throws {
        try removeValue(for: key)
    }
    
}
