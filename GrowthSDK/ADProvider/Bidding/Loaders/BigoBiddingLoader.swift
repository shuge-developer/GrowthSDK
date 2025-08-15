//
//  BigoBiddingLoader.swift
//  SmallGame
//
//  Created by arvin on 2025/6/27.
//

import Foundation
internal import BigoADS

// MARK: -
internal class BigoBiddingLoader: NSObject, BiddingAdLoader {
    let adStyle: AdStyle
    private(set) var isLoading: Bool = false
    private(set) var isLoaded: Bool = false
    private(set) var loadTime: Date?
    
    private var rewardVideoAd: BigoRewardVideoAd?
    private var rewardAdLoader: BigoRewardVideoAdLoader?
    private var interstitialAd: BigoInterstitialAd?
    private var intersAdLoader: BigoInterstitialAdLoader?
    
    private var loadCompletion: ((Result<AdCallback.AdSource, AdError>) -> Void)?
    internal let callback = BigoAdCallback()
    
    // MARK: -
    init(adStyle: AdStyle) {
        self.adStyle = adStyle
        super.init()
        setupCallback()
    }
    
    // MARK: - BiddingAdLoader
    func load(completion: @escaping (Result<AdCallback.AdSource, AdError>) -> Void) {
        guard !isLoading && !isLoaded else {
            Logger.info("[Ad] [BigoBiddingLoader] ⚠️ 广告已在加载中或已加载: \(adStyle)")
            return
        }
        
        isLoading = true
        loadCompletion = completion
        loadTime = Date()
        
        Logger.info("[Ad] [BigoBiddingLoader] 🔄 开始加载 Bigo 广告: \(adStyle.adId)")
        
        switch adStyle.format {
        case .rewarded:
            rewardAdLoader = BigoRewardVideoAdLoader(rewardVideoAdLoaderDelegate: callback)
            let request = BigoRewardVideoAdRequest(slotId: adStyle.adId)
            rewardAdLoader?.loadAd(request)
        case .interstitial:
            intersAdLoader = BigoInterstitialAdLoader(interstitialAdLoaderDelegate: callback)
            let request = BigoInterstitialAdRequest(slotId: adStyle.adId)
            intersAdLoader?.loadAd(request)
        default:
            isLoading = false
            completion(.failure(.adNotAvailable))
        }
    }
    
    func show(from viewController: UIViewController?, customData: String?) -> Bool {
        guard isLoaded else {
            Logger.info("[Ad] [BigoBiddingLoader] ❌ 广告未加载，无法展示")
            return false
        }
        
        // 展示前检查广告是否过期
        if !isAdValid() {
            Logger.info("[Ad] [BigoBiddingLoader] ❌ 广告已过期，无法展示: \(adStyle)")
            isLoaded = false
            return false
        }
        
        switch adStyle.format {
        case .rewarded:
            guard let ad = rewardVideoAd else { return false }
            if let viewController {
                ad.show(viewController)
                return true
            }
        case .interstitial:
            guard let ad = interstitialAd else { return false }
            if let viewController {
                ad.show(viewController)
                return true
            }
        default:
            return false
        }
        return false
    }
    
    func cleanup() {
        Logger.info("[Ad] [BigoBiddingLoader] 🗑️ 清理 Bigo 广告资源: \(adStyle)")
        
        // 销毁广告对象
        destroyAds()
        
        rewardVideoAd = nil
        interstitialAd = nil
        rewardAdLoader = nil
        intersAdLoader = nil
        isLoading = false
        isLoaded = false
        loadTime = nil
        loadCompletion = nil
    }
    
}

// MARK: - 广告状态管理
extension BigoBiddingLoader {
    
    /// 检查广告是否有效（未过期）
    func isAdValid() -> Bool {
        switch adStyle.format {
        case .rewarded:
            if let ad = rewardVideoAd {
                let isExpired = ad.isExpired()
                if isExpired {
                    Logger.info("[Ad] [BigoBiddingLoader] ⏰ Bigo 激励视频广告已过期: \(adStyle)")
                }
                return !isExpired
            }
        case .interstitial:
            if let ad = interstitialAd {
                let isExpired = ad.isExpired()
                if isExpired {
                    Logger.info("[Ad] [BigoBiddingLoader] ⏰ Bigo 插屏广告已过期: \(adStyle)")
                }
                return !isExpired
            }
        default:
            break
        }
        return false
    }
    
