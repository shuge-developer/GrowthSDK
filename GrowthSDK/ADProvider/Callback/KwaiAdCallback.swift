//
//  KwaiAdCallback.swift
//  SmallGame
//
//  Created by arvin on 2025/6/26.
//

import Foundation
internal import KwaiAdsSDK

// MARK: -
internal class KwaiRewardAdCallback: AdCallback, KCOUnionRewardLoadDelegate, KCOUnionRewardAdDelegate {
    
    private var ad: KCOUnionReward?
    
    // MARK: - KCOUnionRewardLoadDelegate
    
    /// 广告加载完成
    func didLoadAd(_ ad: KCOUnionReward) {
        let wrapper = KwaiAdWrapper(reward: ad)
        adStateComplete?(.didLoad(.kwai(wrapper)))
        self.ad = ad
    }
    
    /// 广告加载失败
    func didLoadAdFail(_ error: Error, trackId: String?) {
        let err = AdError.kwaiLoadFailed(error)
        adStateComplete?(.loadFailure(err))
    }
    
    // MARK: - KCOUnionRewardAdDelegate
    
    /// 广告页面展示
    func didRewardShow() {
        if let ad = ad {
            let wrapper = KwaiAdWrapper(reward: ad)
            adStateComplete?(.didDisplay(.kwai(wrapper)))
        }
    }
    
    /// 广告页面展示失败
    func didRewardShowFail(_ error: Error) {
        let err = AdError.kwaiShowFailed(error)
        adStateComplete?(.showFailure(err))
    }
    
    /// 广告页面发生点击
    func didRewardClick() {
        if let ad = ad {
            let wrapper = KwaiAdWrapper(reward: ad)
            adStateComplete?(.didClick(.kwai(wrapper)))
        }
    }
    
    /// 广告视频播放完成
    func didRewardPlayComplete() {
        
    }
    
    /// 获得广告奖励
    func didRewardEarned() {
        if let ad = ad {
            let wrapper = KwaiAdWrapper(reward: ad)
            adStateComplete?(.didReward(.kwai(wrapper)))
        }
    }
    
    /// 广告页面关闭
    func didRewardClose() {
        if let ad = ad {
            let wrapper = KwaiAdWrapper(reward: ad)
            adStateComplete?(.didHide(.kwai(wrapper)))
        }
    }
    
}

// MARK: -
internal class KwaiIntersAdCallback: AdCallback, KCOUnionInterstitialLoadDelegate, KCOUnionInterstitialAdDelegate {
    
    private var ad: KCOUnionInterstitial?
    
    // MARK: - KCOUnionInterstitialLoadDelegate
    
    /// 广告加载完成
    func didLoadAd(_ ad: KCOUnionInterstitial) {
        let wrapper = KwaiAdWrapper(interstitial: ad)
        adStateComplete?(.didLoad(.kwai(wrapper)))
        self.ad = ad
    }
    
    /// 广告加载失败
    func didLoadAdFail(_ error: any Error, trackId: String?) {
        let err = AdError.kwaiLoadFailed(error)
        adStateComplete?(.loadFailure(err))
    }
    
    // MARK: - KCOUnionInterstitialAdDelegate
    
    /// 广告页面展示
    func didInterstitialShow() {
        if let ad = ad {
            let wrapper = KwaiAdWrapper(interstitial: ad)
            adStateComplete?(.didDisplay(.kwai(wrapper)))
        }
    }
    
    /// 广告页面展示失败
    func didInterstitialShowFail(_ error: any Error) {
        let err = AdError.kwaiShowFailed(error)
        adStateComplete?(.showFailure(err))
    }
    
    /// 广告页面发生点击
    func didInterstitialClick() {
        if let ad = ad {
            let wrapper = KwaiAdWrapper(interstitial: ad)
            adStateComplete?(.didClick(.kwai(wrapper)))
        }
    }
    
    /// 广告视频播放完成
    func didInterstitialPlayComplete() {
        
    }
    
    /// 广告页面关闭
    func didInterstitialClose() {
        if let ad = ad {
            let wrapper = KwaiAdWrapper(interstitial: ad)
            adStateComplete?(.didHide(.kwai(wrapper)))
        }
    }
    
}
