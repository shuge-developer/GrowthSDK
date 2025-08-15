# GrowthSDK 运行时广告集成指南

## 概述

GrowthSDK 现在支持**运行时广告 SDK 检查**，解决了编译时条件判断 `#if canImport()` 导致的依赖问题。下游 APP 可以自由选择需要集成的广告 SDK，GrowthSDK 会在运行时动态检查并使用可用的 SDK。

## 核心原理

### 问题背景
- **编译时条件判断**：`#if canImport(FrameworkB)` 在打包 framework 时就确定结果
- **硬导入依赖**：`import GoogleMobileAds` 会在编译时强制要求依赖存在
- **下游无法选择**：即使下游 APP 集成了依赖，SDK 中的条件判断已经固化

### 解决方案
- **运行时检查**：使用 `NSClassFromString()` 动态检查类是否存在
- **弱链接配置**：通过 CocoaPods 配置弱依赖关系
- **动态代理调用**：使用反射和消息转发实现对可选依赖的安全调用

## 集成方式

### 1. 基础集成（仅核心功能）

```ruby
# Podfile
pod 'GrowthSDK', :subspecs => ['Core']
```

此时 GrowthSDK 可以正常工作，但广告功能会被跳过。

### 2. 完整广告集成

```ruby
# Podfile
pod 'GrowthSDK', :subspecs => ['Core', 'AdsDeps']
```

这会自动下载以下依赖：
- AppLovinSDK (~> 12.0)
- GoogleMobileAds (~> 11.0)
- KwaiAdsSDK (~> 3.0)
- BigoADS (~> 4.0)
- 以及所有 AppLovin 聚合适配器

### 3. 部分广告集成

```ruby
# Podfile - 只集成 Google 和 AppLovin
pod 'GrowthSDK', :subspecs => ['Core']
pod 'AppLovinSDK', '~> 12.0'
pod 'GoogleMobileAds', '~> 11.0'
```

GrowthSDK 会自动检测并只使用可用的 SDK。

## 使用方法

### 1. 基本初始化

```swift
import GrowthSDK

// 启动广告 SDK（自动检测可用性）
AdLoadProvider.startup()

// 或者手动控制初始化
AdsInitProvider.startup { adType in
    print("广告 SDK 初始化完成: \(adType)")
}
```

### 2. 检查可用性

```swift
// 检查 SDK 可用性
let availability = AdSDKAvailability.shared
print("可用的广告 SDK: \(availability.availableSDKs)")
print("GoogleMobileAds 可用: \(availability.isGoogleMobileAdsAvailable)")

// 获取详细状态报告
let report = AdsInitProvider.getStatusReport()
print("初始化报告: \(report)")
```

### 3. 调试和监控

```swift
// 打印详细状态
AdsInitProvider.printStatus()

// 显示 AppLovin 调试器（如果可用）
AdsInitProvider.showDebugger()

// 检查初始化状态
if AdsInitProvider.allInitialized {
    print("所有可用的广告 SDK 都已初始化完成")
}
```

## 技术实现详情

### 1. SDK 可用性检查

```swift
class AdSDKAvailability {
    var isGoogleMobileAdsAvailable: Bool {
        return NSClassFromString("GADMobileAds") != nil
    }
    
    var isAppLovinSDKAvailable: Bool {
        return NSClassFromString("ALSdk") != nil
    }
    
    // ... 其他 SDK 检查
}
```

### 2. 动态代理调用

```swift
class AdSDKDynamicProxy {
    func createGoogleMobileAdsInstance() -> AnyObject? {
        guard let gadMobileAdsClass = NSClassFromString("GADMobileAds") as? NSObject.Type else {
            return nil
        }
        return gadMobileAdsClass.perform(Selector("sharedInstance"))?.takeUnretainedValue()
    }
    
    func safePerform(target: AnyObject, selector: Selector, arguments: [Any] = []) -> Any? {
        guard target.responds(to: selector) else { return nil }
        return target.perform(selector)?.takeUnretainedValue()
    }
}
```

### 3. 弱链接配置

```ruby
# GrowthSDK.podspec
s.subspec 'AdsDeps' do |ads|
  ads.dependency 'AppLovinSDK', '~> 12.0'
  ads.dependency 'GoogleMobileAds', '~> 11.0'
  
  # 弱链接配置
  ads.weak_frameworks = 'AppLovinSDK', 'GoogleMobileAds'
  ads.pod_target_xcconfig = {
    'OTHER_LDFLAGS' => '$(inherited) -weak_framework AppLovinSDK -weak_framework GoogleMobileAds'
  }
end
```

## 运行时行为

### 场景 1：完整集成
- 所有 4 个广告 SDK 都可用
- GrowthSDK 初始化所有 SDK
- 广告功能完全可用

### 场景 2：部分集成
- 只集成了 GoogleMobileAds 和 AppLovinSDK
- GrowthSDK 跳过 KwaiAdsSDK 和 BigoADS
- 使用可用的 SDK 提供广告服务

### 场景 3：无广告集成
- 没有集成任何广告 SDK
- GrowthSDK 跳过所有广告相关功能
- 其他功能正常工作

## 日志输出示例

```
=== 广告 SDK 可用性状态 ===
GoogleMobileAds: ✅
AppLovinSDK: ✅
KwaiAdsSDK: ❌
BigoADS: ❌
可用 SDK 数量: 2
可用 SDK 列表: GoogleMobileAds, AppLovinSDK
========================

[Ad] 开始初始化 GoogleMobileAds
[Ad] 开始初始化 AppLovinSDK
[Ad] KwaiAdsSDK 不可用，跳过初始化
[Ad] BigoADS SDK 不可用，跳过初始化
[Ad] admob sdk 初始化完成
[Ad] max sdk 初始化完成
[Ad] 所有可用广告 SDK 初始化完成
```

## 优势

1. **灵活性**：下游 APP 可以自由选择需要的广告 SDK
2. **向后兼容**：现有代码无需修改
3. **减少包体积**：只集成需要的 SDK
4. **运行时适应**：自动适应不同的集成场景
5. **调试友好**：提供详细的状态检查和日志

## 注意事项

1. **方法签名一致性**：动态调用要求方法签名与原 SDK 完全一致
2. **错误处理**：所有动态调用都有安全检查和降级处理
3. **性能影响**：运行时反射有轻微性能开销，但在可接受范围内
4. **测试覆盖**：需要测试各种集成组合的场景

## 迁移指南

### 从硬导入迁移到运行时检查

**之前（硬导入）：**
```swift
import GoogleMobileAds

func initialize() {
    let sdk = MobileAds.shared
    sdk.start { status in
        // 处理完成
    }
}
```

**现在（运行时检查）：**
```swift
// 无需导入

func initialize() {
    guard AdSDKAvailability.shared.isGoogleMobileAdsAvailable else {
        return // 跳过初始化
    }
    
    let proxy = AdSDKDynamicProxy.shared
    guard let mobileAds = proxy.createGoogleMobileAdsInstance() else {
        return
    }
    
    // 动态调用
    let selector = Selector("startWithCompletionHandler:")
    let completionBlock: @convention(block) (AnyObject?) -> Void = { status in
        // 处理完成
    }
    _ = proxy.safePerform(target: mobileAds, selector: selector, arguments: [completionBlock])
}
```

这种方式确保了 SDK 的最大兼容性和灵活性，是 iOS SDK 开发中处理可选依赖的最佳实践。
