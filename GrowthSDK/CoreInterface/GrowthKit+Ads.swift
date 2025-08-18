//
//  GrowthKit+Ads.swift
//  GrowthSDK
//
//  Created by arvin on 2025/8/15.
//

import Foundation

// MARK: -
@objc public enum ADStyle: Int {
    case rewarded = 0
    case inserted = 1
    case appOpen = 2
    
    internal var description: String {
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

// MARK: -
@objc public protocol AdCallbacks {
    @objc optional func onStartLoading(_ style: ADStyle)
    @objc optional func onLoadSuccess(_ style: ADStyle)
    @objc optional func onLoadFailed(_ style: ADStyle, error: Error?)
    @objc optional func onShowSuccess(_ style: ADStyle)
    @objc optional func onShowFailed(_ style: ADStyle, error: Error?)
    @objc optional func onGetAdReward(_ style: ADStyle)
    @objc optional func onAdClick(_ style: ADStyle)
    @objc optional func onAdClose(_ style: ADStyle)
}

// MARK: -
public extension GrowthKit {
    
    @objc func reloadAppOpenAd() {
        let appOpenAd = AdsInitProvider.appOpenInitialized
        guard isInitialized && appOpenAd else {
            Logger.warning("未初始化完成，无法加载开屏广告")
            return
        }
        Task { @MainActor in
            await AppOpenAdManager.shared.loadAd()
            Logger.info("重新加载开屏广告")
        }
    }
    
    @objc func reloadBiddingAds() {
        let videoAd = AdsInitProvider.videoAdInitialized
        guard isInitialized && videoAd else {
            Logger.warning("未初始化完成，无法加载竞价广告")
            return
        }
        Task { @MainActor in
            AdBiddingManager.shared.preloadAllAds()
            Logger.info("重新加载竞价广告")
        }
    }
    
    // MARK: -
    @objc static func showAd(with style: ADStyle) {
        shared.showAd(with: style)
    }
    
    @objc static func showAd(with style: ADStyle, callbacks: AdCallbacks?) {
        shared.showAd(with: style, callbacks: callbacks)
    }
    
    // MARK: -
    @objc func showAd(with style: ADStyle) {
        showAd(with: style, callbacks: nil)
    }
    
    @objc func showAd(with style: ADStyle, callbacks: AdCallbacks?) {
        guard isInitialized else {
            let error = InitError.serviceInitFailed("SDK未初始化")
            callbacks?.onShowFailed?(style, error: error)
            Logger.warning("SDK未初始化，无法展示广告")
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
    
    // MARK: -
    @objc func showAdDebugger() {
        AdsInitProvider.showDebugger()
    }
    
}

// MARK: -
private extension GrowthKit {
    
    func showRewardedAd(callbacks: AdCallbacks?) async {
        let adCallbacks = handleCreateBidding(.rewarded, callbacks: callbacks)
        await MainActor.run {
            AdBiddingManager.shared.showAd(
                type: .rewarded, adCallbacks: adCallbacks
            )
        }
    }
    
    func showInterstitialAd(callbacks: AdCallbacks?) async {
        let adCallbacks = handleCreateBidding(.inserted, callbacks: callbacks)
        await MainActor.run {
            AdBiddingManager.shared.showAd(
                type: .interstitial, adCallbacks: adCallbacks
            )
        }
    }
    
    @MainActor func showAppOpenAd(callbacks: AdCallbacks?) {
        openAdCallbacks = callbacks
        let appOpenManager = AppOpenAdManager.shared
        appOpenManager.adStateComplete = { [weak self] state in
            guard let self = self else { return }
            self.handleOpenAdState(
                state, callbacks: openAdCallbacks
            )
        }
        AppOpenAdManager.shared.showAdIfAvailable()
    }
    
    // MARK: -
    func handleOpenAdState(_ state: AdCallback.AdLoadState, callbacks: AdCallbacks?) {
        guard let callbacks = callbacks else { return }
        switch state {
        case .didLoad(_):
            callbacks.onLoadSuccess?(.appOpen)
        case .loadFailure(let error):
            callbacks.onLoadFailed?(.appOpen, error: error)
        case .showFailure(let error):
            callbacks.onShowFailed?(.appOpen, error: error)
        case .didDisplay(_):
            callbacks.onShowSuccess?(.appOpen)
        case .didClick(_):
            callbacks.onAdClick?(.appOpen)
        case .didHide(_):
            callbacks.onAdClose?(.appOpen)
            self.openAdCallbacks = nil
        case .didReward(_):
            callbacks.onGetAdReward?(.appOpen)
        }
    }
    
    func handleCreateBidding(_ style: ADStyle, callbacks: AdCallbacks?) -> BiddingAdCallbacks? {
        guard let callbacks = callbacks else { return nil }
        return BiddingAdCallbacks {
            callbacks.onStartLoading?(style)
        } onLoadSuccess: { source in
            callbacks.onLoadSuccess?(style)
        } onLoadFailed: { error in
            callbacks.onLoadFailed?(style, error: error)
        } onShowSuccess: { result in
            callbacks.onShowSuccess?(style)
        } onShowFailed: { error in
            callbacks.onShowFailed?(style, error: error)
        } onGetReward: { result in
            callbacks.onGetAdReward?(style)
        } onAdClick: { result in
            callbacks.onAdClick?(style)
        } onClose: { result in
            callbacks.onAdClose?(style)
        }
    }
    
}
