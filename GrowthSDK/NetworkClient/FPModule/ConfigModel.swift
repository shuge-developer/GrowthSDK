//
//  ConfigModel.swift
//  GrowthSDK
//
//  Created by arvin on 2025/8/15.
//

import Foundation

// MARK: - Adjust Config
internal class AdjustConfig: Codable {
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
internal class AdUnitConfig: Codable {
    var abTest: String?
    var interAdIntervalSec: Int?
    var maxAdUnitConfig: MaxAdUnitConfig?
    var kwaiAdUnitConfig: KwaiAdUnitConfig?
    var bigoAdUnitConfig: BigoAdUnitConfig?
    var adMobAdUnitConfig: AdMobAdUnitConfig?
}

// MARK: - Max Ad Unit Config
internal class MaxAdUnitConfig: Codable {
    var rewardedAdIds: [String]?
    var interstitialAdIds: [String]?
}

// MARK: - Kwai Ad Unit Config
internal class KwaiAdUnitConfig: Codable {
    var rewardedAdIds: [String]?
    var interstitialAdIds: [String]?
}

// MARK: - Bigo Ad Unit Config
internal class BigoAdUnitConfig: Codable {
    var rewardedAdIds: [String]?
    var interstitialAdIds: [String]?
}

// MARK: - AdMob Ad Unit Config
internal class AdMobAdUnitConfig: Codable {
    var splashAdIds: [String]?
}
