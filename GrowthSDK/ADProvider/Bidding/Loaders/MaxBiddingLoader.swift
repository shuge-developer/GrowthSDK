//
//  MaxBiddingLoader.swift
//  SmallGame
//
//  Created by arvin on 2025/6/27.
//

import Foundation
internal import AppLovinSDK

// MARK: -
internal class MaxBiddingLoader: NSObject, BiddingAdLoader {
    let adStyle: AdStyle
    private(set) var isLoading: Bool = false
    private(set) var isLoaded: Bool = false
    private(set) var loadTime: Date?
    
    private var rewardedAd: MARewardedAd?
    private var interstitialAd: MAInterstitialAd?
    
    private var loadCompletion: ((Result<AdCallback.AdSource, AdError>) -> Void)?
    internal let callback = MaxAdCallback()
    
    // MARK: -
    init(adStyle: AdStyle) {
        self.adStyle = adStyle
        super.init()
        setupCallback()
    }
    
    // MARK: - BiddingAdLoader
    func load(completion: @escaping (Result<AdCallback.AdSource, AdError>) -> Void) {
        guard !isLoading && !isLoaded else {
            Logger.info("[Ad] [MaxBiddingLoader] ⚠️ 广告已在加载中或已加载: \(adStyle)")
            return
        }
        
        isLoading = true
        loadCompletion = completion
        loadTime = Date()
        
        Logger.info("[Ad] [MaxBiddingLoader] 🔄 开始加载 MAX 广告: \(adStyle.adId)")
        
        switch adStyle.format {
        case .rewarded:
            rewardedAd = MARewardedAd.shared(withAdUnitIdentifier: adStyle.adId)
            rewardedAd?.revenueDelegate = callback
            rewardedAd?.delegate = callback
            rewardedAd?.load()
            
        case .interstitial:
            interstitialAd = MAInterstitialAd(adUnitIdentifier: adStyle.adId)
            interstitialAd?.revenueDelegate = callback
            interstitialAd?.delegate = callback
            interstitialAd?.load()
            
        default:
            isLoading = false
            completion(.failure(.adNotAvailable))
        }
    }
    
    func show(from viewController: UIViewController?, customData: String?) -> Bool {
        guard isLoaded else {
            Logger.info("[Ad] [MaxBiddingLoader] ❌ 广告未加载，无法展示")
            return false
        }
        Logger.info("[Ad] [MaxBiddingLoader] 🎬 开始展示 MAX 广告: \(adStyle), customData: \(customData)")
        switch adStyle.format {
        case .rewarded:
            guard let ad = rewardedAd, ad.isReady else {
                return false
            }
            ad.show(forPlacement: nil, customData: customData)
            return true
            
        case .interstitial:
            guard let ad = interstitialAd, ad.isReady else {
                return false
            }
            ad.show(forPlacement: nil, customData: customData)
            return true
            
        default:
            return false
        }
    }
    
    func cleanup() {
        Logger.info("[Ad] [MaxBiddingLoader] 🗑️ 清理 MAX 广告资源: \(adStyle)")
        
        rewardedAd?.delegate = nil
        rewardedAd?.revenueDelegate = nil
        rewardedAd = nil
        
        interstitialAd?.delegate = nil
        interstitialAd?.revenueDelegate = nil
        interstitialAd = nil
        
        isLoading = false
        isLoaded = false
        loadTime = nil
        loadCompletion = nil
    }
    
}

// MARK: - 竞价结果通知
extension MaxBiddingLoader {
    
    func notifyBidWin(secondPrice: Double, secondBidder: String) {
        Logger.info("[Ad] [MaxBiddingLoader] ℹ️ MAX 广告获胜，无需特殊通知")
    }
    
    func notifyBidLoss(firstPrice: Double, firstBidder: String, lossReason: BiddingLossReason) {
        Logger.info("[Ad] [MaxBiddingLoader] ℹ️ MAX 广告失败，无需特殊通知")
    }
    
}

// MARK: - 回调设置
extension MaxBiddingLoader {
    
    private func setupCallback() {
        callback.adStateComplete = { [weak self] state in
            guard let self = self else { return }
            
            switch state {
            case .didLoad(let adSource):
                self.isLoading = false
                self.isLoaded = true
                
                let loadDuration = Date().timeIntervalSince(self.loadTime ?? Date())
                Logger.info("[Ad] [MaxBiddingLoader] ✅ MAX 广告加载成功: \(self.adStyle), 耗时: \(String(format: "%.2f", loadDuration))s")
                self.loadCompletion?(.success(adSource))
                
            case .loadFailure(let error):
                self.isLoading = false
                self.isLoaded = false
                
                let loadDuration = Date().timeIntervalSince(self.loadTime ?? Date())
                Logger.info("[Ad] [MaxBiddingLoader] ❌ MAX 广告加载失败: \(self.adStyle), Error: \(error.localizedDescription), 耗时: \(String(format: "%.2f", loadDuration))s")
                self.loadCompletion?(.failure(error))
                
            default:
                break
            }
        }
    }
    
}
