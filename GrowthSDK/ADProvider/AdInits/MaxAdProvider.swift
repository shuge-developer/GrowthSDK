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
        let sdkKey = ""//AppConfigure.AD.MAX.sdkKey
        let initConfig = ALSdkInitializationConfiguration(sdkKey: sdkKey) { builder in
            builder.mediationProvider = ALMediationProviderMAX
#if DEBUG
            builder.testDeviceAdvertisingIdentifiers = [
                "6638E837-4C90-48CC-BE6A-882330C9AC07",
                "6638E837-4C90-48CC-BE6A-882330C9AC07",
                "D21AFB1D-2967-4153-AA56-0FA203E2D439",
                "C05EC5C6-EDD5-4547-81C3-AED8D045D7AC",
                "B5C85D60-205C-4767-BAC6-CFDCFF6D9256",
                "07D7F1B4-B668-4C50-83B7-E4999FE44E0C",
                "C0D33FA9-0F1D-48A5-B3B0-FCEA27F60418",
                "BE2EF246-44C6-4E9F-82DE-049C889B3A91"
            ]
#endif
        }
        
        let sdk = ALSdk.shared()
//        let logManager = SDKLogManager.shared
        sdk.settings.isCreativeDebuggerEnabled = true//logManager.maxDebugger
        sdk.settings.isVerboseLoggingEnabled = true//logManager.maxVerboseLog
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
