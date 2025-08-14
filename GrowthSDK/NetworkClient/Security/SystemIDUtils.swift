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
        let bundleName = Bundle.main.bundleIdentifier ?? ""
        let keychain = SecureStorage(service: bundleName)
        
        let key = "\(bundleName)-uuid-key"
        guard let uuid = keychain.string(forKey: key) else {
            let uuid = UUID().uuidString
            keychain.setString(uuid, forKey: key)
            return uuid
        }
        return uuid
    }
    
}
