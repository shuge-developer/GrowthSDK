//
//  AppOpenAdManager.swift
//  SmallGame
//
//  Created by arvin on 2025/6/26.
//

import Foundation
internal import GoogleMobileAds

// MARK: -
@MainActor
internal class AppOpenAdManager: NSObject {
    
    static let shared = AppOpenAdManager()
    
    // MARK: -
    private var appOpenAd: AppOpenAd?
    private var hasEnteredMainPage: Bool = false
    private var isAppFirstLaunch: Bool = true
    private var isLoadingAd: Bool = false
    private var isShowingAd: Bool = false
    private var backgroundTime: Date?
    private var loadTime: Date?
    
    // 冷启动广告是否已经展示过
    private var hasColdLaunchAdShown: Bool = false
    
    // 热启动最小后台时间（3秒）
    private let minimumBackgroundTime: TimeInterval = 3.0
    
    // 统一回调系统
    public var adStateComplete: AdCallback.AdLoadStateComplete?
    
    // 广告过期时间，开屏广告会在 4 小时后超时。
    // 如果广告在超过请求时间 4 小时后呈现，则相应广告将不再有效且可能无法为您创收。
    // https://developers.google.com/admob/ios/app-open?hl=zh-cn
    private let timeoutInterval: TimeInterval = 4 * 3600
    
    // 广告样式配置
    private let adStyle: AdStyle = .appOpen
    
    // 广告请求超时时间
    private var requestTimeout: TimeInterval {
        return adStyle.timeout
    }
    
    // 广告ID
    private var adUnitID: String {
        return adStyle.adId
    }
    
    // MARK: -
    private override init() {
        super.init()
        setupNotifications()
        onAppOpenAdObserver()
    }
    
    // MARK: -
    /// 异步加载开屏广告
    func loadAd() async {
        if isLoadingAd || isAdAvailable() {
            Logger.info("[Ad] [AppOpenAd] 广告已在加载中或已可用，跳过加载")
            return
        }
        guard AdMobProvider.shared.isInitialized else {
            Logger.info("[Ad] [AppOpenAd] AdMob SDK 未初始化")
            adStateComplete?(.loadFailure(.sdkNotInitialized))
            return
        }
        isLoadingAd = true
        Logger.info("[Ad] [AppOpenAd] 开始加载开屏广告，超时时间: \(requestTimeout)秒")
        do {
            let request = Request()
            let adUnitID = self.adUnitID
            appOpenAd = try await AdUtils.withTimeout(seconds: requestTimeout) {
                try await AppOpenAd.load(with: adUnitID, request: request)
            }
            appOpenAd?.fullScreenContentDelegate = self
            setupAdValueHandler(for: appOpenAd)
            loadTime = Date()
            
            Logger.info("[Ad] [AppOpenAd] 广告加载成功")
            let wrapper = AdMobAdWrapper(ad: appOpenAd!)
            let adSource = AdCallback.AdSource.admob(wrapper)
            adStateComplete?(.didLoad(adSource))
            
            if shouldShowAdImmediatelyAfterLoad() {
                Logger.info("[Ad] [AppOpenAd] 冷启动且非首次安装，立即展示广告")
                showAdIfAvailable()
            }
        } catch let error as AdError {
            appOpenAd = nil
            loadTime = nil
            
            Logger.info("[Ad] [AppOpenAd] 广告加载失败: \(error.localizedDescription)")
            adStateComplete?(.loadFailure(error))
        } catch {
            appOpenAd = nil
            loadTime = nil
            
            Logger.info("[Ad] [AppOpenAd] 广告加载失败: \(error.localizedDescription)")
            adStateComplete?(.loadFailure(.admobLoadFailed(error)))
        }
        isLoadingAd = false
    }
    
    /// 展示开屏广告（如果可用）
    func showAdIfAvailable() {
        guard canShowAd() else {
            Logger.info("[Ad] [AppOpenAd] 广告展示被阻止")
            adStateComplete?(.showFailure(.adConflictDetected))
            return
        }
        if isShowingAd {
            Logger.info("[Ad] [AppOpenAd] 广告已在展示中")
            adStateComplete?(.showFailure(.adAlreadyShowing))
            return
        }
        if !isAdAvailable() {
            Logger.info("[Ad] [AppOpenAd] 广告不可用，重新加载")
            Task { [weak self] in
                await self?.loadAd()
            }
            return
        }
        guard let ad = appOpenAd else {
            Logger.info("[Ad] [AppOpenAd] 广告对象为空")
            adStateComplete?(.showFailure(.adNotAvailable))
            return
        }
        Logger.info("[Ad] [AppOpenAd] 开始展示开屏广告")
        ad.present(from: nil)
        isShowingAd = true
        markAdStarted()
    }
    
