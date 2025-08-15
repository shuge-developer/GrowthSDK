//
//  UserDefaultsExtension.swift
//  GrowthSDK
//
//  Created by arvin on 2025/7/30.
//

import Foundation

// MARK: -
internal extension UserDefaults {
    enum Key: String {
        case hasLaunchedBefore
        case configRejectionReason
        case configDailyLimitDate
        case configRejectionTime
        case configResolveTime
        case initConfigHistory
        case cfgConfigHistory
        case jsConfigHistory
    }
    static func setValue<T>(_ value: T, key: UserDefaults.Key) where T: Codable {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.setValue(data, forKey: key.rawValue)
            UserDefaults.standard.synchronize()
        }
    }
    
    static func value<T>(for key: UserDefaults.Key) -> T? where T: Codable {
        if let data = UserDefaults.standard.value(forKey: key.rawValue) as? Data {
            return try? JSONDecoder().decode(T.self, from: data)
        }
        return nil
    }
    static func set<T>(value: T, key: UserDefaults.Key) where T: Codable {
        UserDefaults.setValue(value, key: key)
    }
    
    static func get<T>(key: UserDefaults.Key) -> T? where T: Codable {
        return UserDefaults.value(for: key)
    }
}
