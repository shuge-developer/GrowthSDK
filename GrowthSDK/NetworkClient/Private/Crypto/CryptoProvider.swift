//
//  CryptoProvider.swift
//  GrowthSDK
//
//  Created by arvin on 2025/7/21.
//

import Foundation

#if canImport(CryptoSwift)
internal import CryptoSwift

// MARK: -
private extension String {
    
    enum SecAttrKeyClass {
        case `private`
        case `public`
        
        var rawValue: CFString {
            switch self {
            case .private:
                return kSecAttrKeyClassPrivate
            case .public:
                return kSecAttrKeyClassPublic
            }
        }
    }
    
    static func createSecKey(_ key: String, keyClass: SecAttrKeyClass) throws -> SecKey {
        let options = Data.Base64DecodingOptions(rawValue: 0)
        let keyString = String(key.filter { !" \n\t\r".contains($0) })
        guard let data = Data(base64Encoded: keyString, options: options) else {
            throw NetworkError.createSecKeyError("Invalid base64 string")
        }
        do {
            let keyData = try data.stripKeyHeader()
            let sizeInBits = keyData.count * 8
            let keyDict: [CFString: Any] = [
                kSecAttrKeySizeInBits: NSNumber(value: sizeInBits),
                kSecAttrKeyType: kSecAttrKeyTypeRSA,
                kSecAttrKeyClass: keyClass.rawValue,
                kSecReturnPersistentRef: true
            ]
            let cfData = keyData as CFData
            let cfDict = keyDict as CFDictionary
            var error: Unmanaged<CFError>?
            guard let secKey = SecKeyCreateWithData(cfData, cfDict, &error) else {
                throw NetworkError.createSecKeyFailed(error?.takeRetainedValue())
            }
            return secKey
        } catch {
            let errMsg = "Create secKey error: \(error.localizedDescription)"
            throw NetworkError.createSecKeyError(errMsg)
        }
    }
    
}

// MARK: -
internal class CryptoProvider {
    
    // MARK: -
    static func rsaEncrypt(string: String, publicKey: String) throws -> String {
        //        #if canImport(CryptoSwift)
        do {
            var error: Unmanaged<CFError>?
            let secKey = try String.createSecKey(publicKey, keyClass: .public)
            guard let cfdata = SecKeyCopyExternalRepresentation(secKey, &error) else {
                throw NetworkError.createSecKeyFailed(error?.takeRetainedValue())
            }
            
            let key = try RSA(rawRepresentation: cfdata as Data)
            return try string.encryptToBase64(cipher: key)
        } catch {
            let errMsg = "RSA encryption failed: \(error.localizedDescription)"
            throw NetworkError.encryptionError(errMsg)
        }
        //        #else
        //        throw NetworkError.encryptionError("CryptoSwift not available")
        //        #endif
    }
    
    static func rsaDecrypt(string: String, privateKey: String) throws -> String {
        //        #if canImport(CryptoSwift)
        do {
            var error: Unmanaged<CFError>?
            let secKey = try String.createSecKey(privateKey, keyClass: .private)
            guard let cfdata = SecKeyCopyExternalRepresentation(secKey, &error) else {
                throw NetworkError.createSecKeyFailed(error?.takeRetainedValue())
            }
            
            let key = try RSA(rawRepresentation: cfdata as Data)
            return try string.decryptBase64ToString(cipher: key)
        } catch {
            let errMsg = "RSA decryption failed: \(error.localizedDescription)"
            throw NetworkError.decryptionError(errMsg)
        }
        //        #else
        //        throw NetworkError.decryptionError("CryptoSwift not available")
        //        #endif
    }
    
    // MARK: -
    static func aesEncrypt(string: String, key: String, iv: String) throws -> String {
        //        #if canImport(CryptoSwift)
        guard let data = string.data(using: .utf8, allowLossyConversion: true) else {
            throw NetworkError.encryptionError("Failed to convert string to data")
        }
        do {
            let aes = try AES(key: key, iv: iv)
            let encrypted = try aes.encrypt(data.bytes)
            
            let encryptedData = Data(bytes: encrypted, count: encrypted.count)
            return encryptedData.base64EncodedString()
        } catch {
            let errMsg = "AES encryption failed: \(error.localizedDescription)"
            throw NetworkError.encryptionError(errMsg)
        }
        //        #else
        //        throw NetworkError.encryptionError("CryptoSwift not available")
        //        #endif
    }
    
    static func aesDecrypt(string: String, key: String, iv: String) throws -> String {
        //        #if canImport(CryptoSwift)
        let options = Data.Base64DecodingOptions(rawValue: 0)
        guard let data = Data(base64Encoded: string, options: options) else {
            throw NetworkError.decryptionError("Invalid base64 string")
        }
        do {
            let aes = try AES(key: key, iv: iv)
            let decrypted = try aes.decrypt(data.bytes)
            
            let decryptedData = Data(bytes: decrypted, count: decrypted.count)
            guard let decryptedString = String(data: decryptedData, encoding: .utf8) else {
                throw NetworkError.decryptionError("Failed to convert decrypted data to string")
            }
            return decryptedString
        } catch {
            let errMsg = "AES decryption failed: \(error.localizedDescription)"
            throw NetworkError.decryptionError(errMsg)
        }
        //        #else
        //        throw NetworkError.decryptionError("CryptoSwift not available")
        //        #endif
    }
    
    // MARK: -
    static func md5(string: String) -> String {
        //        #if canImport(CryptoSwift)
        guard let data = string.data(using: .utf8) else { return string }
        let strings = data.md5().map { String(format: "%02x", $0) }
        let hash = strings.joined()
        return hash
        //        #else
        //        // 简单的 MD5 实现，仅用于编译通过
        //        return string
        //        #endif
    }
    
}
#endif