    /// 处理热启动逻辑
    /// 应用从后台返回前台时调用
    func handleHotLaunch() {
        guard !isAppFirstLaunch else {
            Logger.info("[Ad] [AppOpenAd] 冷启动，跳过热启动逻辑")
            return
        }
        guard let backgroundTime = backgroundTime else {
            Logger.info("[Ad] [AppOpenAd] 无后台时间记录，跳过热启动逻辑")
            return
        }
        let backgroundDuration = Date().timeIntervalSince(backgroundTime)
        guard backgroundDuration >= minimumBackgroundTime else {
            Logger.info("[Ad] [AppOpenAd] 后台时间不足3秒（\(backgroundDuration)秒），跳过热启动广告")
            return
        }
        Logger.info("[Ad] [AppOpenAd] 热启动条件满足，后台时长: \(backgroundDuration)秒")
        if isAdAvailable() {
            Logger.info("[Ad] [AppOpenAd] 有缓存广告，立即展示")
            showAdIfAvailable()
        } else {
            Logger.info("[Ad] [AppOpenAd] 无缓存广告，开始预加载")
            Task { [weak self] in
                await self?.loadAd()
            }
        }
        self.backgroundTime = nil
    }
    
    /// 游戏进入主页面回调
    func onEnterMainPage() {
        Logger.info("[Ad] [AppOpenAd] 游戏进入主页面")
        hasEnteredMainPage = true
        if isAppFirstLaunch {
            hasColdLaunchAdShown = false
            isAppFirstLaunch = false
            markLaunched()
        }
    }
    
    /// 检查广告是否可用
    func isAdAvailable() -> Bool {
        guard appOpenAd != nil else { return false }
        return wasLoadTimeLessThanNHoursAgo(
            timeoutInterval
        )
    }
    
    /// 清除广告
    func clearAd() {
        if let ad = appOpenAd {
            AdValueStorage.shared.clearAdValue(for: ad)
        }
        isLoadingAd = false
        isShowingAd = false
        appOpenAd?.fullScreenContentDelegate = nil
        appOpenAd = nil
        loadTime = nil
        Logger.info("[Ad] [AppOpenAd] 广告已清除")
    }
    
}

// MARK: - FullScreenContentDelegate
extension AppOpenAdManager: FullScreenContentDelegate {
    
    /// 广告即将展示
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        if isAppFirstLaunch && !hasEnteredMainPage {
            Logger.info("[Ad] [AppOpenAd] 标记冷启动广告已展示")
            hasColdLaunchAdShown = true
        }
        let wrapper = AdMobAdWrapper(ad: ad)
        let adSource = AdCallback.AdSource.admob(wrapper)
        adStateComplete?(.didDisplay(adSource))
    }
    
    /// 广告展示失败
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        isShowingAd = false
        appOpenAd?.fullScreenContentDelegate = nil
        appOpenAd = nil
        markAdFailed()
        
        // 回调展示失败
        adStateComplete?(.showFailure(.admobShowFailed(error)))
        // 展示失败后重新加载
        Task { [weak self] in
            await self?.loadAd()
        }
    }
    
    /// 广告即将关闭
    func adWillDismissFullScreenContent(_ ad: any FullScreenPresentingAd) {
        
    }
    
    /// 广告已经关闭
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        isShowingAd = false
        appOpenAd?.fullScreenContentDelegate = nil
        appOpenAd = nil
        markAdClosed()
        
        // 回调广告关闭
        let wrapper = AdMobAdWrapper(ad: ad)
        let adSource = AdCallback.AdSource.admob(wrapper)
        adStateComplete?(.didHide(adSource))
        // 广告关闭后重新加载下一个
        Task { [weak self] in
            await self?.loadAd()
        }
    }
    
    /// 广告展示记录
    func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
        
    }
    
    /// 广告被点击
    func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        let wrapper = AdMobAdWrapper(ad: ad)
        let adSource = AdCallback.AdSource.admob(wrapper)
        adStateComplete?(.didClick(adSource))
    }
    
}

// MARK: -
extension AppOpenAdManager {
    
