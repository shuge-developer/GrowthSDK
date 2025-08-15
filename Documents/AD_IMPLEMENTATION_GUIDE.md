# GrowthSDK 广告模块实现指南

## 实现概述

已经完成了GrowthSDK的广告初始化和竞价广告预加载逻辑的实现，主要包含以下功能：

### 1. 广告SDK初始化 (GrowthKit.swift)

```swift
/// 初始化广告SDK
func initializeAdSDKs() async throws {
    Logger.info("开始初始化广告SDK...")
    
    // 使用AdLoadProvider来启动所有广告SDK
    await MainActor.run {
        AdLoadProvider.startup()
    }
    
    // 等待广告SDK初始化完成
    let maxWaitTime: TimeInterval = 10.0 // 最大等待10秒
    let checkInterval: TimeInterval = 0.1
    let maxAttempts = Int(maxWaitTime / checkInterval)
    
    for attempt in 0..<maxAttempts {
        if AdsInitProvider.allInitialized {
            Logger.info("所有广告SDK初始化完成")
            return
        }
        try await Task.sleep(nanoseconds: UInt64(checkInterval * 1_000_000_000))
    }
    
    Logger.warning("广告SDK初始化超时，但继续执行")
}
```

### 2. 竞价广告预加载 (GrowthKit.swift)

```swift
/// 预加载竞价广告
func preloadBiddingAds() async {
    Logger.info("开始预加载竞价广告...")
    
    await MainActor.run {
        // 检查是否所有广告SDK都已初始化
        if AdsInitProvider.allInitialized {
            AdBiddingManager.shared.preloadAllAds()
            Logger.info("竞价广告预加载已启动")
        } else {
            Logger.warning("部分广告SDK未初始化完成，跳过预加载")
        }
    }
}
```

### 3. 广告状态检查方法

```swift
extension GrowthKit {
    
    /// 检查广告SDK是否已初始化
    @objc public var isAdSDKInitialized: Bool {
        return AdsInitProvider.allInitialized
    }
    
    /// 手动重新预加载竞价广告
    @objc public func reloadBiddingAds() {
        guard isInitialized && isAdSDKInitialized else {
            Logger.warning("未初始化完成，无法重新加载竞价广告")
            return
        }
        
        Task { @MainActor in
            AdBiddingManager.shared.preloadAllAds()
            Logger.info("手动重新加载竞价广告")
        }
    }
    
    /// 获取广告初始化状态
    @objc public func getAdInitializationStatus() -> [String: Bool] {
        return [
            "AdMob": AdMobProvider.shared.isInitialized,
            "Bigo": BigoAdProvider.shared.isInitialized,
            "Kwai": KwaiAdProvider.shared.isInitialized,
            "Max": MaxAdProvider.shared.isInitialized
        ]
    }
}
```

### 4. 广告展示接口 (GrowthKit+Ads.swift)

```swift
extension GrowthKit {
    
    /// 展示激励广告
    private func showRewardedAd(callbacks: AdCallbacks?) async {
        Logger.info("展示激励广告")
        
        let biddingCallbacks = createBiddingCallbacks(from: callbacks)
        await MainActor.run {
            AdBiddingManager.shared.showAd(type: BiddingType.rewarded, adCallbacks: biddingCallbacks)
        }
    }
    
    /// 展示插屏广告
    private func showInterstitialAd(callbacks: AdCallbacks?) async {
        Logger.info("展示插屏广告")
        
        let biddingCallbacks = createBiddingCallbacks(from: callbacks)
        await MainActor.run {
            AdBiddingManager.shared.showAd(type: BiddingType.interstitial, adCallbacks: biddingCallbacks)
        }
    }
    
    /// 展示开屏广告
    private func showAppOpenAd(callbacks: AdCallbacks?) {
        Logger.info("展示开屏广告")
        
        let appOpenManager = AppOpenAdManager.shared
        
        // 设置回调
        if let callbacks = callbacks {
            appOpenManager.adStateComplete = { [weak self] state in
                self?.handleAppOpenAdState(state, callbacks: callbacks)
            }
        }
        
        appOpenManager.showAdIfAvailable()
    }
}
```

