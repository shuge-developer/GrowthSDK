//
//  KwaiBiddingLoader.swift
//  SmallGame
//
//  Created by arvin on 2025/6/27.
//

import Foundation
internal import KwaiAdsSDK

// MARK: -
internal class KwaiBiddingLoader: NSObject, BiddingAdLoader {
    let adStyle: AdStyle
    private(set) var isLoading: Bool = false
    private(set) var isLoaded: Bool = false
    private(set) var loadTime: Date?
    
    private var rewardAd: KCOUnionRewardAd?
    private var interstitialAd: KCOUnionInterstitialAd?
    
    private var loadCompletion: ((Result<AdCallback.AdSource, AdError>) -> Void)?
    internal let rewardCallback = KwaiRewardAdCallback()
    internal let intersCallback = KwaiIntersAdCallback()
    
    // MARK: -
    init(adStyle: AdStyle) {
        self.adStyle = adStyle
        super.init()
        setupCallback()
    }
    
    // MARK: - BiddingAdLoader
    func load(completion: @escaping (Result<AdCallback.AdSource, AdError>) -> Void) {
        guard !isLoading && !isLoaded else {
            Logger.info("[Ad] [KwaiBiddingLoader] ⚠️ 广告已在加载中或已加载: \(adStyle)")
            return
        }
        
        isLoading = true
        loadCompletion = completion
        loadTime = Date()
        
        Logger.info("[Ad] [KwaiBiddingLoader] 🔄 开始加载 Kwai 竞价广告: \(adStyle.adId)")
        switch adStyle.format {
        case .rewarded:
            rewardAd = KCOUnionRewardAd.generate(withAdTagId: adStyle.adId)
            rewardAd?.loadDelegate = rewardCallback
            rewardAd?.delegate = rewardCallback
            rewardAd?.load()
            
        case .interstitial:
            interstitialAd = KCOUnionInterstitialAd.generate(withAdTagId: adStyle.adId)
            interstitialAd?.loadDelegate = intersCallback
            interstitialAd?.delegate = intersCallback
            interstitialAd?.load()
            
        default:
            isLoading = false
            completion(.failure(.adNotAvailable))
        }
    }
    
    func show(from viewController: UIViewController?, customData: String?) -> Bool {
        guard isLoaded else {
            Logger.info("[Ad] [KwaiBiddingLoader] ❌ 广告未准备好，无法展示")
            return false
        }
        switch adStyle.format {
        case .rewarded:
            guard let ad = rewardAd, ad.isReady else { return false }
            if let viewController {
                ad.show(with: viewController)
                return true
            }
        case .interstitial:
            guard let ad = interstitialAd, ad.isReady else { return false }
            if let viewController {
                ad.show(with: viewController)
                return true
            }
        default:
            return false
        }
        return false
    }
    
    func cleanup() {
        Logger.info("[Ad] [KwaiBiddingLoader] 🗑️ 清理 Kwai 广告资源: \(adStyle)")
        rewardAd = nil
        interstitialAd = nil
        isLoading = false
        isLoaded = false
        loadTime = nil
        loadCompletion = nil
    }
    
}

// MARK: - 竞价结果通知
extension KwaiBiddingLoader {
    
    func notifyBidWin(secondPrice: Double = 0, secondBidder: String = "") {
        Logger.info("[Ad] [KwaiBiddingLoader] 🏆 通知 Kwai 广告竞价获胜: \(adStyle)")
        switch adStyle.format {
        case .rewarded:
            rewardAd?.bidWin()
            
        case .interstitial:
            interstitialAd?.bidWin()
        default:
            break
        }
        
    }
    
    func notifyBidLoss(firstPrice: Double = 0, firstBidder: String = "", lossReason: BiddingLossReason = .unknown) {
        Logger.info("[Ad] [KwaiBiddingLoader] 💔 通知 Kwai 广告竞价失败: \(adStyle), 原因: \(lossReason)")
        switch adStyle.format {
        case .rewarded:
            rewardAd?.bidLose()
            
        case .interstitial:
            interstitialAd?.bidLose()
        default:
            break
        }
    }
    
}

// MARK: -
extension KwaiBiddingLoader {
    
    private func setupCallback() {
        let callback: AdCallback.AdLoadStateComplete = { [weak self] state in
            guard let self = self else { return }
            
            switch state {
            case .didLoad(let adSource):
                self.isLoading = false
                self.isLoaded = true
                
                let loadDuration = Date().timeIntervalSince(self.loadTime ?? Date())
                Logger.info("[Ad] [KwaiBiddingLoader] ✅ Kwai 广告加载成功: \(self.adStyle), 耗时: \(String(format: "%.2f", loadDuration))s")
                self.loadCompletion?(.success(adSource))
                
            case .loadFailure(let error):
                self.isLoading = false
                self.isLoaded = false
                
                let loadDuration = Date().timeIntervalSince(self.loadTime ?? Date())
                Logger.info("[Ad] [KwaiBiddingLoader] ❌ Kwai 广告加载失败: \(self.adStyle), Error: \(error.localizedDescription), 耗时: \(String(format: "%.2f", loadDuration))s")
                self.loadCompletion?(.failure(error))
                
            default:
                break
            }
        }
        switch adStyle.format {
        case .rewarded:
            rewardCallback.adStateComplete = callback
            
        case .interstitial:
            intersCallback.adStateComplete = callback
            
        default:
            break
        }
    }
    
}
