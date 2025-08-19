# OC 兼容的 ConfigFetcher 使用指南

## 🎯 设计目标

为了解决 ConfigFetcher 的崩溃问题，同时保持 OC 兼容性，我们设计了多种调用方式：

1. **向后兼容**：保持现有的字符串数组调用方式
2. **OC 友好**：提供 OC 可以直接使用的类和方法
3. **类型安全**：使用明确的类型定义，避免字符串推断
4. **灵活扩展**：支持多种调用方式，满足不同需求

## 🏗️ 架构设计

### 1. 配置类型枚举
```swift
@objc public enum ConfigType: Int, Codable {
    case adjust = 0    // Adjust 配置
    case adUnit = 1    // 广告单元配置
    case custom = 2    // 自定义配置
}
```

### 2. 配置键类
```swift
@objc public class ConfigKey: NSObject {
    @objc public let key: String
    @objc public let type: ConfigType
    @objc public let configDescription: String?
    
    // 便利构造器
    @objc public convenience init(adjustKey: String)
    @objc public convenience init(adUnitKey: String)
    @objc public convenience init(customKey: String, description: String?)
}
```

## 📱 使用方式

### 方式1：字符串数组（向后兼容）

**Swift 调用：**
```swift
// 现有代码无需修改
let keys = ["ccs_ad_just_config", "ccs_ad_config"]
ConfigFetcher.shared.fetchConfigs(keys)
```

**OC 调用：**
```objc
// OC 调用方式
NSArray *keys = @[@"ccs_ad_just_config", @"ccs_ad_config"];
[[ConfigFetcher shared] fetchConfigs:keys];
```

### 方式2：字典数组（OC 友好）

**Swift 调用：**
```swift
let configDicts: [[String: Any]] = [
    ["key": "ccs_ad_just_config", "type": ConfigType.adjust.rawValue, "description": "Adjust配置"],
    ["key": "ccs_ad_config", "type": ConfigType.adUnit.rawValue, "description": "广告单元配置"]
]
ConfigFetcher.shared.fetchConfigsWithDicts(configDicts)
```

**OC 调用：**
```objc
// OC 调用方式
NSArray *configDicts = @[
    @{@"key": @"ccs_ad_just_config", @"type": @(0), @"description": @"Adjust配置"},
    @{@"key": @"ccs_ad_config", @"type": @(1), @"description": @"广告单元配置"}
];
[[ConfigFetcher shared] fetchConfigsWithDicts:configDicts];
```

### 方式3：ConfigKey 对象数组（Swift 推荐）

**Swift 调用：**
```swift
// 使用便利构造器
let configKeys = [
    ConfigKey(adjustKey: "ccs_ad_just_config"),
    ConfigKey(adUnitKey: "ccs_ad_config"),
    ConfigKey(customKey: "new_feature_config", description: "新功能配置")
]
ConfigFetcher.shared.fetchConfigs(configKeys)
```

**OC 调用：**
```objc
// OC 调用方式
NSArray *configKeys = @[
    [[ConfigKey alloc] initWithAdjustKey:@"ccs_ad_just_config"],
    [[ConfigKey alloc] initWithAdUnitKey:@"ccs_ad_config"],
    [[ConfigKey alloc] initWithCustomKey:@"new_feature_config" description:@"新功能配置"]
];
[[ConfigFetcher shared] fetchConfigs:configKeys];
```

## 🔧 在 GrowthKit 中的集成

### 现有代码保持不变
```swift
// GrowthKit.swift 中的调用无需修改
if let configKeys = config.configKeys, !configKeys.isEmpty {
    Task { ConfigFetcher.shared.fetchConfigs(configKeys) }
}
```

### 如果需要更精确的控制
```swift
// 使用 ConfigKey 对象，提供更好的类型安全
let configKeys = [
    ConfigKey(adjustKey: "ccs_ad_just_config"),
    ConfigKey(adUnitKey: "ccs_ad_config")
]
Task { ConfigFetcher.shared.fetchConfigs(configKeys) }
```

## 🛡️ 安全机制

### 1. nil 值检查
```swift
// 自动过滤无效的配置项
guard let id = bean.id, !id.isEmpty,
      let content = bean.jsonContent, !content.isEmpty else {
    print("[ConfigFetcher] 跳过无效的配置项")
    continue
}
```

### 2. 类型验证
```swift
// 验证配置字典的有效性
guard let key = dict["key"] as? String, !key.isEmpty,
      let typeRaw = dict["type"] as? Int,
      let type = ConfigType(rawValue: typeRaw) else {
    Logger.warning("无效的配置字典")
    return nil
}
```

### 3. 错误处理
```swift
// 详细的错误日志
Logger.warning("跳过空的配置键")
Logger.warning("未找到配置键映射: \(key)")
```

## 📊 性能优化

### 1. 缓存机制
```swift
// 保持现有的缓存机制
private let cacheExpiry: TimeInterval = 24 * 60 * 60
private var lastFetchTime: [String: TimeInterval] = [:]
```

### 2. 异步处理
```swift
// 所有网络请求都在后台队列执行
private let queue = DispatchQueue(label: "com.growthsdk.config", qos: .utility)
```

### 3. 内存管理
```swift
// 自动过滤无效键，减少内存占用
let validKeys = keys.filter { !$0.isEmpty }
```

## 🎉 优势总结

### 1. **OC 兼容性**
- ✅ 所有公开接口都支持 OC 调用
- ✅ 使用 `@objc` 标记，确保 OC 可见性
- ✅ 提供多种 OC 友好的调用方式

### 2. **向后兼容**
- ✅ 现有代码无需修改
- ✅ 保持原有的字符串数组调用方式
- ✅ 渐进式迁移，降低升级成本

### 3. **类型安全**
- ✅ 使用枚举替代字符串推断
- ✅ 明确的类型定义，减少错误
- ✅ 编译时类型检查

### 4. **灵活扩展**
- ✅ 支持自定义配置类型
- ✅ 多种调用方式满足不同需求
- ✅ 易于添加新的配置类型

### 5. **安全可靠**
- ✅ 全面的 nil 值检查
- ✅ 详细的错误日志
- ✅ 自动过滤无效数据

## 🚀 迁移建议

### 阶段1：保持现状
```swift
// 现有代码继续使用字符串数组
ConfigFetcher.shared.fetchConfigs(["ccs_ad_just_config", "ccs_ad_config"])
```

### 阶段2：逐步迁移
```swift
// 新功能使用 ConfigKey 对象
let newConfigs = [ConfigKey(adjustKey: "new_adjust_config")]
ConfigFetcher.shared.fetchConfigs(newConfigs)
```

### 阶段3：完全迁移
```swift
// 所有配置都使用 ConfigKey 对象
let allConfigs = [
    ConfigKey(adjustKey: "ccs_ad_just_config"),
    ConfigKey(adUnitKey: "ccs_ad_config")
]
ConfigFetcher.shared.fetchConfigs(allConfigs)
```

这个方案既解决了当前的崩溃问题，又为 OC 调用提供了完整的支持，是一个**安全、兼容、灵活**的解决方案！