    /// 检查广告加载完成后是否应该立即展示
    private func shouldShowAdImmediatelyAfterLoad() -> Bool {
        guard isAppFirstLaunch else {
            return false
        }
        guard !hasEnteredMainPage else {
            return false
        }
        guard !hasColdLaunchAdShown else {
            Logger.info("[Ad] [AppOpenAd] 冷启动广告已展示过，跳过重复展示")
            return false
        }
        guard !isFirstTimeInstall() else {
            Logger.info("[Ad] [AppOpenAd] 首次安装，不展示冷启动广告")
            return false
        }
        return true
    }
    
    /// 检查广告加载时间是否在指定时间间隔内
    private func wasLoadTimeLessThanNHoursAgo(_ timeoutInterval: TimeInterval) -> Bool {
        guard let loadTime = loadTime else { return false }
        let timeElapsed = Date().timeIntervalSince(loadTime)
        if timeElapsed >= timeoutInterval {
            Logger.info("[Ad] [AppOpenAd] 广告已过期，距离加载时间: \(timeElapsed/3600)小时")
            return false
        }
        return true
    }
    
    /// 设置广告价值监听器
    /// - Parameter ad: 开屏广告对象
    private func setupAdValueHandler(for ad: AppOpenAd?) {
        ad?.paidEventHandler = { [weak ad] adValue in
            guard let ad = ad else { return }
            AdValueStorage.shared.setAdValue(
                adValue, for: ad
            )
        }
    }
    
    /// 检查是否为首次安装启动
    private func isFirstTimeInstall() -> Bool {
        let key: UserDefaults.Key = .hasLaunchedBefore
        let hasLaunchedBefore: Bool? = UserDefaults.value(for: key)
        return !(hasLaunchedBefore ?? false)
    }
    
    /// 标记应用已经启动过
    private func markLaunched() {
        let key: UserDefaults.Key = .hasLaunchedBefore
        UserDefaults.set(value: true, key: key)
    }
    
}

// MARK: -
extension AppOpenAdManager {
    
    private func createAdInfo(with adSource: AdCallback.AdSource) -> AdInfo? {
        return AdInfo.infoModel(by: adSource.adObj, adId: adUnitID)
    }
    
    /// 设置应用生命周期监听
    private func setupNotifications() {
//        LifeCycleObserver.shared.addObserver { [weak self] state in
//            guard let self = self else { return }
//            switch state {
//            case .willEnterForeground:
//                Logger.info("[Ad] [AppOpenAd] 应用即将进入前台")
//                DispatchQueue.mainAsyncAfter(delay: 0.1) {
//                    self.handleHotLaunch()
//                }
//            case .didEnterBackground:
//                Logger.info("[Ad] [AppOpenAd] 记录应用进入后台时间")
//                self.backgroundTime = Date()
//            default:
//                break
//            }
//        }
    }
    
    private func onAppOpenAdObserver() {
        adStateComplete = { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .didLoad(let adSource):
                Logger.info("[Ad] [AppOpenAd] 广告加载成功: \(adSource.description)")
                break
                
            case .loadFailure(let error):
                Logger.info("[Ad] [AppOpenAd] 广告加载失败: \(error.localizedDescription)")
//                AdThinking.adLoadFail(.appOpen, error: error)
                
            case .showFailure(let error):
                Logger.info("[Ad] [AppOpenAd] 广告展示失败: \(error.localizedDescription)")
//                AdThinking.adShowFail(error)
                
            case .didDisplay(let adSource):
                Logger.info("[Ad] [AppOpenAd] 广告开始展示: \(adSource.description)")
                let info = self.createAdInfo(with: adSource)
//                AdThinking.adShow("appOpen", info: info)
//                CallUnityProvider.onSetAudio(false)
                
            case .didClick(let adSource):
                Logger.info("[Ad] [AppOpenAd] 广告被点击: \(adSource.description)")
//                let info = self.createAdInfo(with: adSource)
//                AdThinking.adClick("appOpen", info: info)
                
            case .didHide(let adSource):
                Logger.info("[Ad] [AppOpenAd] 广告已关闭: \(adSource.description)")
                let info = self.createAdInfo(with: adSource)
//                NetworkManager.uploadAdRevenue(info)
                //AdThinking.ad_firebaseThinking(info)
//                CallUnityProvider.onSetAudio(true)
                
            case .didReward(let adSource):
                Logger.info("[Ad] [AppOpenAd] 获得奖励: \(adSource.description)")
                break
            }
        }
    }
    
}
