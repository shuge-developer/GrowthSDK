//
//  AdStyleConfigManager.swift
//  SmallGame
//
//  Created by arvin on 2025/6/28.
//

import Foundation
internal import AppLovinSDK

// MARK: - 广告源配置结构体
private struct AdSourceConfig {
    let name: String
    let ids: [String]?
    let sources: [AdStyle.Source]
}

// MARK: - 广告配置管理器
internal class AdStyleConfigManager {
    static let shared = AdStyleConfigManager()
    
    /// 获取指定竞价类型的广告样式数组
    /// 优先使用网络配置，如果没有则使用本地兜底配置
    func adStyles(for type: BiddingType) -> [AdStyle] {
        if let remoteStyles = getRemoteAdStyles(for: type), !remoteStyles.isEmpty {
            Logger.info("[Ad] [AdBiddingManager] 🌐 使用网络配置 \(type.description): \(remoteStyles.count) 个广告源")
            return remoteStyles
        } else {
            Logger.info("[Ad] [AdBiddingManager] 📱 使用本地兜底配置 \(type.description): \(type.localStyles.count) 个广告源")
            return type.localStyles
        }
    }
    
    /// 获取开屏广告样式（单独处理，因为不参与竞价）
    func appOpenAdStyle() -> AdStyle {
        return .appOpen
    }
    
    // MARK: -
    /// 从网络配置获取广告样式数组
    private func getRemoteAdStyles(for type: BiddingType) -> [AdStyle]? {
        let adUnitConfig: AdUnitConfig?
        if Thread.isMainThread {
            adUnitConfig = ConfigFetcher.adUnitConfig
        } else {
            adUnitConfig = DispatchQueue.main.sync {
                return ConfigFetcher.adUnitConfig
            }
        }
        guard let config = adUnitConfig else {
            Logger.info("[Ad] [AdBiddingManager] ⚠️ 网络广告配置为空，将使用本地兜底配置")
            return nil
        }
        switch type {
        case .rewarded:
            return convertToAdStyles(
                maxIds:  config.maxAdUnitConfig?.rewardedAdIds,
                kwaiIds: config.kwaiAdUnitConfig?.rewardedAdIds,
                bigoIds: config.bigoAdUnitConfig?.rewardedAdIds,
                type: .rewarded
            )
        case .interstitial:
            return convertToAdStyles(
                maxIds:  config.maxAdUnitConfig?.interstitialAdIds,
                kwaiIds: config.kwaiAdUnitConfig?.interstitialAdIds,
                bigoIds: config.bigoAdUnitConfig?.interstitialAdIds,
                type: .interstitial
            )
        }
    }
    
    /// 将网络配置的 ID 数组转换为 AdStyle 数组
    private func convertToAdStyles(maxIds: [String]?, kwaiIds: [String]?, bigoIds: [String]?, type: BiddingType) -> [AdStyle] {
        let sourceConfigs: [AdSourceConfig] = [
            AdSourceConfig(name: "MAX",  ids: maxIds,  sources: [.max1,  .max2]),
            AdSourceConfig(name: "Kwai", ids: kwaiIds, sources: [.kwai1, .kwai2]),
            AdSourceConfig(name: "Bigo", ids: bigoIds, sources: [.bigo1, .bigo2])
        ]
        return sourceConfigs.flatMap { config in
            createAdStyles(from: config, type: type)
        }
    }
    
    /// 从广告配置创建AdStyle数组
    private func createAdStyles(from config: AdSourceConfig, type: BiddingType) -> [AdStyle] {
        guard let ids = config.ids, !ids.isEmpty else { return [] }
        let maxCount = min(ids.count, config.sources.count)
        return Array(ids.prefix(maxCount)).enumerated().map { index, adId in
            let source = config.sources[index]
            return createAdStyle(
                type: type,
                source: source,
                adId: adId
            )
        }
    }
    
    /// 创建指定格式和来源的 AdStyle
    private func createAdStyle(type: BiddingType, source: AdStyle.Source, adId: String) -> AdStyle {
        let maFormat: MAAd.AdFormat = type == .rewarded ? .REWARDED : .INTER
        return .custom(id: adId, source: source, format: maFormat)
    }
    
}
