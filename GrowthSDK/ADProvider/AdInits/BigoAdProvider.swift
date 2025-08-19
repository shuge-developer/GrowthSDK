//
//  BigoAdProvider.swift
//  SmallGame
//
//  Created by arvin on 2025/6/26.
//

import Foundation
internal import BigoADS

// MARK: -
internal class BigoAdProvider {
    
    static let shared = BigoAdProvider()
    
    // MARK: -
    func initialize(complete: AdInitComplete? = nil) {
        let appId = ConfigFetcher.confgConfig?.bigo?.appId
        guard let appId, !appId.isEmpty else {
            Logger.warning("[Ad] Bigo 配置缺失，跳过初始化")
            complete?(.bigo)
            return
        }
        let config = BigoAdConfig(appId: appId)
        config.testMode = GrowthKit.isLoggingEnabled
        
        let sdk = BigoAdSdk.sharedInstance()
        sdk.initializeSdk(with: config) {
            Logger.info("[Ad] bigo sdk 初始化完成")
            complete?(.bigo)
        }
    }
    
    var isInitialized: Bool {
        let sdk = BigoAdSdk.sharedInstance()
        return sdk.isInitialized()
    }
    
}
