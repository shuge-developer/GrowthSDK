# ConfigFetcher 使用示例

## 🎯 问题解决

经过清理后的 `ConfigFetcher.swift` 现在更加简洁，解决了以下问题：

1. **移除了重复代码**：删除了不必要的 OC 兼容接口
2. **简化了实现**：专注于内部使用，不需要对外暴露
3. **修复了类型引用**：使用元组替代复杂的对象引用
4. **统一了日志**：使用 `print` 替代 `Logger`

## 📱 使用方式

### 在 GrowthKit 中的调用

```swift
// 在 GrowthKit.swift 中
private func initializeNetworkService(with config: NetworkConfigurable) {
    // 优先使用结构化配置键
    if let configKeyItems = config.configKeyItems, !configKeyItems.isEmpty {
        // 转换为 ConfigFetcher 需要的格式
        let configItems = configKeyItems.map { item in
            (key: item.key, type: ConfigType(rawValue: item.type.rawValue) ?? .custom)
        }
        Task { 
            ConfigFetcher.shared.fetchConfigsWithKeyItems(configItems)
        }
    } else if let configKeys = config.configKeys, !configKeys.isEmpty {
        // 向后兼容：使用字符串数组
        Task { 
            ConfigFetcher.shared.fetchConfigs(configKeys)
        }
    }
}
```

### ConfigFetcher 内部实现

```swift
// ConfigFetcher.swift 中的方法
internal final class ConfigFetcher {
    
    // 字符串数组方式（向后兼容）
    func fetchConfigs(_ keys: [String]) {
        print("开始获取配置(字符串数组): \(keys)")
        
        // 安全检查 keys
        let validKeys = keys.filter { !$0.isEmpty }
        guard !validKeys.isEmpty else {
            print("没有有效的配置键")
            return
        }
        
        // 自动注册配置键映射
        ConfigFetcher.autoRegisterConfig(validKeys)
        // 开始异步配置请求
        queue.async { [weak self] in
            self?.performFetch(validKeys)
        }
    }
    
    // 结构化配置键方式（从 GrowthKit+Config 传入）
    func fetchConfigsWithKeyItems(_ configKeyItems: [(key: String, type: ConfigType)]) {
        print("开始获取配置(结构化配置键): \(configKeyItems.map { $0.key })")
        
        // 注册配置键映射
        ConfigFetcher.registerConfigKeyItems(configKeyItems)
        
        // 提取键值
        let keys = configKeyItems.map { $0.key }
        
        // 开始异步配置请求
        queue.async { [weak self] in
            self?.performFetch(keys)
        }
    }
}
```

## 🔧 配置键映射

### 预定义映射表

```swift
// ConfigFetcher.swift 中的预定义映射
private static let legacyKeyMapping: [String: ConfigType] = [
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

### 自动注册逻辑

```swift
// 字符串数组方式的自动注册
private static func autoRegisterConfig(_ keys: [String]) {
    for key in keys {
        guard !key.isEmpty else {
            print("跳过空的配置键")
            continue
        }
        
        if keyMapping[key] == nil {
            if let configType = legacyKeyMapping[key] {
                print("从预定义映射注册配置键: \(key) -> \(configType.description)")
                keyMapping[key] = configType
            } else {
                print("未找到配置键映射，使用默认类型: \(key)")
                keyMapping[key] = .custom
            }
        }
    }
}

// 结构化配置键的注册
private static func registerConfigKeyItems(_ configKeyItems: [(key: String, type: ConfigType)]) {
    for configKeyItem in configKeyItems {
        guard !configKeyItem.key.isEmpty else {
            print("跳过空的配置键")
            continue
        }
        keyMapping[configKeyItem.key] = configKeyItem.type
        print("注册配置键: \(configKeyItem.key) -> \(configKeyItem.type.description)")
    }
}
```

## 🛡️ 安全机制

### 1. nil 值检查

```swift
// ConfigData 初始化时的安全检查
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

### 2. 空字符串过滤

```swift
// 自动过滤无效的配置键
let validKeys = keys.filter { !$0.isEmpty }
guard !validKeys.isEmpty else {
    print("没有有效的配置键")
    return
}
```

### 3. 配置更新时的安全检查

```swift
// 更新静态配置时的安全检查
private func updateStaticConfigs(_ configData: ConfigData) {
    for (key, json) in configData.configs {
        // 安全检查 key 和 json 是否为空
        guard !key.isEmpty, !json.isEmpty else {
            print("跳过空的配置: key=\(key), json=\(json)")
            continue
        }
        
        guard let configType = ConfigFetcher.keyMapping[key] else {
            print("未找到配置键映射: \(key)")
            continue
        }
        
        // 根据类型处理配置
        switch configType {
        case .adjust:
            if let adjustConfig = AdjustConfig.deserialize(from: json) {
                adjustConfig.adChannel = configData.extendJson?.adChannel
                adjustConfig.userId = configData.extendJson?.userId
                ConfigFetcher.adjustConfig = adjustConfig
                print("AdjustConfig 已更新 (key: \(key))")
            }
        case .adUnit:
            if let adUnitConfig = AdUnitConfig.deserialize(from: json) {
                ConfigFetcher.adUnitConfig = adUnitConfig
                print("AdUnitConfig 已更新 (key: \(key))")
            }
        case .custom:
            print("自定义配置类型，跳过处理: \(key)")
        }
    }
}
```

## 🎉 优势总结

### 1. **代码简洁**
- ✅ 移除了重复的 OC 兼容代码
- ✅ 专注于内部使用，接口更清晰
- ✅ 使用元组替代复杂对象引用

### 2. **类型安全**
- ✅ 明确的类型定义
- ✅ 编译时类型检查
- ✅ 避免字符串推断错误

### 3. **向后兼容**
- ✅ 保持字符串数组调用方式
- ✅ 现有代码无需修改
- ✅ 渐进式迁移支持

### 4. **安全可靠**
- ✅ 全面的 nil 值检查
- ✅ 自动过滤无效数据
- ✅ 详细的错误日志

### 5. **易于维护**
- ✅ 清晰的代码结构
- ✅ 集中的配置管理
- ✅ 统一的日志输出

## 🚀 使用建议

### 现有项目
```swift
// 继续使用字符串数组方式
let config = NetworkConfig(..., configKeys: ["ccs_ad_just_config", "ccs_ad_config"])
```

### 新项目
```swift
// 使用结构化配置键
let configKeyItems = [
    ConfigKeyItem(adjustKey: "ccs_ad_just_config"),
    ConfigKeyItem(adUnitKey: "ccs_ad_config")
]
let config = NetworkConfig(..., configKeyItems: configKeyItems)
```

这个清理后的实现既**解决了崩溃问题**，又**保持了代码简洁**，是一个**安全、可靠、易维护**的解决方案！
