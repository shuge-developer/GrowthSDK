# ConfigKeys 传递问题解决方案

## 🎯 问题分析

### 原始问题：
- `GrowthKit+Config.swift` 中的 `configKeys: [String]?` 传递字符串数组
- `ConfigFetcher` 需要通过字符串推断来确定配置类型
- 字符串推断容易出错，导致崩溃：`NSInvalidArgumentException: key cannot be nil`

### 根本原因：
```swift
// 原始方式 - 容易出错
let configKeys = ["ccs_ad_just_config", "ccs_ad_config"]
// ConfigFetcher 需要通过字符串匹配来推断类型
// 如果字符串格式不匹配或为空，就会崩溃
```

## ✅ 解决方案

### 1. 结构化配置键（推荐）

**在 `GrowthKit+Config.swift` 中新增：**

```swift
// 配置键类型枚举
@objc public enum ConfigKeyType: Int, Codable {
    case adjust = 0
    case adUnit = 1
    case custom = 2
}

// 配置键结构
@objc public class ConfigKeyItem: NSObject {
    @objc public let key: String
    @objc public let type: ConfigKeyType
    @objc public let configDescription: String?
    
    // 便利构造器
    @objc public convenience init(adjustKey: String)
    @objc public convenience init(adUnitKey: String)
    @objc public convenience init(customKey: String, description: String?)
}
```

### 2. 向后兼容的配置协议

```swift
public protocol NetworkConfigurable {
    // 向后兼容：字符串数组方式
    var configKeys: [String]? { get }
    
    // 新增：结构化配置键方式
    var configKeyItems: [ConfigKeyItem]? { get }
}
```

### 3. 多种初始化方式

```swift
@objcMembers
public class NetworkConfig: NSObject, NetworkConfigurable {
    
    // 向后兼容的初始化方法
    public init(serviceId: String, ..., configKeys: [String]? = nil, ...)
    
    // 新增：结构化配置键的初始化方法
    public init(serviceId: String, ..., configKeyItems: [ConfigKeyItem]? = nil, ...)
}
```

## 📱 使用方式

### 方式1：向后兼容（现有代码无需修改）

**Swift 调用：**
```swift
// 现有代码保持不变
let config = NetworkConfig(
    serviceId: "your_service_id",
    bundleName: "your_bundle",
    serviceUrl: "your_url",
    serviceKey: "your_key",
    serviceIv: "your_iv",
    publicKey: "your_public_key",
    configKeys: ["ccs_ad_just_config", "ccs_ad_config"]
)
```

**OC 调用：**
```objc
// OC 调用方式保持不变
NetworkConfig *config = [[NetworkConfig alloc] 
    initWithServiceId:@"your_service_id"
    bundleName:@"your_bundle"
    serviceUrl:@"your_url"
    serviceKey:@"your_key"
    serviceIv:@"your_iv"
    publicKey:@"your_public_key"
    configKeys:@[@"ccs_ad_just_config", @"ccs_ad_config"]];
```

### 方式2：结构化配置键（推荐新项目使用）

**Swift 调用：**
```swift
// 使用结构化配置键，类型安全
let configKeyItems = [
    ConfigKeyItem(adjustKey: "ccs_ad_just_config"),
    ConfigKeyItem(adUnitKey: "ccs_ad_config"),
    ConfigKeyItem(customKey: "new_feature_config", description: "新功能配置")
]

let config = NetworkConfig(
    serviceId: "your_service_id",
    bundleName: "your_bundle",
    serviceUrl: "your_url",
    serviceKey: "your_key",
    serviceIv: "your_iv",
    publicKey: "your_public_key",
    configKeyItems: configKeyItems
)
```

**OC 调用：**
```objc
// OC 调用方式
NSArray *configKeyItems = @[
    [[ConfigKeyItem alloc] initWithAdjustKey:@"ccs_ad_just_config"],
    [[ConfigKeyItem alloc] initWithAdUnitKey:@"ccs_ad_config"],
    [[ConfigKeyItem alloc] initWithCustomKey:@"new_feature_config" description:@"新功能配置"]
];

NetworkConfig *config = [[NetworkConfig alloc] 
    initWithServiceId:@"your_service_id"
    bundleName:@"your_bundle"
    serviceUrl:@"your_url"
    serviceKey:@"your_key"
    serviceIv:@"your_iv"
    publicKey:@"your_public_key"
    configKeyItems:configKeyItems];
```

