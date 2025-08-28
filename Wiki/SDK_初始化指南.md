# SDK 初始化指南

## 概述

GrowthSDK 的对外主入口为 `GrowthKit`。初始化时需要传入 `NetworkConfig` 配置。

## 配置参数说明

### NetworkConfig 字段

- **serviceId**: 服务/应用 ID（字符串）
- **bundleName**: 包名（通常为 `Bundle.main.bundleIdentifier`）
- **serviceUrl**: 服务基础地址（字符串）
- **serviceKey**: 服务密钥（字符串）
- **serviceIv**: 服务向量（字符串）
- **publicKey**: 公钥（字符串）
- **configKeyItems**: 结构化配置键（数组）

> 可选字段：
> - **thirdId**: 第三方 ID（可选，字符串）。

### 结构化配置键

如需通过结构化配置驱动 SDK 内部的配置拉取，可传入 `configKeyItems`：

```swift
let configKeys: [ConfigKeyItem] = [
    .init(configKey: "your_config_key"),
    .init(adjustKey: "your_adjust_key"),
    .init(adUnitKey: "your_adunit_key")
]
```

## 初始化示例

### Swift · UIKit · async/await

使用 `NetworkConfigurable` 自定义配置并在 `AppDelegate` 中使用 `async/await` 初始化：

```swift
import UIKit
import GrowthSDK

struct CustomNetworkConfig: NetworkConfigurable {
    let serviceId: String = "your_service_id"
    let bundleName: String = "com.example.app"
    let serviceUrl: String = "https://api.example.com"
    let publicKey: String = "your_public_key"
    let serviceKey: String = "your_service_key"
    let serviceIv: String = "your_service_iv"
    var configKeyItems: [ConfigKeyItem]? {
        [
            ConfigKeyItem(adjustKey: "your_adjust_key"),
            ConfigKeyItem(configKey: "your_config_key"),
            ConfigKeyItem(adUnitKey: "your_adunit_key")
        ]
    }
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Task {
            do {
                try await GrowthKit.shared.initialize(with: CustomNetworkConfig())
                print("SDK 初始化成功")
            } catch {
                print("SDK 初始化失败: \(error)")
            }
        }
        return true
    }
}
```

### Objective-C · UIKit

在 `AppDelegate` 中通过回调方式初始化。注意引入自动生成的 Swift 头文件：`#import <GrowthSDK/GrowthSDK-Swift.h>`。

```objective-c
// AppDelegate.m
#import <GrowthSDK/GrowthSDK-Swift.h>

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self initializeGrowthKitSDK:launchOptions];
    return YES;
}

- (void)initializeGrowthKitSDK:(NSDictionary *)launchOptions {
    NSArray<ConfigKeyItem *> *configKeys = @[
        [[ConfigKeyItem alloc] initWithAdjustKey:@"your_adjust_key"],
        [[ConfigKeyItem alloc] initWithConfigKey:@"your_config_key"],
        [[ConfigKeyItem alloc] initWithAdUnitKey:@"your_adunit_key"]
    ];

    NetworkConfig *config = [[NetworkConfig alloc] initWithServiceId:@"your_service_id"
                                                         bundleName:@"com.example.app"
                                                         serviceUrl:@"https://api.example.com"
                                                         serviceKey:@"your_service_key"
                                                          serviceIv:@"your_service_iv"
                                                          publicKey:@"your_public_key"
                                                     configKeyItems:configKeys
                                                            thirdId:nil];

    [[GrowthKit shared] initializeWith:config launchOptions:launchOptions completion:^(NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                NSLog(@"SDK 初始化失败: %@", error.localizedDescription);
            } else {
                NSLog(@"SDK 初始化成功");
            }
        });
    }];
}
```

### SwiftUI · @UIApplicationDelegateAdaptor

通过 `@UIApplicationDelegateAdaptor` 适配 `AppDelegate` 并在启动时初始化：

```swift
import SwiftUI
import GrowthSDK
import UIKit

struct CustomNetworkConfig: NetworkConfigurable {
    let serviceId: String = "your_service_id"
    let bundleName: String = "com.example.app"
    let serviceUrl: String = "https://api.example.com"
    let publicKey: String = "your_public_key"
    let serviceKey: String = "your_service_key"
    let serviceIv: String = "your_service_iv"
    var configKeyItems: [ConfigKeyItem]? {
        [
            ConfigKeyItem(adjustKey: "your_adjust_key"),
            ConfigKeyItem(configKey: "your_config_key"),
            ConfigKeyItem(adUnitKey: "your_adunit_key")
        ]
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        Task {
            do {
                try await GrowthKit.shared.initialize(with: CustomNetworkConfig())
                print("SDK 初始化成功")
            } catch {
                print("SDK 初始化失败: \(error)")
            }
        }
        return true
    }
}

@main
struct YourApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

## 初始化状态检查

### 检查初始化状态

```swift
// 查询 SDK 初始化状态
let isReady = GrowthKit.shared.isInitialized

// 查询 SDK 当前状态
let state = GrowthKit.shared.state
// InitState.uninitialized  - 未初始化
// InitState.initializing   - 初始化中  
// InitState.initialized    - 已初始化
// InitState.failed         - 初始化失败
```

### 版本信息

```swift
// 获取 SDK 版本号
let version = GrowthKit.sdkVersion
```

## 错误处理

### 初始化错误类型

```swift
do {
    try await GrowthKit.shared.initialize(with: config)
    print("SDK 初始化成功")
} catch let error as InitError {
    switch error {
    case .alreadyInitialized:
        print("SDK 已经初始化")
    case .storageInitFailed(let message):
        print("存储初始化失败: \(message)")
    case .serviceInitFailed(let message):
        print("服务初始化失败: \(message)")
    }
} catch {
    print("未知错误: \(error)")
}
```

## 最佳实践

### 1. 配置管理

- 将配置信息集中管理，便于维护和更新
- 使用环境变量或配置文件存储敏感信息
- 避免在代码中硬编码配置值

### 2. 错误处理

- 始终处理初始化错误
- 提供用户友好的错误提示
- 记录详细的错误日志用于调试

### 3. 初始化时机

- 在应用启动时尽早初始化 SDK
- 确保在需要使用 SDK 功能之前完成初始化
- 避免在后台线程中初始化

### 4. 配置验证

- 验证所有必需的配置参数
- 检查网络连接状态
- 确保配置格式正确

## 相关文档

- [SDK 集成指南](SDK_集成指南.md) - 集成步骤和配置
- [API 参考文档](API_参考文档.md) - 完整的 API 接口
