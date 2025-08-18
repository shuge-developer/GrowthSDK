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
        let appid = ConfigFetcher.confgConfig?.bigo?.appId ?? ""
        let config = BigoAdConfig(appId: appid)
        config.testMode = true
        
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
