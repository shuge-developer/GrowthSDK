//
//  SystemIDUtils.swift
//  GrowthSDK
//
//  Created by arvin on 2025/7/22.
//

import Foundation
import AppTrackingTransparency
import AdSupport
import UIKit

// MARK: -
internal struct SystemIDUtils {
    
    internal static var idfvString: String? {
        let uuid = UIDevice.current.identifierForVendor
        return uuid?.uuidString
    }
    
    internal static var idfaString: String? {
        if #available(iOS 14, *) {
            let trackingStatus = ATTrackingManager.trackingAuthorizationStatus
            if (trackingStatus == .authorized) {
                let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
                return idfa
            }
            return nil
        } else {
            if ASIdentifierManager.shared().isAdvertisingTrackingEnabled {
                let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
                return idfa
            }
            return nil
        }
    }
    
    internal static var uuidString: String {
        let bundleName = Bundle.main.bundleIdentifier
        let key: SecureUtils.Key = .custom(bundleName)
        if let uuid = SecureUtils.string(for: key) {
            return uuid
        }
        let uuid = UUID().uuidString
        SecureUtils.set(string: uuid, for: key)
        return uuid
    }
    
    internal static var countryCode: String {
        let local = (Locale.current as NSLocale)
        let code = local.object(forKey: .countryCode)
        return (code as? String) ?? "unknown"
    }
    
    internal static var versionString: String {
        let infoDictionary = Bundle.main.infoDictionary
        let version = infoDictionary?["CFBundleShortVersionString"]
        return (version as? String) ?? "0.0"
    }
    
    internal static var buildString: String {
        let infoDictionary = Bundle.main.infoDictionary
        let version = infoDictionary?["CFBundleVersion"]
        return (version as? String) ?? "0"
    }
    
}

// MARK: -
internal struct SecureUtils {
    
    enum Key {
        case custom(String?)
        case userId
        
        var rawValue: String {
            if case .custom(let string) = self {
                return "\(self):\(string ?? "")"
            }
            return "\(self)"
        }
    }
    
    static let bundleName = Bundle.main.bundleIdentifier ?? ""
    
    static let shared = SecureStorage(service: bundleName)
    
    // MARK: -
    static func set(string value: String?, for key: Key) {
        shared.setString(value, forKey: key.rawValue)
    }
    
    static func string(for key: Key) -> String? {
        shared.string(forKey: key.rawValue)
    }
    
    static func clearAll() {
        try? shared.removeAll()
    }
    
}
