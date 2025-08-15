# ConfigFetcher 使用指南

## 概述

`ConfigFetcher` 是一个智能的配置管理系统，能够自动推断外部传递的配置key类型，并提供类型安全的静态属性访问。

## 核心特性

1. **自动Key推断**: 根据key名称自动推断配置类型，无需手动注册
2. **静态缓存**: 提供类型安全的静态属性访问
3. **自动更新**: 网络请求成功后立即更新静态缓存
4. **缓存机制**: 支持本地缓存和过期管理
5. **零配置**: 外部调用者无需任何额外设置

## 使用步骤

### 1. 直接获取配置

只需要调用 `fetchConfigs` 方法，传入配置key数组即可：

```swift
// 自动推断key类型并获取配置
ConfigFetcher.shared.fetchConfigs(["adjust_config", "ad_unit_config"])
```

### 2. 在SDK中快速访问配置

在SDK的任意地方，都可以通过静态属性快速访问配置：

```swift
// 获取Adjust配置
if let adjustConfig = ConfigFetcher.adjustConfig {
    print("验证状态: \(adjustConfig.isVerifying)")
    print("初始化率: \(adjustConfig.initRate)")
}

// 获取广告单元配置
if let adConfig = ConfigFetcher.adUnitConfig {
    // 使用MAX广告配置
    if let maxConfig = adConfig.maxAdUnitConfig {
        let rewardedIds = maxConfig.rewardedAdIds ?? []
        print("MAX激励视频广告ID: \(rewardedIds)")
    }
    
    // 使用快手广告配置
    if let kwaiConfig = adConfig.kwaiAdUnitConfig {
        let interstitialIds = kwaiConfig.interstitialAdIds ?? []
        print("快手插屏广告ID: \(interstitialIds)")
    }
    
    // 使用Bigo广告配置
    if let bigoConfig = adConfig.bigoAdUnitConfig {
        let rewardedIds = bigoConfig.rewardedAdIds ?? []
        print("Bigo激励视频广告ID: \(rewardedIds)")
    }
    
    // 使用AdMob广告配置
    if let adMobConfig = adConfig.adMobAdUnitConfig {
        let splashIds = adMobConfig.splashAdIds ?? []
        print("AdMob开屏广告ID: \(splashIds)")
    }
}
```

## 支持的Key命名模式

### Adjust相关配置
系统会自动识别包含以下关键词的key：
- `adjust` - 如: "adjust", "adjust_config", "adjust_verify"
- `verify` - 如: "verify", "adjust_verify", "user_verify"

### 广告相关配置
系统会自动识别包含以下关键词的key：
- `ad` - 如: "ad_unit", "ad_config", "ad_settings"
- `unit` - 如: "ad_unit", "unit_config"
- `max` - 如: "max_ad", "max_config", "max_unit"
- `kwai` - 如: "kwai_ad", "kwai_config", "kwai_unit"
- `bigo` - 如: "bigo_ad", "bigo_config", "bigo_unit"
- `admob` - 如: "admob_ad", "admob_config", "admob_unit"

## 配置模型结构

### AdjustConfig
```swift
class AdjustConfig: Codable {
    var initRate: Double = 0.5
    var isLegally: Bool = true
    var force: Bool?
    var adChannel: String?
    var userId: String?
    
    var isVerifying: Bool {
        guard let force = force else { return false }
        return force == true && isLegally == true
    }
}
```

### AdUnitConfig
```swift
class AdUnitConfig: Codable {
    var abTest: String?
    var interAdIntervalSec: Int?
    var maxAdUnitConfig: MaxAdUnitConfig?
    var kwaiAdUnitConfig: KwaiAdUnitConfig?
    var bigoAdUnitConfig: BigoAdUnitConfig?
    var adMobAdUnitConfig: AdMobAdUnitConfig?
}
```

## 完整使用示例

```swift
// SDK初始化时
class SDKInitializer {
    static func initialize() {
        // 1. 加载缓存配置
        ConfigFetcher.shared.loadCachedConfigs()
        
        // 2. 获取最新配置 (自动推断key类型)
        ConfigFetcher.shared.fetchConfigs(["adjust_config", "ad_unit_config"])
    }
}

// 在广告管理器中
class AdManager {
    func loadRewardedAd() {
        guard let adConfig = ConfigFetcher.adUnitConfig else {
            print("广告配置未获取到")
            return
        }
        
        // 根据配置加载对应平台的广告
        if let maxConfig = adConfig.maxAdUnitConfig,
           let adId = maxConfig.rewardedAdIds?.first {
            loadMaxRewardedAd(adId: adId)
        }
    }
}

// 在Adjust验证中
class AdjustValidator {
    func shouldVerify() -> Bool {
        guard let adjustConfig = ConfigFetcher.adjustConfig else {
            return false
        }
        return adjustConfig.isVerifying
    }
}

// 支持各种key命名
class ConfigManager {
    func loadAllConfigs() {
        // 这些key都会被自动推断为对应的配置类型
        ConfigFetcher.shared.fetchConfigs([
            "adjust_config",      // -> AdjustConfig
            "user_verify",        // -> AdjustConfig
            "ad_unit_config",     // -> AdUnitConfig
            "max_ad_config",      // -> AdUnitConfig
            "kwai_unit",          // -> AdUnitConfig
            "bigo_ad",            // -> AdUnitConfig
            "admob_config"        // -> AdUnitConfig
        ])
    }
}
```

## 优势

1. **零配置**: 外部调用者无需任何额外设置
2. **智能推断**: 根据key名称自动推断配置类型
3. **性能**: 静态属性访问，避免重复JSON解析
4. **类型安全**: 编译时类型检查，减少运行时错误
5. **实时更新**: 网络请求成功后立即更新，无需等待下次访问
6. **缓存支持**: 本地缓存机制，离线时仍可使用
7. **易于使用**: 在SDK任意地方都可以快速访问配置
8. **灵活命名**: 支持各种key命名模式

## 注意事项

1. 系统会根据key名称自动推断配置类型
2. 无法推断的key会被忽略，不会影响其他配置的更新
3. 建议在应用启动时调用 `loadCachedConfigs()`
4. 网络请求成功后会自动更新静态缓存
5. 支持多个key映射到同一个配置类型
6. key名称不区分大小写
