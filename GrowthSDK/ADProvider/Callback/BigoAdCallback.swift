//
//  BigoAdCallback.swift
//  SmallGame
//
//  Created by arvin on 2025/6/26.
//

import Foundation
internal import BigoADS

// MARK: -
internal class BigoAdCallback: AdCallback, BigoRewardVideoAdLoaderDelegate, BigoRewardVideoAdInteractionDelegate, BigoInterstitialAdLoaderDelegate {
    
    // MARK: - BigoInterstitialAdLoaderDelegate
    
    func onInterstitialAdLoaded(_ ad: BigoInterstitialAd) {
        ad.setAdInteractionDelegate(self)
        let wrapper = BigoAdWrapper(ad: ad)
        adStateComplete?(.didLoad(.bigo(wrapper)))
    }
    
    func onInterstitialAdLoadError(_ error: BigoAdError) {
        let err = AdError.bigoLoadFailed(error)
        adStateComplete?(.loadFailure(err))
    }
    
    // MARK: - BigoRewardVideoAdLoaderDelegate
    
    /// 广告加载完成
    func onRewardVideoAdLoaded(_ ad: BigoRewardVideoAd) {
        ad.setRewardVideoAdInteractionDelegate(self)
        let wrapper = BigoAdWrapper(ad: ad)
        adStateComplete?(.didLoad(.bigo(wrapper)))
    }
    
    /// 广告加载失败
    func onRewardVideoAdLoadError(_ error: BigoAdError) {
        let err = AdError.bigoLoadFailed(error)
        adStateComplete?(.loadFailure(err))
    }
    
    // MARK: - BigoRewardVideoAdInteractionDelegate
    
    /// 激励视频已播放完成，可下发奖励
    func onAdRewarded(_ ad: BigoRewardVideoAd) {
        let wrapper = BigoAdWrapper(ad: ad)
        adStateComplete?(.didReward(.bigo(wrapper)))
    }
    
    // MARK: - BigoAdInteractionDelegate
    
    /// 广告异常
    func onAd(_ ad: BigoAd, error: BigoAdError) {
        let err = AdError.bigoShowFailed(error)
        adStateComplete?(.showFailure(err))
    }
    
    /// 广告打开
    func onAdOpened(_ ad: BigoAd) {
        
    }
    
    /// 广告展示
    func onAdImpression(_ ad: BigoAd) {
        let wrapper = BigoAdWrapper(ad: ad)
        adStateComplete?(.didDisplay(.bigo(wrapper)))
    }
    
    /// 广告点击
    func onAdClicked(_ ad: BigoAd) {
        let wrapper = BigoAdWrapper(ad: ad)
        adStateComplete?(.didClick(.bigo(wrapper)))
    }
    
    /// 广告关闭
    func onAdClosed(_ ad: BigoAd) {
        let wrapper = BigoAdWrapper(ad: ad)
        adStateComplete?(.didHide(.bigo(wrapper)))
    }
    
    /// 广告已被屏蔽（由负反馈触发）
    func onAdMuted(_ ad: BigoAd) {
        
    }
    
}
