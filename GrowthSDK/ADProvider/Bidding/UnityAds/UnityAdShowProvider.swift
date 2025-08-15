//
//  UnityAdShowProvider.swift
//  SmallGame
//
//  Created by arvin on 2025/6/30.
//

import Foundation

// MARK: -
@MainActor
internal class UnityAdShowProvider {
    
    static func show() {
        guard canShowAd() else {
            Logger.info("[Ad] 广告展示被阻止")
            return
        }
        let adCallbacks = BiddingAdCallbacks(
            onStartLoading: {
//                CallUnityProvider.haveAds(false)
                Logger.info("[Ad] onStartLoading")
            },
            onLoadSuccess: { adSource in
                Logger.info("[Ad] onLoadSuccess, adSource: \(adSource)")
            },
            onLoadFailed: { error in
                Logger.info("[Ad] onLoadFailed, error: \(error)")
//                AdThinking.adLoadFail(error: error)
                markAdFailed()
            },
            onShowSuccess: { result in
//                CallUnityProvider.haveAds(true)
                Logger.info("[Ad] onShowSuccess, adSource: \(result.description)")
                let info = AdInfo.infoModel(by: result)
//                AdThinking.adShow(data, info: info)
//                CallUnityProvider.onSetAudio(false)
                markAdStarted()
            },
            onShowFailed: { error in
                Logger.info("[Ad] onShowFailed, error: \(error)")
//                AdThinking.adShowFail(error)
                markAdFailed()
            },
            onGetReward: { result in
                Logger.info("[Ad] onGetReward, result: \(result.description)")
                let info = AdInfo.infoModel(by: result)
//                NetworkManager.uploadAdRevenue(info)
//                AdThinking.ad_firebaseThinking(info)
            },
            onAdClick: { result in
                Logger.info("[Ad] onAdClick, result: \(result.description)")
//                let info = AdInfo.infoModel(by: result)
//                AdThinking.adClick(data, info: info)
            },
            onClose: { result in
                Logger.info("[Ad] onClose, result: \(result.description)")
//                CallUnityProvider.onAdComplete()
                markAdClosed()
            }
        )
        Task { @MainActor in
//            AdBiddingManager.shared.showAd(
//                type: data.adsType,
//                adCallbacks: adCallbacks
//            )
        }
    }
    
}
