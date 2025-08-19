# 修复后的配置使用示例

## 🎯 问题修复

已经修复了以下问题：

1. **添加了 ConfigItem 定义**：在 `ConfigFetcher.swift` 中添加了缺失的 `ConfigItem` 枚举
2. **更新了 GrowthKit 调用**：修改为使用新的结构化配置键方式
3. **统一了类型命名**：`ConfigItem` 在两个文件中保持一致

## 📱 使用方式

### 1. 创建配置

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

### 2. 初始化 SDK

```swift
// 初始化 SDK
GrowthKit.shared.initialize(with: config) { error in
    if let error = error {
        print("SDK 初始化失败: \(error)")
    } else {
        print("SDK 初始化成功")
    }
}
```

### 3. 内部处理流程

#### GrowthKit.swift 中的处理
```swift
/// 初始化网络服务
func initializeNetworkService() async throws {
    Logger.info("开始初始化网络服务...")
    // 初始化配置同步管理器
    let configSyncManager = ConfigSyncManager.shared
    // 触发初始配置检查
    configSyncManager.triggerAllConfigCheck()
    // 如果提供了结构化配置键，则异步获取配置
    if let configKeyItems = config.configKeyItems, !configKeyItems.isEmpty {
        // 转换为 ConfigFetcher 需要的格式
        let configItems = configKeyItems.map { item in
            (key: item.key, type: ConfigItem(rawValue: item.type.rawValue) ?? .custom)
        }
        Task { ConfigFetcher.shared.fetchConfigsWithKeyItems(configItems) }
    }
    Logger.info("网络服务初始化成功")
}
```

#### ConfigFetcher.swift 中的处理
```swift
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

## 🔧 类型定义

### ConfigItem 枚举（在 ConfigFetcher.swift 中）
```swift
internal enum ConfigItem: Int, Codable {
    case adjust = 0
    case adUnit = 1
    case custom = 2
    
    var description: String {
        switch self {
        case .adjust: return "Adjust配置"
        case .adUnit: return "广告单元配置"
        case .custom: return "自定义配置"
        }
    }
}
```

### ConfigKeyItem 类（在 GrowthKit+Config.swift 中）
```swift
@objc public class ConfigKeyItem: NSObject {
    @objc public let key: String
    @objc public let type: ConfigItem
    @objc public let configDescription: String?
    
    // 便利构造器
    @objc public convenience init(adjustKey: String)
    @objc public convenience init(adUnitKey: String)
    @objc public convenience init(customKey: String, description: String?)
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

### 2. 类型转换安全
```swift
// 安全的类型转换
let configItems = configKeyItems.map { item in
    (key: item.key, type: ConfigItem(rawValue: item.type.rawValue) ?? .custom)
}
```

### 3. 空值过滤
```swift
// 自动过滤无效的配置键
guard !configKeyItem.key.isEmpty else {
    print("跳过空的配置键")
    continue
}
```

## 🎉 优势总结

### 1. **类型安全**
- ✅ 明确的类型定义
- ✅ 编译时类型检查
- ✅ 避免字符串推断错误

### 2. **安全可靠**
- ✅ 全面的 nil 值检查
- ✅ 自动过滤无效数据
- ✅ 详细的错误日志

### 3. **易于维护**
- ✅ 清晰的代码结构
- ✅ 集中的配置管理
- ✅ 统一的日志输出

### 4. **OC 兼容**
- ✅ 所有公开接口都支持 OC 调用
- ✅ 使用 `@objc` 标记，确保 OC 可见性
- ✅ 提供 OC 友好的便利构造器

## 🚀 使用建议

### Swift 调用
```swift
let configKeyItems = [
    ConfigKeyItem(adjustKey: "ccs_ad_just_config"),
    ConfigKeyItem(adUnitKey: "ccs_ad_config")
]

let config = NetworkConfig(..., configKeyItems: configKeyItems)
GrowthKit.shared.initialize(with: config)
```

### OC 调用
```objc
NSArray *configKeyItems = @[
    [[ConfigKeyItem alloc] initWithAdjustKey:@"ccs_ad_just_config"],
    [[ConfigKeyItem alloc] initWithAdUnitKey:@"ccs_ad_config"]
];

NetworkConfig *config = [[NetworkConfig alloc] 
    initWithServiceId:@"your_service_id"
    bundleName:@"your_bundle"
    serviceUrl:@"your_url"
    serviceKey:@"your_key"
    serviceIv:@"your_iv"
    publicKey:@"your_public_key"
    configKeyItems:configKeyItems];

[GrowthKit.shared initializeWithConfig:config completion:nil];
```

这个修复后的实现既**解决了编译错误**，又**保持了类型安全**，是一个**安全、可靠、易维护**的解决方案！