    /// 销毁广告对象
    func destroyAds() {
        switch adStyle.format {
        case .rewarded:
            if let ad = rewardVideoAd {
                Logger.info("[Ad] [BigoBiddingLoader] 💥 销毁 Bigo 激励视频广告: \(adStyle)")
                ad.destroy()
            }
        case .interstitial:
            if let ad = interstitialAd {
                Logger.info("[Ad] [BigoBiddingLoader] 💥 销毁 Bigo 插屏广告: \(adStyle)")
                ad.destroy()
            }
        default:
            break
        }
    }
    
    /// 获取广告竞价信息
    func getBiddingInfo() -> (price: Double, creativeId: String?) {
        switch adStyle.format {
        case .rewarded:
            if let ad = rewardVideoAd {
                let price = ad.getBid()?.getPrice() ?? 0.0
                let creativeId = ad.getCreativeId()
                return (Double(price), creativeId)
            }
        case .interstitial:
            if let ad = interstitialAd {
                let price = ad.getBid()?.getPrice() ?? 0.0
                let creativeId = ad.getCreativeId()
                return (Double(price), creativeId)
            }
        default:
            break
        }
        return (0.0, nil)
    }
}

// MARK: - 竞价结果通知
extension BigoBiddingLoader {
    
    func notifyBidWin(secondPrice: Double, secondBidder: String) {
        Logger.info("[Ad] [BigoBiddingLoader] 🏆 通知 Bigo 广告竞价获胜: \(adStyle), SecondPrice: \(secondPrice), SecondBidder: \(secondBidder)")
        
        switch adStyle.format {
        case .rewarded:
            if let ad = rewardVideoAd, let bidAd = ad.getBid() {
                bidAd.notifyWin(withSecPrice: secondPrice, secBidder: secondBidder)
                Logger.info("[Ad] [BigoBiddingLoader] ✅ Bigo 激励视频广告竞价获胜通知已发送")
            }
        case .interstitial:
            if let ad = interstitialAd, let bidAd = ad.getBid() {
                bidAd.notifyWin(withSecPrice: secondPrice, secBidder: secondBidder)
                Logger.info("[Ad] [BigoBiddingLoader] ✅ Bigo 插屏广告竞价获胜通知已发送")
            }
        default:
            break
        }
    }
    
    func notifyBidLoss(firstPrice: Double, firstBidder: String, lossReason: BiddingLossReason) {
        Logger.info("[Ad] [BigoBiddingLoader] 💔 通知 Bigo 广告竞价失败: \(adStyle), FirstPrice: \(firstPrice), FirstBidder: \(firstBidder), Reason: \(lossReason)")
        
        switch adStyle.format {
        case .rewarded:
            if let ad = rewardVideoAd, let bidAd = ad.getBid() {
                bidAd.notifyLoss(withFirstPrice: firstPrice, firstBidder: firstBidder, lossReason: lossReason.bigoReason)
                Logger.info("[Ad] [BigoBiddingLoader] ✅ Bigo 激励视频广告竞价失败通知已发送")
            }
        case .interstitial:
            if let ad = interstitialAd, let bidAd = ad.getBid() {
                bidAd.notifyLoss(withFirstPrice: firstPrice, firstBidder: firstBidder, lossReason: lossReason.bigoReason)
                Logger.info("[Ad] [BigoBiddingLoader] ✅ Bigo 插屏广告竞价失败通知已发送")
            }
        default:
            break
        }
    }
    
}

// MARK: -
extension BigoBiddingLoader {
    
    private func setupCallback() {
        callback.adStateComplete = { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .didLoad(let adSource):
                self.isLoading = false
                self.isLoaded = true
                
                if case .bigo(let wrapper) = adSource {
                    if let rewardAd = wrapper?.rewardVideoAd {
                        self.rewardVideoAd = rewardAd
                    }
                    if let interAd = wrapper?.interstitialAd {
                        self.interstitialAd = interAd
                    }
                }
                
                let loadDuration = Date().timeIntervalSince(self.loadTime ?? Date())
                Logger.info("[Ad] [BigoBiddingLoader] ✅ Bigo 广告加载成功: \(self.adStyle), 耗时: \(String(format: "%.2f", loadDuration))s")
                self.loadCompletion?(.success(adSource))
                
            case .loadFailure(let error):
                self.isLoading = false
                self.isLoaded = false
                
                let loadDuration = Date().timeIntervalSince(self.loadTime ?? Date())
                Logger.info("[Ad] [BigoBiddingLoader] ❌ Bigo 广告加载失败: \(self.adStyle), Error: \(error.localizedDescription), 耗时: \(String(format: "%.2f", loadDuration))s")
                self.loadCompletion?(.failure(error))
                
            default:
                break
            }
        }
    }
    
}
