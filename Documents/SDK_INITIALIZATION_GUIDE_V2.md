# GrowthKit SDK 初始化指南 V2

## 概述

GrowthKit SDK 提供了一个完整的初始化入口，包括 CoreData 初始化、任务仓库初始化、自动刷新管理器启动等功能。**配置请求由内部的 `RefreshManager` 和 `TaskPloysManager` 自动管理**，具有复杂的业务逻辑。

## 初始化流程

### 1. 设置网络配置
```swift
let networkConfig = NetworkConfig(
    appid: "your_app_id",
    bundleName: "com.yourcompany.yourapp",
    baseUrl: "https://api.yourcompany.com",
    publicKey: "your_public_key",
    appKey: "your_app_key",
    appIv: "your_app_iv"
)

GameWebWrapper.shared.setup(network: networkConfig)
```

### 2. 初始化 SDK
```swift
GameWebWrapper.shared.initialize { result in
    switch result {
    case .success:
        print("SDK 初始化成功")
    case .failure(let error):
        print("SDK 初始化失败: \(error.localizedDescription)")
    }
}
```

## 配置请求机制

### 自动管理
- **应用启动时**：自动触发初始配置检查
- **应用进入前台时**：触发配置检查
- **任务队列清空时**：自动触发配置检查

### 配置类型和策略
- **initConfig**：每日获取一次
- **cfgConfig**：复杂逻辑（任务队列为空 + 每日限制 + 时间间隔）
- **jsConfig**：只获取一次

### 智能重试机制
- 网络失败时自动重试
- 支持精确间隔重试和标准重试
- 状态持久化，应用重启后恢复

## 初始化步骤详解

1. **CoreData 初始化**: 初始化本地数据存储
2. **任务仓库初始化**: 加载和分类任务数据
3. **自动刷新管理器**: 启动配置自动刷新功能，包括：
   - 设置应用生命周期观察者
   - 设置任务队列观察者
   - 创建配置检查调度器
   - 触发初始配置检查

## 错误处理

- `configNotSet`: 网络配置未设置
- `coreDataInitFailed`: CoreData 初始化失败
- `taskRepositoryInitFailed`: 任务仓库初始化失败

## 注意事项

1. **配置请求由内部管理**: 无需手动调用网络请求，由 `RefreshManager` 自动处理
2. **业务逻辑复杂**: 配置请求遵循复杂的业务规则，包括时间间隔、次数限制等
3. **状态持久化**: 重试状态会持久化，应用重启后恢复
4. **线程安全**: 初始化在后台线程执行，回调在主线程返回 