//
//  CryptoProvider.swift
//  GrowthSDK
//
//  Created by arvin on 2025/7/21.
//

import Foundation
import CommonCrypto
import CryptoKit
import Security

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
    
    enum CryptType {
        case encrypt, decrypt
        
        var rawValue: Int {
            switch self {
            case .encrypt:
                return kCCEncrypt
            case .decrypt:
                return kCCDecrypt
            }
        }
    }
    
    // MARK: - RSA
    static func rsaEncrypt(string: String, publicKey: String) throws -> String {
        let secKey = try String.createSecKey(publicKey, keyClass: .public)
        let algorithm: SecKeyAlgorithm = .rsaEncryptionPKCS1
        
        guard SecKeyIsAlgorithmSupported(secKey, .encrypt, algorithm) else {
            throw NetworkError.encryptionError("RSA algorithm not supported")
        }
        
        guard let stringData = string.data(using: .utf8) else {
            throw NetworkError.encryptionError("Failed to convert string to data")
        }
        
        var error: Unmanaged<CFError>?
        guard let encryptedData = SecKeyCreateEncryptedData(secKey, algorithm, stringData as CFData, &error) as Data? else {
            let errMsg = "RSA encryption failed: \(error?.takeRetainedValue().localizedDescription ?? "Unknown error")"
            throw NetworkError.encryptionError(errMsg)
        }
        return encryptedData.base64EncodedString()
    }
    
    static func rsaDecrypt(string: String, privateKey: String) throws -> String {
        let secKey = try String.createSecKey(privateKey, keyClass: .private)
        let algorithm: SecKeyAlgorithm = .rsaEncryptionPKCS1
        
        guard SecKeyIsAlgorithmSupported(secKey, .decrypt, algorithm) else {
            throw NetworkError.decryptionError("RSA algorithm not supported")
        }
        
        let options = Data.Base64DecodingOptions(rawValue: 0)
        guard let dataToDecrypt = Data(base64Encoded: string, options: options) else {
            throw NetworkError.decryptionError("Invalid base64 string")
        }
        
        var error: Unmanaged<CFError>?
        guard let decryptedData = SecKeyCreateDecryptedData(secKey, algorithm, dataToDecrypt as CFData, &error) as Data? else {
            let errMsg = "RSA decryption failed: \(error?.takeRetainedValue().localizedDescription ?? "Unknown error")"
            throw NetworkError.decryptionError(errMsg)
        }
        
        guard let decryptedString = String(data: decryptedData, encoding: .utf8) else {
            throw NetworkError.decryptionError("Failed to convert decrypted data to string")
        }
        return decryptedString
    }
    
    // MARK: - AES
    static func aesEncrypt(string: String, key: String, iv: String) throws -> String {
        guard let data = string.data(using: .utf8) else {
            throw NetworkError.encryptionError("Failed to convert string to data for AES")
        }
        let keyData = key.data(using: .utf8)!
        let ivData = iv.data(using: .utf8)!
        
        let encryptedData = try aesCrypt(data, key: keyData, iv: ivData, type: .encrypt)
        return encryptedData.base64EncodedString()
    }
    
    static func aesDecrypt(string: String, key: String, iv: String) throws -> String {
        let options = Data.Base64DecodingOptions(rawValue: 0)
        guard let data = Data(base64Encoded: string, options: options) else {
            throw NetworkError.decryptionError("Invalid base64 string for AES")
        }
        let keyData = key.data(using: .utf8)!
        let ivData = iv.data(using: .utf8)!
        
        let decryptedData = try aesCrypt(data, key: keyData, iv: ivData, type: .decrypt)
        guard let decryptedString = String(data: decryptedData, encoding: .utf8) else {
            throw NetworkError.decryptionError("Failed to convert decrypted AES data to string")
        }
        return decryptedString
    }
    
    // MARK: -
    private static func aesCrypt(_ data: Data, key: Data, iv: Data, type: CryptType) throws -> Data {
        let keyLength = kCCKeySizeAES128
        let ivLength = kCCBlockSizeAES128
        
        guard key.count == keyLength else {
            throw NetworkError.encryptionError("Invalid AES key length. Must be \(keyLength) bytes.")
        }
        guard iv.count == ivLength else {
            throw NetworkError.encryptionError("Invalid AES IV length. Must be \(ivLength) bytes.")
        }
        
        var outputBytes = [UInt8](repeating: 0, count: data.count + kCCBlockSizeAES128)
        var numBytesEncrypted: size_t = 0
        
        let status = data.withUnsafeBytes { dataBytes in
            key.withUnsafeBytes { keyBytes in
                iv.withUnsafeBytes { ivBytes in
                    CCCrypt(
                        CCOperation(type.rawValue),
                        CCAlgorithm(kCCAlgorithmAES),
                        CCOptions(kCCOptionPKCS7Padding),
                        keyBytes.baseAddress, keyLength,
                        ivBytes.baseAddress,
                        dataBytes.baseAddress, data.count,
                        &outputBytes, outputBytes.count,
                        &numBytesEncrypted
                    )
                }
            }
        }
        
        if status == kCCSuccess {
            return Data(bytes: outputBytes, count: numBytesEncrypted)
        } else {
            let errorType = type == .encrypt ? "Encryption" : "Decryption"
            throw NetworkError.encryptionError("AES \(errorType) failed with status \(status)")
        }
    }
    
    // MARK: - MD5
    static func md5(string: String) -> String {
        guard let data = string.data(using: .utf8) else { return string }
        let digest = Insecure.MD5.hash(data: data)
        return digest.map {
            String(format: "%02x", $0)
        }.joined()
    }
    
}
