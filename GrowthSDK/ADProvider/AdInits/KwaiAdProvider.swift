//
//  KwaiAdProvider.swift
//  SmallGame
//
//  Created by arvin on 2025/6/26.
//

import Foundation
internal import KwaiAdsSDK

// MARK: -
internal class KwaiAdProvider {
    
    static let shared = KwaiAdProvider()
    
    private var _isInitialized: Bool = false
    
    // MARK: -
    func initialize(complete: AdInitComplete? = nil) {
        let appId = ConfigFetcher.confgConfig?.kwaiAds?.appId
        let token = ConfigFetcher.confgConfig?.kwaiAds?.token
        guard let appId, !appId.isEmpty, let token, !token.isEmpty else {
            Logger.warning("[Ad] Kwai 配置缺失，跳过初始化")
            complete?(.kwai)
            return
        }
        let option = KCOAdsInitOption()
        option.mediationType = .SDK
        option.appId = appId
        option.token = token
        option.debug = GrowthKit.isLoggingEnabled
        
        let sdk = KCOAdsInitialization.sharedInstance()
        sdk.start(option) { [weak self] error in
            Logger.info("[Ad] kwai sdk 初始化完成")
            if let error = error { // SDK 初始化报错
                Logger.info("[Ad] Kwai-SDK error: \(error)")
            }
            guard let self = self else { return }
            self._isInitialized = true
            complete?(.kwai)
        }
    }
    
    var isInitialized: Bool {
        return _isInitialized
    }
    
}
