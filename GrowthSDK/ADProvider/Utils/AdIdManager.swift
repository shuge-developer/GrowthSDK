//
//  AdIdManager.swift
//  SmallGame
//
//  Created by arvin on 2025/6/28.
//

import Foundation

// MARK: - 广告ID管理器
internal class AdIdManager {
    static let shared = AdIdManager()
    
    // MARK: -
    /// 获取开屏广告ID
    /// 优先使用远程配置，无配置时使用本地兜底
    func appOpenAdId() -> String {
        if let remoteId = remoteAppOpenAdId() {
            Logger.info("[Ad] [AdIdManager] 🌐 使用远程开屏广告ID: \(remoteId)")
            return remoteId
        } else {
            let localId = localAppOpenAdId()
            Logger.info("[Ad] [AdIdManager] 📱 使用本地兜底开屏广告ID: \(localId)")
            return localId
        }
    }
    
    // MARK: - 私有方法
    /// 从远程配置获取开屏广告ID
    private func remoteAppOpenAdId() -> String? {
        let adUnitConfig: AdUnitConfig?
        if Thread.isMainThread {
            adUnitConfig = ConfigFetcher.adUnitConfig
        } else {
            adUnitConfig = DispatchQueue.main.sync {
                return ConfigFetcher.adUnitConfig
            }
        }
        guard let config = adUnitConfig?.adMobAdUnitConfig else {
            Logger.info("[Ad] [AdIdManager] ⚠️ 网络广告配置为空，开屏广告将使用本地兜底ID")
            return nil
        }
        guard let splashIds = config.splashAdIds, !splashIds.isEmpty else {
            Logger.info("[Ad] [AdIdManager] ⚠️ 远程开屏广告ID配置为空，将使用本地兜底ID")
            return nil
        }
        return splashIds.first
    }
    
    /// 获取本地兜底的开屏广告ID
    private func localAppOpenAdId() -> String {
        return ""//AppConfigure.AD.AdMob.AppOpen.adId
    }
    
}
