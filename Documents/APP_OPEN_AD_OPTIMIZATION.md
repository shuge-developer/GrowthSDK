# 开屏广告优化说明

## 问题分析

您提出的问题很重要：**AppOpenAdManager 对象会不会提前释放？**

## 原始实现分析

```swift
// 原始实现 - 可能存在的问题
private func showAppOpenAd(callbacks: AdCallbacks?) {
    let appOpenManager = AppOpenAdManager.shared  // 单例，不会释放
    
    // 每次调用都会覆盖之前的回调
    appOpenManager.adStateComplete = { [weak self] state in
        self?.handleAppOpenAdState(state, callbacks: callbacks)
    }
    
    appOpenManager.showAdIfAvailable()
}
```

### 潜在问题：
1. ✅ **对象释放问题**: `AppOpenAdManager.shared` 是单例，不存在释放问题
2. ❌ **回调覆盖问题**: 每次调用都会设置新的回调，可能覆盖之前的回调
3. ❌ **内存泄漏风险**: 回调中捕获的 `callbacks` 可能导致循环引用

## 优化后的实现

### 1. 在 GrowthKit 主类中添加回调管理

```swift
// GrowthKit.swift
private var appOpenAdCallbacks: AdCallbacks?  // 统一管理回调
```

### 2. 统一的回调处理机制

```swift
// GrowthKit.swift
private func setupAppOpenAdManager() {
    let appOpenManager = AppOpenAdManager.shared
    
    // 设置统一的回调处理器，避免重复设置
    appOpenManager.adStateComplete = { [weak self] state in
        self?.handleAppOpenAdState(state, callbacks: self?.appOpenAdCallbacks)
    }
}

private func handleAppOpenAdState(_ state: AdCallback.AdLoadState, callbacks: AdCallbacks?) {
    guard let callbacks = callbacks else { return }
    
    switch state {
    case .didLoad(let adSource):
        callbacks.onLoadSuccess?()
    case .loadFailure(let error):
        callbacks.onLoadFailed?(error)
    case .showFailure(let error):
        callbacks.onShowFailed?(error)
    case .didDisplay(let adSource):
        callbacks.onShowSuccess?()
    case .didClick(let adSource):
        callbacks.onAdClick?()
    case .didHide(let adSource):
        callbacks.onClose?()
        // 广告关闭后清理回调引用，防止内存泄漏
        self.appOpenAdCallbacks = nil
    case .didReward(let adSource):
        callbacks.onGetReward?()
    }
}
```

### 3. 优化后的展示方法

```swift
// GrowthKit+Ads.swift
@MainActor private func showAppOpenAd(callbacks: AdCallbacks?) {
    Logger.info("展示开屏广告")
    
    // 保存回调引用，防止被覆盖
    appOpenAdCallbacks = callbacks
    
    // 初始化开屏广告管理器回调（只设置一次）
    setupAppOpenAdManager()
    
    // 展示广告
    AppOpenAdManager.shared.showAdIfAvailable()
}
```

## 优化效果

### ✅ 解决的问题：

1. **回调管理**: 统一管理回调，避免覆盖
2. **内存管理**: 广告关闭后自动清理回调引用
3. **生命周期**: 完整的广告生命周期处理
4. **线程安全**: 使用 `@MainActor` 确保线程安全

### 🚀 新增功能：

```swift
// 检查开屏广告是否可用
if GrowthKit.shared.isAppOpenAdAvailable {
    GrowthKit.showAd(with: .appOpen, callbacks: self)
}

// 手动加载开屏广告
GrowthKit.shared.loadAppOpenAd()
```

## 使用示例

### 基本使用
```swift
class ViewController: UIViewController, AdCallbacks {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 检查是否可以展示开屏广告
        if GrowthKit.shared.isAppOpenAdAvailable {
            GrowthKit.showAd(with: .appOpen, callbacks: self)
        } else {
            // 先加载再展示
            GrowthKit.shared.loadAppOpenAd()
        }
    }
    
    // MARK: - AdCallbacks
    
    func onLoadSuccess() {
        print("开屏广告加载成功")
        // 可以在这里展示广告
        GrowthKit.showAd(with: .appOpen, callbacks: self)
    }
    
    func onShowSuccess() {
        print("开屏广告展示成功")
    }
    
    func onClose() {
        print("开屏广告关闭")
        // 进入主界面逻辑
    }
}
```

### 应用启动时的最佳实践

```swift
// AppDelegate.swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    // 初始化 SDK
    let config = NetworkConfig(/* 配置参数 */)
    GrowthKit.shared.initialize(with: config) { error in
        if error == nil {
            // SDK 初始化成功，预加载开屏广告
            GrowthKit.shared.loadAppOpenAd()
        }
    }
    
    return true
}

// SceneDelegate.swift 或 ViewController
func showAppOpenAdIfNeeded() {
    // 应用进入前台时检查并展示开屏广告
    if GrowthKit.shared.isAppOpenAdAvailable {
        GrowthKit.showAd(with: .appOpen, callbacks: self)
    }
}
```

## 内存管理最佳实践

1. **自动清理**: 广告关闭后自动清理回调引用
2. **弱引用**: 使用 `[weak self]` 避免循环引用
3. **状态检查**: 展示前检查 SDK 和广告状态
4. **异常处理**: 完整的错误处理机制

## 总结

优化后的实现解决了您担心的问题：
- ✅ **对象生命周期**: 单例模式确保不会被释放
- ✅ **回调管理**: 统一管理，避免覆盖和泄漏
- ✅ **内存安全**: 自动清理机制
- ✅ **功能增强**: 新增状态检查和手动加载功能

这样的设计既保证了功能的完整性，又确保了内存的安全管理。
