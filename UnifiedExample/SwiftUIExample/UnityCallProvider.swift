//
//  UnityCallProvider.swift
//  SwiftUIExample
//
//  Created by arvin on 2025/8/21.
//

import Foundation
import GrowthSDK

// MARK: -
class UnityCallProvider: NativeCallable, AdCallbacks {
    
    static let shared = UnityCallProvider()
    
    // MARK: - NativeCallable
    func onAdShow(_ json: String?) {
        guard let json else { return }
        switch json {
        case "0":
            GrowthKit.showAd(with: .rewarded, callbacks: self)
        case "1":
            GrowthKit.showAd(with: .inserted, callbacks: self)
        case "2":
            GrowthKit.showAd(with: .appOpen, callbacks: self)
        case "3":
            GrowthKit.shared.showAdDebugger()
        default:
            break
        }
    }
    
    // MARK: - AdCallbacks
    func onStartLoading(_ style: ADStyle) {
        print(#function, style)
    }
    
    func onLoadSuccess(_ style: ADStyle) {
        print(#function, style)
    }
    
    func onLoadFailed(_ style: ADStyle, error: (any Error)?) {
        print(#function, style, error)
    }
    
    func onShowSuccess(_ style: ADStyle) {
        print(#function, style)
    }
    
    func onShowFailed(_ style: ADStyle, error: (any Error)?) {
        print(#function, style, error)
    }
    
    func onGetAdReward(_ style: ADStyle) {
        print(#function, style)
    }
    
    func onAdClick(_ style: ADStyle) {
        print(#function, style)
    }
    
    func onAdClose(_ style: ADStyle) {
        print(#function, style)
    }
    
}
