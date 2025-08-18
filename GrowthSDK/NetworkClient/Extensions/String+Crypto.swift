//
//  String+Crypto.swift
//  GrowthSDK
//
//  Created by arvin on 2025/7/21.
//

import Foundation

// MARK: -
internal extension String {
    
    func rsaEncrypt(publicKey: String) throws -> String {
        try CryptoProvider.rsaEncrypt(string: self, publicKey: publicKey)
    }
    
    func rsaDecrypt(privateKey: String) throws -> String {
        try CryptoProvider.rsaDecrypt(string: self, privateKey: privateKey)
    }
    
}

// MARK: -
internal extension String {
    
    func aesEncrypt(key: String, iv: String) throws -> String {
        try CryptoProvider.aesEncrypt(string: self, key: key, iv: iv)
    }
    
    func aesDecrypt(key: String, iv: String) throws -> String {
        try CryptoProvider.aesDecrypt(string: self, key: key, iv: iv)
    }
    
}

// MARK: -
internal extension String {
    
    func md5String() -> String {
        CryptoProvider.md5(string: self)
    }
    
}

// MARK: -
internal extension String {
    
    static func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in letters.randomElement()! })
    }
    
    func clearEndZeroString() -> String {
        var string = trimmingCharacters(in: .whitespacesAndNewlines)
        guard string.hasSuffix("\0") else { return string }
        string = replacingOccurrences(of: "\0", with: "")
        return string
    }
    
    func toDictionary() -> [String: Any]? {
        guard let data = self.data(using: .utf8) else { return nil }
        do {
            let obj = try JSONSerialization.jsonObject(with: data, options: [])
            return obj as? [String: Any]
        } catch {
            return nil
        }
    }
    
}

// MARK: -
internal extension String {
    
    var isNullOrEmpty: Bool {
        return self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var isValid: Bool {
        return !self.isNullOrEmpty
    }
    
}

// MARK: -
internal extension Optional where Wrapped == String {
    
    var isNullOrEmpty: Bool {
        guard let string = self else { return true }
        return string.isNullOrEmpty
    }
    
    var isValid: Bool {
        guard let string = self else { return false }
        return string.isValid
    }
    
    // MARK: -
    func orDefault(_ defaultValue: String) -> String {
        return self ?? defaultValue
    }
    
    func orEmpty() -> String {
        return self ?? ""
    }
    
}