## SDK 初始化流程

```swift
public func initialize(with config: NetworkConfigurable) async throws {
    guard state == .uninitialized else {
        throw InitError.alreadyInitialized
    }
    state = .initializing
    do {
        // 1. 保存配置
        self.config = config
        // 2. 初始化 CoreData
        try await initializeCoreData()
        // 3. 初始化任务服务
        try await initializeTaskService()
        // 4. 初始化网络服务
        try await initializeNetworkService()
        // 5. 初始化广告 SDK
        try await initializeAdSDKs()
        // 6. 预加载竞价广告
        await preloadBiddingAds()
        // 7. 完成初始化
        state = .initialized
        Logger.info("SDK 初始化成功")
    } catch {
        state = .failed
        Logger.error("SDK 初始化失败: \(error)")
        throw error
    }
}
```

## 使用示例

### 1. 基本使用

```swift
// 初始化SDK
let config = NetworkConfig(/* 配置参数 */)
GrowthKit.shared.initialize(with: config) { error in
    if let error = error {
        print("SDK初始化失败: \(error)")
    } else {
        print("SDK初始化成功")
        
        // 检查广告SDK状态
        let adStatus = GrowthKit.shared.getAdInitializationStatus()
        print("广告SDK状态: \(adStatus)")
        
        // 展示广告
        GrowthKit.showAd(with: .rewarded)
    }
}
```

### 2. 带回调的广告展示

```swift
class AdManager: AdCallbacks {
    
    func showRewardedVideo() {
        // 检查SDK状态
        guard GrowthKit.shared.isInitialized && GrowthKit.shared.isAdSDKInitialized else {
            print("SDK或广告SDK未初始化完成")
            return
        }
        
        GrowthKit.showAd(with: .rewarded, callbacks: self)
    }
    
    // MARK: - AdCallbacks
    
    func onStartLoading() {
        print("开始加载广告")
    }
    
    func onLoadSuccess() {
        print("广告加载成功")
    }
    
    func onShowSuccess() {
        print("广告展示成功")
    }
    
    func onGetReward() {
        print("获得奖励")
        // 发放奖励给用户
    }
    
    func onClose() {
        print("广告关闭")
    }
}
```

### 3. 手动管理广告预加载

```swift
// 检查广告预加载状态
if GrowthKit.shared.isAdSDKInitialized {
    // 手动重新预加载
    GrowthKit.shared.reloadBiddingAds()
}
```

## 架构特点

1. **异步初始化**: 广告SDK初始化采用异步方式，不阻塞主线程
2. **状态检查**: 提供完整的初始化状态检查机制
3. **容错处理**: 即使部分广告SDK初始化失败也不影响整体功能
4. **预加载机制**: 自动预加载竞价广告，提高展示速度
5. **回调系统**: 完整的广告生命周期回调
6. **多平台支持**: 支持AdMob、Bigo、Kwai、Max等多个广告平台

## 注意事项

1. 确保在SDK完全初始化后再调用广告展示方法
2. 广告SDK初始化可能需要一定时间，建议检查`isAdSDKInitialized`状态
3. 竞价广告预加载是自动的，也可以手动触发重新加载
4. 开屏广告使用单独的管理器，不参与竞价系统
5. 所有广告展示都会记录详细日志，便于调试

## 错误处理

SDK提供了完整的错误处理机制：

- `InitError.alreadyInitialized`: SDK已经初始化
- `InitError.storageInitFailed`: CoreData初始化失败  
- `InitError.serviceInitFailed`: 任务服务初始化失败

广告相关错误会通过AdCallbacks回调返回给调用方。
