//
//  AdValueStorage.swift
//  SmallGame
//
//  Created by arvin on 2025/6/28.
//

import Foundation
internal import GoogleMobileAds

// MARK: -
internal class AdValueStorage {
    static let shared = AdValueStorage()
    
    private let queue = DispatchQueue(label: "com.smallgame.advalue", attributes: .concurrent)
    private var adValueMap: [ObjectIdentifier: AdValue] = [:]
    
    // MARK: -
    /// 存储广告的价值信息
    /// - Parameters:
    ///   - adValue: AdMob 提供的 AdValue 对象
    ///   - ad: 广告对象
    func setAdValue(_ adValue: AdValue, for ad: Any) {
        let identifier = ObjectIdentifier(ad as AnyObject)
        queue.async(flags: .barrier) {
            self.adValueMap[identifier] = adValue
        }
    }
    
    /// 获取广告的详细价值信息
    /// - Parameter ad: 广告对象
    /// - Returns: AdValue 对象，如果没有找到则返回 nil
    func getAdValue(for ad: Any) -> AdValue? {
        let identifier = ObjectIdentifier(ad as AnyObject)
        return queue.sync {
            return adValueMap[identifier]
        }
    }
    
    // MARK: -
    /// 获取广告的收益值（美元，已转换为 ECPM）
    /// - Parameter ad: 广告对象
    /// - Returns: 收益值，如果没有找到则返回 nil
    func getRevenue(for ad: Any) -> Double? {
        let adValue = getAdValue(for: ad)
        return revenueInUSD(adValue)
    }
    
    // MARK: -
    /// 清除特定广告的价值信息
    /// - Parameter ad: 广告对象
    func clearAdValue(for ad: Any) {
        let identifier = ObjectIdentifier(ad as AnyObject)
        queue.async(flags: .barrier) {
            self.adValueMap.removeValue(forKey: identifier)
        }
    }
    
    /// 清除所有广告价值信息
    func clearAll() {
        queue.async(flags: .barrier) {
            self.adValueMap.removeAll()
        }
    }
    
    // MARK: -
    func revenueInUSD(_ adValue: AdValue?) -> Double {
        let value = adValue?.value.doubleValue ?? 0.0
        let baseAmount = value * 1000
        if adValue?.currencyCode == "USD" {
            return baseAmount
        }
        return localeRevenue(adValue)
    }
    
    func localeRevenue(_ adValue: AdValue?) -> Double {
        guard let value = adValue?.value else { return 0.0 }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = .current
        
        let amount = formatter.string(from: value)
        let price = Double(amount ?? "0")
        return (price ?? 0.0) * 1000
    }
    
}

// MARK: -
internal extension AdValueStorage {
    
    static func revenue(for ad: Any) -> Double {
        let shared = AdValueStorage.shared
        let v = shared.getRevenue(for: ad)
        return v ?? 0.0
    }
    
}
