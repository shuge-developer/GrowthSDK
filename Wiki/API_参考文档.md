# API 参考文档

面向集成方的公开 API 说明，提供 Swift 与 Objective‑C 用法示例。


## 版本与状态

### SDK 版本
```swift
// Swift
let version = GrowthKit.sdkVersion
```

### 初始化状态枚举
```swift
@objc public enum InitState: Int {
    case uninitialized  // 未初始化
    case initializing   // 初始化中
    case initialized    // 已初始化
    case failed         // 初始化失败
}
```

### 初始化错误类型（Swift）
```swift
public enum InitError: Error, LocalizedError {
    case alreadyInitialized
    case storageInitFailed(String)
    case serviceInitFailed(String)
}
```

### 核心单例与状态
```swift
// 获取单例
let kit = GrowthKit.shared

// 初始化状态（只读）
let state: InitState = kit.state
let isReady: Bool = kit.isInitialized

// 日志开关（默认 true）
GrowthKit.isLoggingEnabled = true
```

---

## 初始化接口

### Swift（async/await）
```swift
public func initialize(
    with config: NetworkConfigurable,
    launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
) async throws
```
使用示例：
```swift
struct CustomConfig: NetworkConfigurable {
    let serviceId: String = "your_service_id"
    let bundleName: String = Bundle.main.bundleIdentifier ?? ""
    let serviceUrl: String = "https://api.example.com"
    let serviceKey: String = "your_service_key"
    let serviceIv: String = "your_service_iv"
    let publicKey: String = "your_public_key"
}

Task {
    try await GrowthKit.shared.initialize(with: CustomConfig())
}
```

### Objective‑C（回调）
```objc
- (void)initializeWith:(NetworkConfig *)config
        launchOptions:(NSDictionary<UIApplicationLaunchOptionsKey, id> * _Nullable)launchOptions
          completion:(void (^ _Nullable)(NSError * _Nullable error))completion;
```
使用示例：
```objective-c
#import <GrowthSDK/GrowthSDK-Swift.h>

NetworkConfig *config = [[NetworkConfig alloc] initWithServiceId:@"your_service_id"
                                                     bundleName:[[NSBundle mainBundle] bundleIdentifier]
                                                     serviceUrl:@"https://api.example.com"
                                                     serviceKey:@"your_service_key"
                                                      serviceIv:@"your_service_iv"
                                                      publicKey:@"your_public_key"
                                                 configKeyItems:nil
                                                        thirdId:nil];
[[GrowthKit shared] initializeWith:config launchOptions:launchOptions completion:^(NSError * _Nullable error) {
    if (error) {
        NSLog(@"初始化失败: %@", error);
    } else {
        NSLog(@"初始化成功");
    }
}];
```

---

## 配置类型

### 配置键类型
```swift
@objc public enum ConfigItem: Int, Codable {
    case config   // 业务配置键
    case adjust   // Adjust 配置键
    case adUnit   // 广告单元配置键
    case link     // Link 配置键（Web 链接展示配置）
}
```

### 结构化配置键
```swift
@objc public class ConfigKeyItem: NSObject {
    @objc public let key: String
    @objc public let item: ConfigItem

    @objc public init(key: String, item: ConfigItem)

    // 便捷构造
    @objc public convenience init(configKey: String)
    @objc public convenience init(adjustKey: String)
    @objc public convenience init(adUnitKey: String)
    @objc public convenience init(linkKey: String)
}
```

### 网络配置协议（Swift）
```swift
public protocol NetworkConfigurable {
    var serviceId: String { get }
    var bundleName: String { get }
    var serviceUrl: String { get }
    var serviceKey: String { get }
    var serviceIv: String { get }
    var publicKey: String { get }

    // 可选扩展字段（默认实现返回 nil）
    var configKeyItems: [ConfigKeyItem]? { get }
    var thirdId: String? { get }
}
```

### 面向 Objective‑C 的配置体
```swift
@objcMembers
public class NetworkConfig: NSObject, NetworkConfigurable {
    public init(
        serviceId: String,
        bundleName: String,
        serviceUrl: String,
        serviceKey: String,
        serviceIv: String,
        publicKey: String,
        configKeyItems: [ConfigKeyItem]? = nil,
        thirdId: String? = nil
    )

    public let serviceId: String
    public let bundleName: String
    public let serviceUrl: String
    public let serviceKey: String
    public let serviceIv: String
    public let publicKey: String
    public let configKeyItems: [ConfigKeyItem]?
    public var thirdId: String?
}
```

