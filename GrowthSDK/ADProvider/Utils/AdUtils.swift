//
//  AdUtils.swift
//  SmallGame
//
//  Created by arvin on 2025/6/26.
//

import Foundation
internal import GoogleMobileAds
internal import AppLovinSDK
internal import KwaiAdsSDK
internal import BigoADS

// MARK: - MAAd.AdFormat 扩展
internal extension MAAd {
    
    enum AdFormat: String, Codable {
        case APPOPEN
        case REWARDED
        case NATIVE
        case BANNER
        case INTER
        
        var label: Int {
            switch self {
            case .APPOPEN:
                return 4 // 开屏广告
            case .REWARDED:
                return 0 // 激励视频
            case .NATIVE:
                return 3 // native广告
            case .BANNER:
                return 1 // banner广告
            case .INTER:
                return 2 // 插屏视频
            }
        }
        
        var maFormat: MAAdFormat {
            switch self {
            case .APPOPEN:
                return .appOpen
            case .REWARDED:
                return .rewarded
            case .NATIVE:
                return .native
            case .BANNER:
                return .banner
            case .INTER:
                return .interstitial
            }
        }
    }
    
    var isAdmobOpen: Bool {
        guard adFormat == .APPOPEN else { return false }
        return networkName.lowercased().contains("admob")
    }
    
    var adFormat: AdFormat? {
        return AdFormat(rawValue: format.label)
    }
    
    var platform: String {
        return "AppLovin"
    }
    
}

// MARK: - FullScreenPresentingAd 扩展
internal extension FullScreenPresentingAd {
    
    /// 广告平台
    var platform: String {
        return "Google AdMob"
    }
    
    /// 广告格式
    var format: MAAd.AdFormat? {
        switch self {
        case is AppOpenAd:
            return .APPOPEN
        case is RewardedAd:
            return .REWARDED
        case is InterstitialAd:
            return .INTER
        default:
            return nil
        }
    }
    
    /// 千次广告价值（`ECPM`）
    var revenue: Double {
        return AdValueStorage.revenue(for: self)
    }
    
    /// 广告类型
    var adType: Int {
        switch self {
        case is AppOpenAd:
            return 7
        default:
            return -1
        }
    }
    
}

// MARK: -
internal struct AdUtils {
    
    /// 为异步操作添加超时机制
    /// - Parameters:
    ///   - seconds: 超时时间（秒）
    ///   - operation: 要执行的异步操作
    /// - Returns: 操作结果
    /// - Throws: AdError.timeout 或操作本身的错误
    static func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            group.addTask {
                let time = UInt64(seconds * 1_000_000_000)
                try await Task.sleep(nanoseconds: time)
                throw AdError.timeout
            }
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
    
}

// MARK: - 快手广告包装器
internal struct KwaiAdWrapper {
    private let interstitial: KCOUnionInterstitial?
    private let reward: KCOUnionReward?
    
    init(interstitial: KCOUnionInterstitial) {
        self.interstitial = interstitial
        self.reward = nil
    }
    
    init(reward: KCOUnionReward) {
        self.interstitial = nil
        self.reward = reward
    }
    
    var description: String {
        if let interstitial = interstitial {
            return "[KCOUnionInterstitial adTrackId=\(interstitial.adTrackId.prefix(10))..., adTagId=\(interstitial.adTagId), price=\(interstitial.price)]"
        } else if let reward = reward {
            return "[KCOUnionReward adTrackId=\(reward.adTrackId.prefix(10))..., adTagId=\(reward.adTagId), price=\(reward.price)]"
        }
        return "[KwaiAd]"
    }
    
    var platform: String {
        return "Kwai"
    }
    
    var format: MAAd.AdFormat? {
        if interstitial != nil {
            return .INTER
        } else if reward != nil {
            return .REWARDED
        }
        return nil
    }
    
    var revenue: Double {
        if let interstitial = interstitial {
            let amount = Double(interstitial.price)
            return amount ?? 0.0
        } else if let reward = reward {
            let amount = Double(reward.price)
            return amount ?? 0.0
        }
        return 0.0
    }
    
    var adType: Int {
        if interstitial != nil {
            return 9
        } else if reward != nil {
            return 5
        }
        return -1
    }
    
}

