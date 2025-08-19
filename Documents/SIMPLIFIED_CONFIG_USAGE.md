# 简化后的配置使用示例

## 🎯 问题解决

经过简化的 `ConfigFetcher.swift` 现在更加专注，解决了以下问题：

1. **移除了向后兼容代码**：专注于结构化配置键
2. **统一了命名**：`ConfigType` → `ConfigItem`
3. **简化了实现**：只保留必要的功能
4. **修复了编译错误**：移除了不必要的依赖

## 📱 使用方式

### 在 GrowthKit 中的调用

```swift
// 在 GrowthKit.swift 中
private func initializeNetworkService(with config: NetworkConfigurable) {
    // 使用结构化配置键
    if let configKeyItems = config.configKeyItems, !configKeyItems.isEmpty {
        // 转换为 ConfigFetcher 需要的格式
        let configItems = configKeyItems.map { item in
            (key: item.key, type: ConfigItem(rawValue: item.type.rawValue) ?? .custom)
        }
        Task { 
            ConfigFetcher.shared.fetchConfigsWithKeyItems(configItems)
        }
    }
}
```

### ConfigFetcher 内部实现

```swift
// ConfigFetcher.swift 中的方法
internal final class ConfigFetcher {
    
    // 结构化配置键方式（从 GrowthKit+Config 传入）
    func fetchConfigsWithKeyItems(_ configKeyItems: [(key: String, type: ConfigItem)]) {
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

## 🔧 配置键注册

### 注册结构化配置键

```swift
// 注册结构化配置键
private static func registerConfigKeyItems(_ configKeyItems: [(key: String, type: ConfigItem)]) {
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
guard !configKeyItem.key.isEmpty else {
    print("跳过空的配置键")
    continue
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
- ✅ 移除了向后兼容代码
- ✅ 专注于结构化配置键
- ✅ 统一的命名规范

### 2. **类型安全**
- ✅ 明确的类型定义
- ✅ 编译时类型检查
- ✅ 避免字符串推断错误

### 3. **安全可靠**
- ✅ 全面的 nil 值检查
- ✅ 自动过滤无效数据
- ✅ 详细的错误日志

### 4. **易于维护**
- ✅ 清晰的代码结构
- ✅ 集中的配置管理
- ✅ 统一的日志输出

## 🚀 使用建议

### 新项目使用
```swift
// 使用结构化配置键
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

### OC 调用
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

这个简化后的实现既**解决了崩溃问题**，又**保持了代码简洁**，是一个**安全、可靠、易维护**的解决方案！
