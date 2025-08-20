//
//  AdInfoData.swift
//  SmallGame
//
//  Created by arvin on 2025/6/26.
//

import Foundation
internal import GoogleMobileAds
internal import AppLovinSDK
internal import KwaiAdsSDK
internal import BigoADS

// MARK: -
internal struct AdInfo: Codable, Transformable {
    /// 广告Id
    var adId: String?
    /// 广告国家
    var adCountry: String?
    /// 广告源
    var networkName: String?
    /// 广告聚合平台(MAX,BIGO,KWAI,OTHER等)
    var adSource: String?
    /// 广告价值传千次价值
    var adWorth: Double = 0.0
    /// 广告类型:0=激励视频,1=banner广告,2=插屏视频,3=native广告,4=开屏广告,5=快手(kwai)激励视频广告,6=bigo激励视频广告,7=admob开屏,8=bigo插屏
    var adType: Int?
    
    // MARK: - Firebase 埋点
    /// 广告格式
    var format: MAAd.AdFormat?
    /// 广告平台
    var platform: String?
    
    // MARK: -
    static func info(with adObj: Any?, adId: String) -> String? {
        AdInfo.infoModel(with: adObj, adId: adId)?.toJsonString()
    }
    
    static func infoModel(with result: BiddingResult) -> AdInfo? {
        let info = AdInfo.infoModel(
            with: result.adSource.adObj,
            adId: result.adStyle.adId
        )
        return info
    }
    
    static func infoModel(with adObj: Any?, adId: String) -> AdInfo? {
        guard let adObj else { return nil }
        var adInfo = AdInfo()
        switch adObj {
        case let wrapper as BigoAdWrapper:
            adInfo.adCountry = SystemIDUtils.countryCode
            adInfo.adSource = AdStyle.Source.bigo1.name
            adInfo.networkName = wrapper.platform
            adInfo.platform = wrapper.platform
            adInfo.adWorth = wrapper.revenue
            adInfo.format = wrapper.format
            adInfo.adType = wrapper.adType
            adInfo.adId = adId
            
        case let wrapper as KwaiAdWrapper:
            adInfo.adCountry = SystemIDUtils.countryCode
            adInfo.adSource = AdStyle.Source.kwai1.name
            adInfo.networkName = wrapper.platform
            adInfo.platform = wrapper.platform
            adInfo.adWorth = wrapper.revenue
            adInfo.format = wrapper.format
            adInfo.adType = wrapper.adType
            adInfo.adId = adId
            
        case let wrapper as AdMobAdWrapper:
            adInfo.adSource = "OTHER"
            adInfo.adCountry = SystemIDUtils.countryCode
            adInfo.networkName = wrapper.platform
            adInfo.platform = wrapper.platform
            adInfo.adWorth = wrapper.revenue
            adInfo.format = wrapper.format
            adInfo.adType = wrapper.adType
            adInfo.adId = adId
            
        case let wrapper as MaxAdWrapper:
            adInfo.adCountry = MaxAdProvider.countryCode
            adInfo.adSource = AdStyle.Source.max1.name
            adInfo.adId = wrapper.adUnitIdentifier
            adInfo.networkName = wrapper.networkName
            adInfo.adType = wrapper.adType
            adInfo.adWorth = wrapper.revenue
            adInfo.platform = wrapper.platform
            adInfo.format = wrapper.format
            
        case let ad as MAAd:
            adInfo.adCountry = MaxAdProvider.countryCode
            adInfo.adSource = AdStyle.Source.max1.name
            adInfo.adId = ad.adUnitIdentifier
            adInfo.networkName = ad.networkName
            adInfo.adType = ad.adFormat?.label
            adInfo.adWorth = ad.revenue * 1000
            adInfo.platform = "AppLovin"
            adInfo.format = ad.adFormat
            
        default:
            break
        }
        return adInfo
    }
    
}
