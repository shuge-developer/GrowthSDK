//
//  AdMobProvider.swift
//  SmallGame
//
//  Created by arvin on 2025/6/26.
//

import Foundation
internal import GoogleMobileAds

// MARK: -
internal class AdMobProvider {
    
    static let shared = AdMobProvider()
    
    private var _isInitialized: Bool = false
    
    // MARK: -
    func initialize(complete: AdInitComplete? = nil) {
        let sdk = MobileAds.shared
        sdk.start { [weak self] status in
            guard let self = self else { return }
            Logger.info("[Ad] admob sdk 初始化完成")
            self._isInitialized = true
            complete?(.admob)
        }
#if DEBUG
        sdk.requestConfiguration.testDeviceIdentifiers = [
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
    
    var isInitialized: Bool {
        return _isInitialized
    }
    
}