// MARK: - Bigo广告包装器
internal struct BigoAdWrapper {
    private let ad: BigoAd
    
    init(ad: BigoAd) {
        self.ad = ad
    }
    
    // 提供访问原始广告对象的方法
    var originalAd: BigoAd {
        return ad
    }
    
    // 类型安全的访问方法
    var rewardVideoAd: BigoRewardVideoAd? {
        return ad as? BigoRewardVideoAd
    }
    
    var interstitialAd: BigoInterstitialAd? {
        return ad as? BigoInterstitialAd
    }
    
    var description: String {
        let creativeId = ad.getCreativeId() ?? "nil"
        return "[BigoRewardVideoAd creativeId=\(creativeId), isExpired=\(ad.isExpired()), price=\(revenue)]"
    }
    
    var platform: String {
        return "Bigo"
    }
    
    var format: MAAd.AdFormat? {
        switch ad {
        case is BigoRewardVideoAd:
            return .REWARDED
        case is BigoInterstitialAd:
            return .INTER
        default:
            return nil
        }
    }
    
    var revenue: Double {
        if let bid = ad.getBid() {
            let price = bid.getPrice()
            return Double(price)
        }
        return 0.0
    }
    
    var adType: Int {
        switch ad {
        case is BigoRewardVideoAd:
            return 6
        case is BigoInterstitialAd:
            return 8
        default:
            return -1
        }
    }
    
}

// MARK: - MAX广告包装器
internal struct MaxAdWrapper {
    private let ad: MAAd
    
    init(ad: MAAd) {
        self.ad = ad
    }
    
    var description: String {
        return ad.description
    }
    
    var platform: String {
        return "AppLovin"
    }
    
    var format: MAAd.AdFormat? {
        return ad.adFormat
    }
    
    var revenue: Double {
        let cpm = ad.revenue
        return Double(cpm * 1000)
    }
    
    var adType: Int {
        return ad.adFormat?.label ?? -1
    }
    
    var networkName: String {
        return ad.networkName
    }
    
    var adUnitIdentifier: String {
        return ad.adUnitIdentifier
    }
    
    var isAdmobOpen: Bool {
        return ad.isAdmobOpen
    }
    
}

// MARK: - AdMob广告包装器
internal struct AdMobAdWrapper {
    private let ad: FullScreenPresentingAd
    
    init(ad: FullScreenPresentingAd) {
        self.ad = ad
    }
    
    var platform: String {
        return "Google AdMob"
    }
    
    var format: MAAd.AdFormat? {
        switch ad {
        case is AppOpenAd:
            return .APPOPEN
        case is RewardedAd:
            return .REWARDED
        case is InterstitialAd:
            return .INTER
        default:
            return nil
        }
    }
    
    var revenue: Double {
        return AdValueStorage.revenue(for: ad)
    }
    
    var adType: Int {
        switch ad {
        case is AppOpenAd:
            return 7
        default:
            return -1
        }
    }
    
}

// MARK: -
internal extension KCOUnionInterstitialAd {
    
    private static let adLoadAssociation = AnyAssociation<Bool>()
    
    /// 广告是否已加载
    var isLoad: Bool {
        get { return Self.adLoadAssociation[self] ?? false }
        set { Self.adLoadAssociation[self] = newValue }
    }
    
}

internal extension KCOUnionRewardAd {
    
    private static let adLoadAssociation = AnyAssociation<Bool>()
    
    /// 广告是否已加载
    var isLoad: Bool {
        get { return Self.adLoadAssociation[self] ?? false }
        set { Self.adLoadAssociation[self] = newValue }
    }
    
}

// MARK: -
internal struct MaxCustomData: Codable, Transformable {
    var adWorth: Double
    var appId: String?
    var gaid: String?
    var uuid: String
    
    init(adWorth: Double) {
        self.adWorth = adWorth
        self.appId = GrowthKit.shared.config.serviceId
        self.gaid = SystemIDUtils.idfaString
        self.uuid = SystemIDUtils.uuidString
    }
    
    static func adWorth(_ revenue: Double) -> String? {
        let data = MaxCustomData(adWorth: revenue)
        return data.toJsonString()
    }
    
}
