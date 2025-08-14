//
//  RequestConfig.swift
//  GrowthSDK
//
//  Created by arvin on 2025/7/18.
//

import Foundation

// MARK: -
internal enum BaseURL {
    case global(String)
    case custom(String, headers: [String: String]? = nil)
}

internal extension BaseURL {
    var value: String {
        switch self {
        case .global(let url):
            return url
        case .custom(let url, _):
            return url
        }
    }
    
    var customHeaders: [String: String]? {
        switch self {
        case .global:
            return nil
        case .custom(_, let headers):
            return headers
        }
    }
}

// MARK: -
internal protocol RequestConfigure: CustomStringConvertible {
    var baseURL: BaseURL { get }
    var timeout: TimeInterval { get }
    var cacheTTL: TimeInterval { get }
    var maxRetryCount: UInt { get }
    var rsaPublicKey: String { get }
    var aesKey: String { get }
    var aesIV: String { get }
    var headerProvider: HeaderConfigure { get }
    var isCacheEnabled: Bool { get }
    var isLogEnabled: Bool { get }
}

// MARK: -
internal extension RequestConfigure {
    
    var timeout: TimeInterval {
        return 30
    }
    
    var cacheTTL: TimeInterval {
        return 300
    }
    
    var maxRetryCount: UInt {
        return 3
    }
    
    var isCacheEnabled: Bool {
        return false
    }
    
    var isLogEnabled: Bool {
        return false
    }
    
    var isCustomURL: Bool {
        switch baseURL {
        case .custom(_, _):
            return true
        default:
            return false
        }
    }
    
}

// MARK: -
internal extension RequestConfigure {
    
    var description: String {
        var lines: [String] = []
        lines.append("=== Request Configuration ===")
        lines.append("Base URL: \(baseURL.value)")
        
        if case .custom(_, let headers) = baseURL, let customHeaders = headers {
            lines.append("Custom Headers: \(customHeaders)")
        }
        
        lines.append("Timeout: \(timeout)s")
        lines.append("Cache TTL: \(cacheTTL)s")
        lines.append("Max Retry Count: \(maxRetryCount)")
        lines.append("RSA Public Key: \(rsaPublicKey)")
        lines.append("AES Key: \(aesKey)")
        lines.append("AES IV: \(aesIV)")
        lines.append("Cache Enabled: \(isCacheEnabled)")
        lines.append("Log Enabled: \(isLogEnabled)")
        lines.append("Is Custom URL: \(isCustomURL)")
        
        lines.append("")
        lines.append("=== Header Configuration ===")
        lines.append(headerProvider.header() ?? "")
        
        lines.append("========================")
        return lines.joined(separator: "\n")
    }
    
}