> 说明：Swift 工程推荐直接实现 `NetworkConfigurable`；Objective‑C 工程使用 `NetworkConfig` 进行初始化。

---

## 广告接口

---

## Link 配置 API

用于从服务端配置中获取 Web 链接展示开关与推荐展示链接。

### Swift
```swift
// 是否允许展示 Web Link（需 SDK 完成初始化且已拉取到配置）
let canShow = GrowthKit.shared.isShowWebLink

// 推荐展示的 Web Link（需先判断 canShow 为 true）
if canShow, let url = GrowthKit.shared.webLink {
    // TODO: 展示入口或直接打开 url
}
```

### Objective‑C
```objective-c
BOOL canShow = [GrowthKit.shared isShowWebLink];
NSString * _Nullable link = [GrowthKit.shared webLink];
if (canShow && link.length > 0) {
    // 展示入口或打开 link
}
```

### 拉取配置（结构化配置键）
```swift
let config = NetworkConfig(
    serviceId: "...",
    bundleName: Bundle.main.bundleIdentifier ?? "",
    serviceUrl: "https://api.example.com",
    serviceKey: "...",
    serviceIv: "...",
    publicKey: "...",
    configKeyItems: [
        ConfigKeyItem(linkKey: "your_link_config_key")
    ]
)
```

> 注意：`isShowWebLink` 为 true 且 `webLink` 非空时才可展示；否则请隐藏相关入口。

### 广告样式枚举
```swift
@objc public enum ADStyle: Int {
    case rewarded   // 激励视频
    case inserted   // 插屏
    case appOpen    // 开屏
}
```

### 展示广告
```swift
// 静态便捷方法
GrowthKit.showAd(with: .rewarded)
GrowthKit.showAd(with: .rewarded, callbacks: adCallbacks)

// 实例方法（与上等效）
GrowthKit.shared.showAd(with: .inserted)
GrowthKit.shared.showAd(with: .inserted, callbacks: adCallbacks)
```

### 广告回调协议
```swift
@objc public protocol AdCallbacks {
    @objc optional func onStartLoading(_ style: ADStyle)
    @objc optional func onLoadSuccess(_ style: ADStyle)
    @objc optional func onLoadFailed(_ style: ADStyle, error: Error?)
    @objc optional func onShowSuccess(_ style: ADStyle)
    @objc optional func onShowFailed(_ style: ADStyle, error: Error?)
    @objc optional func onGetAdReward(_ style: ADStyle)
    @objc optional func onAdClick(_ style: ADStyle)
    @objc optional func onAdClose(_ style: ADStyle)
}
```

### 预加载与调试
```swift
// 重新加载开屏广告（需 SDK 已初始化）
GrowthKit.shared.reloadAppOpenAd()

// 重新加载竞价广告（需 SDK 已初始化）
GrowthKit.shared.reloadBiddingAd()

// 打开广告调试面板
GrowthKit.shared.showAdDebugger()
```

---

## 视图管理（Unity 集成）

以下接口用于在 iOS 应用中承载 Unity 视图与 SDK 层（需要 UIKit；如使用 SwiftUI 接口，请导入 SwiftUI）。

```swift
// 创建 SDK 宿主控制器（承载 Unity 视图 + SDK 层）
@objc static func createController(with unityController: UIViewController) -> UIViewController

// 创建 SwiftUI 视图（将 Unity 视图与 SDK 层编排到同一层级）
static func createView(with unityController: UIViewController) -> some View
```

---

## 最小可用示例

```swift
import GrowthSDK
import UIKit

struct AppConfig: NetworkConfigurable {
    let serviceId = "service_id"
    let bundleName = Bundle.main.bundleIdentifier ?? ""
    let serviceUrl = "https://api.example.com"
    let serviceKey = "key"
    let serviceIv = "iv"
    let publicKey = "public_key"
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        Task {
            try? await GrowthKit.shared.initialize(with: AppConfig())
        }
        return true
    }
}

final class AdManager: NSObject, AdCallbacks {
    func showReward() {
        GrowthKit.showAd(with: .rewarded, callbacks: self)
    }
    func onGetAdReward(_ style: ADStyle) { /* 发奖励 */ }
}
```

---

## 更多文档

如需更多示例与集成说明，请参考：
- [SDK 初始化指南](SDK_初始化指南.md)
- [广告集成指南](广告集成指南.md)
