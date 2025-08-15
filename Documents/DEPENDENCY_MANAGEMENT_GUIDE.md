# GrowthSDK 依赖管理指南

## 概述

GrowthSDK 采用 `internal import` 属性来隐藏内部依赖，确保下游应用不会直接访问第三方广告SDK的符号，避免符号冲突和版本兼容性问题。

## 依赖管理策略

### 1. 内部依赖隐藏

所有第三方广告SDK都使用 `internal import` 导入：

```swift
// ✅ 正确：隐藏内部依赖
internal import GoogleMobileAds
internal import AppLovinSDK
internal import KwaiAdsSDK
internal import BigoADS

// ❌ 错误：暴露依赖给使用者
import GoogleMobileAds
import AppLovinSDK
```

### 2. 依赖打包方式

GrowthSDK 使用静态链接方式打包依赖：

```ruby
# Podfile 配置
use_frameworks! :linkage => :static

pod 'AppLovinSDK'
pod 'Google-Mobile-Ads-SDK'
pod 'KwaiAdsSDK'
pod 'BigoADS'
```

这意味着：
- ✅ 所有依赖都会被编译并打包到 `GrowthSDK.xcframework` 中
- ✅ 下游应用不需要重复导入这些依赖
- ✅ 避免了符号冲突和版本兼容性问题

## 下游应用集成

### 方案一：简单集成（推荐）

下游应用只需要导入 GrowthSDK：

```ruby
# 下游应用的 Podfile
pod 'GrowthSDK'
```

**优势：**
- 零配置，开箱即用
- 自动包含所有广告SDK
- 避免版本冲突

### 方案二：自定义广告SDK

如果下游应用需要自定义广告SDK版本：

```ruby
# 下游应用的 Podfile
pod 'GrowthSDK'
pod 'AppLovinSDK', '~> 13.0'  # 指定版本
pod 'Google-Mobile-Ads-SDK', '~> 12.0'  # 指定版本
```

**注意事项：**
- 需要确保版本兼容性
- 可能出现符号冲突
- 需要额外的配置

## 技术实现细节

### 1. 符号可见性

使用 `internal import` 后：

```swift
// 在 GrowthSDK 内部
internal import GoogleMobileAds

class AdMobProvider {
    func initialize() {
        let sdk = MobileAds.shared  // ✅ 内部可以使用
    }
}

// 下游应用
import GrowthSDK

let provider = AdMobProvider()  // ✅ 可以使用我们的类
let sdk = MobileAds.shared      // ❌ 无法访问 GoogleMobileAds 的类
```

### 2. 编译时检查

`internal import` 在编译时进行检查：

- 确保依赖项不会在公共API中暴露
- 防止意外的符号泄露
- 提供更好的封装性

### 3. 运行时行为

- 依赖项仍然会被链接到最终的二进制文件中
- 运行时功能完全正常
- 只是隐藏了符号的可见性

## 最佳实践

### 1. 公共API设计

```swift
// ✅ 好的设计：通过我们自己的类型暴露功能
public class GrowthAdManager {
    public func loadRewardedAd() {
        // 内部使用第三方SDK
    }
}

// ❌ 避免：直接暴露第三方SDK类型
public class GrowthAdManager {
    public var admobAd: GADRewardedAd?  // 不要这样做
}
```

### 2. 错误处理

```swift
// ✅ 使用我们自己的错误类型
public enum GrowthAdError: Error {
    case loadFailed
    case showFailed
    case sdkNotInitialized
}

// ❌ 避免：直接暴露第三方SDK错误
public enum GrowthAdError: Error {
    case admobError(GADRequestError)  // 不要这样做
}
```

### 3. 配置管理

```swift
// ✅ 通过我们自己的配置类
public struct GrowthAdConfig {
    public let appId: String
    public let adUnitId: String
}

// ❌ 避免：直接暴露第三方SDK配置
public struct GrowthAdConfig {
    public let admobConfig: GADMobileAdsConfiguration  // 不要这样做
}
```

## 优势总结

1. **符号隔离**：避免与下游应用的依赖冲突
2. **版本控制**：SDK内部统一管理依赖版本
3. **简化集成**：下游应用无需关心内部依赖
4. **向后兼容**：内部依赖升级不影响下游应用
5. **安全性**：防止下游应用直接访问内部实现

## 注意事项

1. **编译时间**：静态链接会增加编译时间
2. **包体积**：所有依赖都会打包到SDK中
3. **调试难度**：内部依赖的调试相对复杂
4. **版本锁定**：下游应用无法选择依赖版本

## 迁移指南

如果下游应用之前直接使用了第三方SDK：

1. **移除直接依赖**：从 Podfile 中移除第三方SDK
2. **更新导入**：移除 `import GoogleMobileAds` 等
3. **使用我们的API**：通过 GrowthSDK 的公共API使用功能
4. **测试验证**：确保功能正常工作

## 技术选择说明

### 为什么选择 internal import？

GrowthSDK 选择使用 `internal import` 而不是 `@_implementationOnly import` 的原因：

1. **现代语法**：`internal import` 是 Swift 5.9+ 推荐的新语法
2. **更好的兼容性**：与 Swift 的访问控制系统更好地集成
3. **减少警告**：避免 `@_implementationOnly` 的弃用警告
4. **未来兼容**：符合 Swift 语言的发展方向

### 两种方式的对比

| 特性 | @_implementationOnly | internal import |
|------|---------------------|-----------------|
| 引入版本 | Swift 5.1+ | Swift 5.9+ |
| 严格程度 | 更严格 | 相对宽松 |
| 编译检查 | 强类型检查 | 访问控制检查 |
| 向后兼容 | 更好 | 需要新版本 |
| 推荐场景 | 严格隔离 | 现代项目 |

对于 GrowthSDK 项目，我们选择 `internal import` 因为它：
- 符合现代 Swift 开发实践
- 提供足够的符号隔离
- 减少编译警告
- 更好的长期维护性
