# GrowthSDK SDK 初始化指南

## 概述

GrowthSDK SDK 提供了一个完整的初始化入口，包括 CoreData 初始化、任务仓库初始化、自动刷新管理器启动等功能。配置请求由内部的 `RefreshManager` 和 `TaskPloysManager` 自动管理，具有复杂的业务逻辑。

## 初始化流程

### 1. 设置网络配置

首先需要设置网络配置参数：

```swift
import GrowthSDK

// 创建网络配置
let networkConfig = NetworkConfig(
    appid: "your_app_id",
    bundleName: "com.yourcompany.yourapp",
    baseUrl: "https://api.yourcompany.com",
    publicKey: "your_public_key",
    appKey: "your_app_key",
    appIv: "your_app_iv"
)

// 设置网络配置
GameWebWrapper.shared.setup(network: networkConfig)
```

### 2. 初始化 SDK

设置网络配置后，调用初始化方法：

```swift
// 初始化 SDK
GameWebWrapper.shared.initialize(configKeys: "your_config_keys") { result in
    switch result {
    case .success:
        print("SDK 初始化成功")
        // 可以开始使用 SDK 功能
        
    case .failure(let error):
        print("SDK 初始化失败: \(error.localizedDescription)")
        // 处理初始化错误
    }
}
```

### 3. 监听初始化进度（可选）

如果需要监听初始化进度，可以设置进度回调：

```swift
// 设置进度回调
GameWebWrapper.shared.onInitProgress = { message in
    print("初始化进度: \(message)")
}

// 设置完成回调
GameWebWrapper.shared.onInitComplete = { result in
    switch result {
    case .success:
        print("初始化完成")
    case .failure(let error):
        print("初始化失败: \(error)")
    }
}
```

## 配置请求机制

SDK 的配置请求由内部的 `RefreshManager` 和 `TaskPloysManager` 自动管理，具有以下特点：

### 1. 自动配置检查
- **应用启动时**：自动触发初始配置检查
- **应用进入前台时**：触发配置检查
- **任务队列清空时**：自动触发配置检查

### 2. 配置类型和策略
- **initConfig**：每日获取一次
- **cfgConfig**：复杂逻辑（任务队列为空 + 每日限制 + 时间间隔）
- **jsConfig**：只获取一次

### 3. 智能重试机制
- 网络失败时自动重试
- 支持精确间隔重试和标准重试
- 状态持久化，应用重启后恢复

### 4. 业务逻辑验证
- 每日请求次数限制
- 时间间隔验证
- 任务队列状态检查

## 完整使用示例

```swift
import GrowthSDK
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // 1. 设置网络配置
        let networkConfig = NetworkConfig(
            appid: "com.example.game",
            bundleName: "com.example.game",
            baseUrl: "https://api.example.com",
            publicKey: "your_public_key_here",
            appKey: "your_app_key_here",
            appIv: "your_app_iv_here"
        )
        
        GameWebWrapper.shared.setup(network: networkConfig)
        
        // 2. 设置初始化回调
        GameWebWrapper.shared.onInitProgress = { message in
            print("🎯 初始化进度: \(message)")
        }
        
        // 3. 初始化 SDK
        GameWebWrapper.shared.initialize(configKeys: "game_config") { result in
            switch result {
            case .success:
                print("✅ GrowthSDK SDK 初始化成功")
                print("📡 配置请求将由内部管理器自动处理")
                
            case .failure(let error):
                print("❌ GrowthSDK SDK 初始化失败: \(error.localizedDescription)")
                
                // 可以根据错误类型进行重试
                switch error {
                case .coreDataInitFailed:
                    print("CoreData 初始化失败，可能需要检查数据模型")
                case .taskRepositoryInitFailed:
                    print("任务仓库初始化失败")
                case .configNotSet:
                    print("网络配置未设置")
                }
            }
        }
        
        return true
    }
}

// 在 SwiftUI 中使用
struct ContentView: View {
    @StateObject private var gameWrapper = GameWebWrapper.shared
    
    var body: some View {
        VStack {
            if gameWrapper.isInitialized {
                Text("SDK 已初始化")
                    .foregroundColor(.green)
            } else {
                Text("SDK 初始化中...")
                    .foregroundColor(.orange)
            }
            
            // 显示初始化状态
            switch gameWrapper.initStatus {
            case .notInitialized:
                Text("未初始化")
            case .initializing:
                Text("初始化中...")
            case .initialized:
                Text("初始化完成")
            case .failed(let error):
                Text("初始化失败: \(error.localizedDescription)")
                    .foregroundColor(.red)
            }
        }
    }
}
```

## 高级功能

### 重新初始化

如果需要在运行时重新初始化 SDK：

```swift
GameWebWrapper.shared.reinitialize(configKeys: "new_config_keys") { result in
    switch result {
    case .success:
        print("SDK 重新初始化成功")
    case .failure(let error):
        print("SDK 重新初始化失败: \(error)")
    }
}
```

### 清理资源

在应用退出或需要清理 SDK 资源时：

```swift
GameWebWrapper.shared.cleanup()
```

### 状态检查

可以随时检查 SDK 的初始化状态：

```swift
if GameWebWrapper.shared.isInitialized {
    // SDK 已初始化，可以安全使用
} else {
    // SDK 未初始化，需要先初始化
}
```

## 错误处理

SDK 提供了详细的错误类型：

- `configNotSet`: 网络配置未设置
- `coreDataInitFailed`: CoreData 初始化失败
- `taskRepositoryInitFailed`: 任务仓库初始化失败

## 注意事项

1. **初始化顺序**: 必须先调用 `setup(network:)` 设置网络配置，再调用 `initialize(configKeys:)`
2. **线程安全**: 初始化方法在后台线程执行，回调在主线程返回
3. **重复初始化**: 避免重复调用初始化方法，SDK 会自动处理
4. **资源清理**: 在应用退出时调用 `cleanup()` 方法清理资源
5. **配置请求**: 配置请求由内部管理器自动处理，无需手动调用
6. **业务逻辑**: 配置请求遵循复杂的业务规则，包括时间间隔、次数限制等

## 初始化流程详解

1. **CoreData 初始化**: 初始化本地数据存储
2. **任务仓库初始化**: 加载和分类任务数据
3. **自动刷新管理器**: 启动配置自动刷新功能，包括：
   - 设置应用生命周期观察者
   - 设置任务队列观察者
   - 创建配置检查调度器
   - 触发初始配置检查

## 配置请求业务逻辑

### 触发条件
- 应用启动时
- 应用进入前台时
- 任务队列清空时

### 验证规则
- **initConfig**: 每日最多请求一次
- **cfgConfig**: 需要满足多个条件
  - 任务队列为空
  - 每日请求次数未达上限
  - 距离上次任务完成时间满足间隔要求
- **jsConfig**: 只请求一次

### 重试机制
- 网络失败时自动重试
- 支持精确间隔重试（基于业务规则）
- 状态持久化，应用重启后恢复

每个步骤都有详细的进度回调，方便调试和用户反馈。 