## 🔧 在 GrowthKit 中的处理

### 修改 GrowthKit 的配置处理逻辑

```swift
// 在 GrowthKit.swift 中
private func initializeNetworkService(with config: NetworkConfigurable) {
    // 优先使用结构化配置键
    if let configKeyItems = config.configKeyItems, !configKeyItems.isEmpty {
        // 使用结构化配置键，类型安全
        Task { 
            ConfigFetcher.shared.fetchConfigsWithKeyItems(configKeyItems)
        }
    } else if let configKeys = config.configKeys, !configKeys.isEmpty {
        // 向后兼容：使用字符串数组
        Task { 
            ConfigFetcher.shared.fetchConfigs(configKeys)
        }
    }
}
```

### ConfigFetcher 中的处理

```swift
// 在 ConfigFetcher.swift 中新增方法
internal func fetchConfigsWithKeyItems(_ configKeyItems: [ConfigKeyItem]) {
    Logger.info("开始获取配置(ConfigKeyItem数组): \(configKeyItems.map { $0.key })")
    
    // 注册配置键映射
    ConfigFetcher.registerConfigKeyItems(configKeyItems)
    
    // 提取键值
    let keys = configKeyItems.map { $0.key }
    
    // 开始异步配置请求
    queue.async { [weak self] in
        self?.performFetch(keys)
    }
}
```

## 🛡️ 安全机制

### 1. 类型安全
```swift
// 明确的类型定义，避免字符串推断
ConfigKeyItem(adjustKey: "ccs_ad_just_config")  // 明确是 Adjust 类型
ConfigKeyItem(adUnitKey: "ccs_ad_config")       // 明确是广告单元类型
```

### 2. 空值检查
```swift
// 自动过滤无效的配置项
guard !configKeyItem.key.isEmpty else {
    Logger.warning("跳过空的配置键")
    continue
}
```

### 3. 错误处理
```swift
// 详细的错误日志
Logger.warning("未找到配置键映射: \(key)")
Logger.info("注册配置键: \(key) -> \(type.description)")
```

## 🎉 优势总结

### 1. **类型安全**
- ✅ 明确的类型定义，避免字符串推断
- ✅ 编译时类型检查，减少运行时错误
- ✅ 自动补全和代码提示

### 2. **向后兼容**
- ✅ 现有代码无需修改
- ✅ 渐进式迁移，降低升级成本
- ✅ 支持两种方式并存

### 3. **OC 兼容**
- ✅ 所有新增接口都支持 OC 调用
- ✅ 使用 `@objc` 标记，确保 OC 可见性
- ✅ 提供 OC 友好的便利构造器

### 4. **易于维护**
- ✅ 集中管理配置类型
- ✅ 清晰的代码结构
- ✅ 详细的错误日志

### 5. **灵活扩展**
- ✅ 轻松添加新的配置类型
- ✅ 支持自定义配置描述
- ✅ 多种初始化方式

## 🚀 迁移建议

### 阶段1：保持现状
```swift
// 现有代码继续使用字符串数组
let config = NetworkConfig(..., configKeys: ["ccs_ad_just_config", "ccs_ad_config"])
```

### 阶段2：逐步迁移
```swift
// 新功能使用结构化配置键
let configKeyItems = [
    ConfigKeyItem(adjustKey: "ccs_ad_just_config"),
    ConfigKeyItem(adUnitKey: "ccs_ad_config")
]
let config = NetworkConfig(..., configKeyItems: configKeyItems)
```

### 阶段3：完全迁移
```swift
// 所有配置都使用结构化配置键
let allConfigKeyItems = [
    ConfigKeyItem(adjustKey: "ccs_ad_just_config"),
    ConfigKeyItem(adUnitKey: "ccs_ad_config"),
    ConfigKeyItem(customKey: "new_feature_config", description: "新功能配置")
]
let config = NetworkConfig(..., configKeyItems: allConfigKeyItems)
```

这个方案既**解决了当前的崩溃问题**，又**保持了向后兼容性**，同时为**OC 调用提供了完整支持**，是一个**安全、兼容、灵活**的解决方案！
