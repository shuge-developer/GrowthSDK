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
    }
    
    var isInitialized: Bool {
        return _isInitialized
    }
    
}

