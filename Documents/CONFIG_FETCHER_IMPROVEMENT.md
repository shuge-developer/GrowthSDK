# ConfigFetcher 改进方案

## 🚨 问题分析

### 原始问题：
1. **nil key 崩溃**：`NSInvalidArgumentException: key cannot be nil`
2. **字符串推断不灵活**：通过字符串匹配推断配置类型容易出错
3. **无法处理新配置类型**：硬编码的推断规则难以扩展

### 崩溃原因：
```swift
// 原始代码 - 容易崩溃
for bean in response.configBeans {
    if let id = bean.id, let content = bean.jsonContent {
        configDict[id] = content  // 如果 id 为 nil，这里会崩溃
    }
}
```

## ✅ 解决方案

### 1. 配置键映射表（推荐）

**优势：**
- ✅ **明确映射**：预定义配置键到类型的映射关系
- ✅ **类型安全**：使用枚举替代字符串推断
- ✅ **易于扩展**：添加新配置只需更新映射表
- ✅ **向后兼容**：保持现有调用方式不变

**实现：**
```swift
// 预定义的配置键映射表
private static let configKeyMapping: [String: ConfigType] = [
    // Adjust 相关配置
    "ccs_ad_just_config": .adjust,
    "adjust_config": .adjust,
    "verify_config": .adjust,
    
    // 广告单元配置
    "ccs_ad_config": .adUnit,
    "ad_unit_config": .adUnit,
    "max_config": .adUnit,
    "kwai_config": .adUnit,
    "bigo_config": .adUnit,
    "admob_config": .adUnit,
]
```

### 2. 安全检查机制

**防止 nil 值崩溃：**
```swift
// 改进后的安全初始化
init(from response: ConfigResponse) {
    var configDict: [String: String] = [:]
    for bean in response.configBeans {
        // 安全检查，防止 nil 值导致崩溃
        guard let id = bean.id, !id.isEmpty,
              let content = bean.jsonContent, !content.isEmpty else {
            print("[ConfigFetcher] 跳过无效的配置项: id=\(bean.id ?? "nil"), content=\(bean.jsonContent ?? "nil")")
            continue
        }
        configDict[id] = content
    }
    self.configs = configDict
}
```

### 3. 多种调用方式

**方式1：保持现有调用（向后兼容）**
```swift
// 现有调用方式保持不变
let keys = ["ccs_ad_just_config", "ccs_ad_config"]
ConfigFetcher.shared.fetchConfigs(keys)
```

**方式2：自定义映射（灵活扩展）**
```swift
// 新增自定义映射调用方式
let customMapping: [String: ConfigType] = [
    "my_custom_config": .adjust,
    "new_ad_config": .adUnit
]
ConfigFetcher.shared.fetchConfigs(keys, customMapping: customMapping)
```

## 🎯 使用示例

### 基本使用（向后兼容）
```swift
// 在 GrowthKit.swift 中的调用保持不变
if let configKeys = config.configKeys, !configKeys.isEmpty {
    Task { ConfigFetcher.shared.fetchConfigs(configKeys) }
}
```

### 高级使用（自定义映射）
```swift
// 如果需要处理新的配置类型
let configKeys = ["ccs_ad_just_config", "ccs_ad_config", "new_feature_config"]
let customMapping: [String: ConfigType] = [
    "new_feature_config": .custom
]

ConfigFetcher.shared.fetchConfigs(configKeys, customMapping: customMapping)
```

### 配置类型扩展
```swift
// 如果需要添加新的配置类型
enum ConfigType: String, Codable {
    case adjust = "adjust"
    case adUnit = "adUnit"
    case custom = "custom"
    case feature = "feature"  // 新增类型
    case analytics = "analytics"  // 新增类型
}

// 更新映射表
private static let configKeyMapping: [String: ConfigType] = [
    // 现有映射...
    "feature_config": .feature,
    "analytics_config": .analytics,
]
```

## 🔧 改进效果

### 1. 崩溃问题解决
- ✅ **nil 值检查**：所有字典操作前都进行安全检查
- ✅ **空字符串过滤**：自动过滤无效的配置键
- ✅ **错误日志**：详细的错误信息便于调试

### 2. 灵活性提升
- ✅ **明确映射**：不再依赖字符串推断
- ✅ **类型安全**：使用枚举确保类型正确性
- ✅ **易于维护**：映射表集中管理，便于维护

### 3. 扩展性增强
- ✅ **向后兼容**：现有代码无需修改
- ✅ **自定义映射**：支持运行时添加新映射
- ✅ **类型扩展**：轻松添加新的配置类型

## 📊 性能优化

### 1. 内存安全
```swift
// 过滤无效键，减少内存占用
let validKeys = keys.filter { !$0.isEmpty }
```

### 2. 错误处理
```swift
// 详细的错误日志，便于问题定位
Logger.warning("跳过空的配置键")
Logger.warning("未找到配置键映射: \(key)")
```

### 3. 缓存优化
```swift
// 保持现有的缓存机制
private let cacheExpiry: TimeInterval = 24 * 60 * 60
private var lastFetchTime: [String: TimeInterval] = [:]
```

## 🎉 总结

新的 ConfigFetcher 实现：

1. **解决了崩溃问题**：通过全面的安全检查防止 nil 值崩溃
2. **提升了灵活性**：使用映射表替代字符串推断
3. **保持了兼容性**：现有调用方式完全不变
4. **增强了扩展性**：支持自定义映射和类型扩展
5. **改善了可维护性**：集中管理映射关系，便于维护

这个方案既解决了当前的崩溃问题，又为未来的扩展提供了良好的基础。
