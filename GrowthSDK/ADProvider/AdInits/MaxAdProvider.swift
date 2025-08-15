//
//  MaxAdProvider.swift
//  SmallGame
//
//  Created by arvin on 2025/6/26.
//

import Foundation
internal import AppLovinSDK

// MARK: -
internal class MaxAdProvider {
    
    static let shared = MaxAdProvider()
    
    // MARK: -
    func initialize(complete: AdInitComplete? = nil) {
        let sdkKey = ""
        let initConfig = ALSdkInitializationConfiguration(sdkKey: sdkKey) { builder in
            builder.mediationProvider = ALMediationProviderMAX
        }
        
        let sdk = ALSdk.shared()
        sdk.settings.isCreativeDebuggerEnabled = true
        sdk.settings.isVerboseLoggingEnabled = true
        sdk.settings.userIdentifier = SystemIDUtils.uuidString
        sdk.settings.setExtraParameterForKey(
            "initialization_delay_ms", value: "0"
        )
        sdk.initialize(with: initConfig) { sdkConfig in
            Logger.info("[Ad] max sdk 初始化完成")
            complete?(.max)
        }
    }
    
    func showDebugger() {
        ALSdk.shared().showMediationDebugger()
    }
    
    // MARK: -
    var isInitialized: Bool {
        let sdk = ALSdk.shared()
        return sdk.isInitialized
    }
    
    static var countryCode: String? {
        let config = ALSdk.shared().configuration
        return config.countryCode
    }
    
}
