//
//  ConfigModel.swift
//  GrowthSDK
//
//  Created by arvin on 2025/8/15.
//

import Foundation

// MARK: - Adjust Config
internal struct AdjustConfig: Codable {
    var initRate: Double = 0.5
    var isLegally: Bool = true
    var force: Bool?
    
    var adChannel: String?
    var userId: String?
    
    // MARK: -
    var isVerifying: Bool {
        guard let force = force else { return false }
        return force == true && isLegally == true
    }
}

// MARK: - Ad Unit Config
internal struct AdUnitConfig: Codable {
    var abTest: String?
    var interAdIntervalSec: Int?
    var maxAdUnitConfig: MaxAdUnitConfig?
    var kwaiAdUnitConfig: KwaiAdUnitConfig?
    var bigoAdUnitConfig: BigoAdUnitConfig?
    var adMobAdUnitConfig: AdMobAdUnitConfig?
}

// MARK: - Max Ad Unit Config
internal struct MaxAdUnitConfig: Codable {
    var rewardedAdIds: [String]?
    var interstitialAdIds: [String]?
}

// MARK: - Kwai Ad Unit Config
internal struct KwaiAdUnitConfig: Codable {
    var rewardedAdIds: [String]?
    var interstitialAdIds: [String]?
}

// MARK: - Bigo Ad Unit Config
internal struct BigoAdUnitConfig: Codable {
    var rewardedAdIds: [String]?
    var interstitialAdIds: [String]?
}

// MARK: - AdMob Ad Unit Config
internal struct AdMobAdUnitConfig: Codable {
    var splashAdIds: [String]?
}

// MARK: - Confg Config
internal struct ConfgConfig: Codable {
    var thinking: ThinkingConfig?
    var appLovin: AppLovinConfig?
    var kwaiAds: KwaiAdsConfig?
    var bigo: BigoConfig?
}

internal struct ThinkingConfig: Codable {
    var appId: String?
    var serverUrl: String?
    
    var canInitialize: Bool {
        guard let appId = appId else { return false }
        guard let url = serverUrl else { return false }
        return !appId.isEmpty && !url.isEmpty
    }
}

internal struct AppLovinConfig: Codable {
    var sdkKey: String?
    
    var canInitialize: Bool {
        guard let sdkKey = sdkKey else { return false }
        return !sdkKey.isEmpty
    }
}

internal struct KwaiAdsConfig: Codable {
    var appId: String?
    var token: String?
    
    var canInitialize: Bool {
        guard let appId = appId else { return false }
        guard let token = token else { return false }
        return !appId.isEmpty && !token.isEmpty
    }
}

internal struct BigoConfig: Codable {
    var appId: String?
    
    var canInitialize: Bool {
        guard let appId = appId else { return false }
        return !appId.isEmpty
    }
}
