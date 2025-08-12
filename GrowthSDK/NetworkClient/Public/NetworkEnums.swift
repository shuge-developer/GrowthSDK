//
//  NetworkEnums.swift
//  GrowthSDK
//
//  Created by arvin on 2025/8/12.
//

import Foundation

// MARK: -
internal enum CachePolicy {
    case reloadIgnoringCache
    case reloadFallingBackToCache
    case cacheOnly
    case useCache
}

// MARK: -
internal enum HTTPMethod {
    case get
    case post
    case put
    case connect
    case delete
    case patch
    case head
    
    public var rawValue: String {
        switch self {
        case .get: return "GET"
        case .post: return "POST"
        case .put: return "PUT"
        case .connect: return "CONNECT"
        case .delete: return "DELETE"
        case .patch: return "PATCH"
        case .head: return "HEAD"
        }
    }
}

// MARK: -
internal enum NetworkError: Error {
    case notInitialized
    case invalidURL
    case networkUnavailable
    case timeout
    case cancelled
    case requestFailed(Int, String?)
    case resposeError(Int, String?)
    case noData
    case decodeError
    case cacheError(String)
    case createSecKeyError(String)
    case createSecKeyFailed(CFError?)
    case encryptionError(String)
    case decryptionError(String)
}

// MARK: -
internal extension NetworkError {
    
    var description: String {
        switch self {
        case .notInitialized:
            return "Network service not initialized. Call NetworkProvider.shared.setup() first."
        case .invalidURL:
            return "Invalid URL provided."
        case .networkUnavailable:
            return "Network is not available."
        case .timeout:
            return "Request timed out."
        case .cancelled:
            return "Request was cancelled."
        case .requestFailed(let code, let message):
            return "Request failed with code \(code): \(message ?? "Unknown error")"
        case .resposeError(let code, let message):
            return "Server error \(code): \(message ?? "Unknown error")"
        case .noData:
            return "No data received from server."
        case .decodeError:
            return "Failed to decode response data."
        case .cacheError(let message):
            return "Cache error: \(message)"
        case .createSecKeyError(let message):
            return "RSA key creation error: \(message)"
        case .createSecKeyFailed(let error):
            if let error = error {
                let errMsg = String(describing: CFErrorCopyDescription(error))
                return "RSA key creation failed: \(errMsg)"
            } else {
                return "RSA key creation failed with unknown error."
            }
        case .encryptionError(let message):
            return "Encryption error: \(message)"
        case .decryptionError(let message):
            return "Decryption error: \(message)"
        }
    }
    
}
