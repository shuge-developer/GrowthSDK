//
//  GrowthKit+Ads.swift
//  GrowthSDK
//
//  Created by arvin on 2025/8/15.
//

import Foundation

// MARK: - 广告样式
@objc public enum ADStyle: Int {
    case rewarded = 0
    case inserted = 1
    case appOpen = 2
}

// MARK: - 广告样式扩展
public extension ADStyle {
    var description: String {
        switch self {
        case .rewarded:
            return "激励"
        case .inserted:
            return "插屏"
        case .appOpen:
            return "开屏"
        }
    }
}


// MARK: - 广告回调协议
@objc public protocol AdCallbacks {
    @objc optional func onStartLoading()
    @objc optional func onLoadSuccess()
    @objc optional func onLoadFailed(_ error: Error?)
    @objc optional func onShowSuccess()
    @objc optional func onShowFailed(_ error: Error?)
    @objc optional func onAdClick()
    @objc optional func onGetReward()
    @objc optional func onClose()
}

// MARK: - 广告展示接口
public extension GrowthKit {
    
    @objc static func showAd(with style: ADStyle) {
        shared.showAd(with: style)
    }
    
    @objc static func showAd(with style: ADStyle, callbacks: AdCallbacks?) {
        shared.showAd(with: style, callbacks: callbacks)
    }
    
    @objc func showAd(with style: ADStyle) {
        showAd(with: style, callbacks: nil)
    }
    
    @objc func showAd(with style: ADStyle, callbacks: AdCallbacks?) {
        guard isInitialized else {
            Logger.warning("SDK未初始化，无法展示广告")
            callbacks?.onShowFailed?(InitError.serviceInitFailed("SDK未初始化"))
            return
        }
        
        Logger.info("请求展示\(style.description)广告")
        
        Task { @MainActor in
            switch style {
            case .rewarded:
                await showRewardedAd(callbacks: callbacks)
            case .inserted:
                await showInterstitialAd(callbacks: callbacks)
            case .appOpen:
                showAppOpenAd(callbacks: callbacks)
            }
        }
    }
    
}

// MARK: -
extension GrowthKit {
    
    private func showRewardedAd(callbacks: AdCallbacks?) async {
        Logger.info("展示激励广告")
        
        let biddingCallbacks = createBiddingCallbacks(from: callbacks)
        await MainActor.run {
            AdBiddingManager.shared.showAd(type: BiddingType.rewarded, adCallbacks: biddingCallbacks)
        }
    }
    
    private func showInterstitialAd(callbacks: AdCallbacks?) async {
        Logger.info("展示插屏广告")
        
        let biddingCallbacks = createBiddingCallbacks(from: callbacks)
        await MainActor.run {
            AdBiddingManager.shared.showAd(type: BiddingType.interstitial, adCallbacks: biddingCallbacks)
        }
    }
    
    @MainActor private func showAppOpenAd(callbacks: AdCallbacks?) {
        Logger.info("展示开屏广告")
        
        // 保存回调引用，防止被覆盖
        appOpenAdCallbacks = callbacks
        
        // 初始化开屏广告管理器回调
        setupAppOpenAdManager()
        
        // 展示广告
        AppOpenAdManager.shared.showAdIfAvailable()
    }
    
    private func createBiddingCallbacks(from callbacks: AdCallbacks?) -> BiddingAdCallbacks? {
        guard let callbacks = callbacks else { return nil }
        
        return BiddingAdCallbacks(
            onStartLoading: callbacks.onStartLoading,
            onLoadSuccess: { adSource in
                callbacks.onLoadSuccess?()
            },
            onLoadFailed: { error in
                callbacks.onLoadFailed?(error)
            },
            onShowSuccess: { result in
                callbacks.onShowSuccess?()
            },
            onShowFailed: { error in
                callbacks.onShowFailed?(error)
            },
            onGetReward: { result in
                callbacks.onGetReward?()
            },
            onAdClick: { result in
                callbacks.onAdClick?()
            },
            onClose: { result in
                callbacks.onClose?()
            }
        )
    }
    
}
