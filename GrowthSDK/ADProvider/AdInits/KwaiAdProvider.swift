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
        let option = KCOAdsInitOption()
        option.appId = ""//AppConfigure.AD.Kwai.appId
        option.token = ""//AppConfigure.AD.Kwai.token
        option.debug = true
        option.mediationType = .SDK
        
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
