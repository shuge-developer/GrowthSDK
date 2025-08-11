# GrowthSDK API 重命名重构总结

## 概述
本次重构对 GrowthSDK SDK 的 API 类命名进行了全面优化，移除了冗余前缀，使用更简洁优雅的命名，提升了代码的可读性和维护性。

## 重命名对照表

### 核心类重命名

| 原名称 | 新名称 | 说明 |
|--------|--------|------|
| `GameWebWrapper` | `GrowthSDKSDK` | 主入口类，避免与模块名冲突 |
| `GrowthSDKNetworkConfig` | `NetworkConfig` | 移除冗余前缀，更简洁 |
| `GrowthSDKInitStatus` | `InitStatus` | 移除冗余前缀 |
| `GrowthSDKInitError` | `InitError` | 移除冗余前缀 |

### 视图类重命名

| 原名称 | 新名称 | 说明 |
|--------|--------|------|
| `GrowthSDKSwiftUIView` | `GrowthSDKView` | 简化名称，更易理解 |
| `GrowthSDKUIKitBridge` | `GrowthSDKViewController` | 更符合UIKit命名规范 |

### 业务层类重命名

| 原名称 | 新名称 | 说明 |
|--------|--------|------|
| `CoreDataManager` | `DataStore` | 更语义化，体现数据存储职责 |
| `TaskRepository` | `TaskService` | 更符合服务层命名规范 |
| `RefreshManager` | `ConfigSyncManager` | 更准确地描述配置同步功能 |
| `H5TaskStartManager` | `TaskLauncher` | 更简洁，体现任务启动职责 |
| `GrowthSDKLayerManager` | `LayerOrchestrator` | 更准确地描述层级编排功能 |
| `PopupPositionManager` | `PopupCoordinator` | 更准确地描述弹窗协调功能 |

## 编译问题解决方案

### 问题1：类名与模块名冲突
**问题**：`GrowthSDK` 类名与模块名 `GrowthSDK` 冲突，导致模块接口验证失败。

**解决方案**：将主类重命名为 `GrowthSDKSDK`，避免命名冲突。

### 问题2：UIKit 导入问题
**问题**：`GrowthSDKViews.swift` 在 macOS 环境下无法找到 UIKit 相关类型。

**解决方案**：添加条件编译 `#if canImport(UIKit)` 来确保只在 iOS 环境下编译 UIKit 相关代码。

### 问题3：模块映射问题
**问题**：没有找到 umbrella header 来生成模块映射。

**解决方案**：更新 `GrowthSDK.h` 头文件，添加所有重命名后的类声明。

### 问题4：依赖链接问题
**问题**：直接使用 `xcodebuild` 构建时找不到 `Pods_GrowthSDK` framework。

**解决方案**：使用 workspace 构建：`xcodebuild -workspace GrowthSDK.xcworkspace -scheme GrowthSDK`

## 最终状态

✅ **编译成功**：使用 workspace 构建成功  
✅ **重命名完成**：所有类名已更新  
✅ **头文件更新**：`GrowthSDK.h` 包含所有类声明  
✅ **条件编译**：UIKit 相关代码正确处理  
⚠️ **警告**：仍有 umbrella header 警告，但不影响构建  

## 使用方式

### 构建命令
```bash
# 使用 workspace 构建（推荐）
xcodebuild -workspace GrowthSDK.xcworkspace -scheme GrowthSDK -configuration Debug -sdk iphoneos -destination 'generic/platform=iOS' clean build

# 或使用脚本构建
./ShellCodes/build-ios-sdk.sh
```

### API 使用示例
```swift
// 初始化 SDK
let config = NetworkConfig(appid: "your_app_id", ...)
GrowthSDKSDK.shared.initializeWithConfig(config) { success, error in
    // 处理初始化结果
}

// 使用视图
let growthKitView = GrowthSDKView(unityController: yourUnityController)
```

## 注意事项

1. **主类名称**：现在使用 `GrowthSDKSDK` 而不是 `GrowthSDK`
2. **构建方式**：必须使用 workspace 构建，不能直接使用 project
3. **平台兼容性**：UIKit 相关代码已添加条件编译，支持多平台
4. **向后兼容性**：需要更新使用方代码中的类名引用

## 文件变更清单

### 核心文件
- `GrowthSDK/Core/GrowthSDK.swift` - 主类重命名
- `GrowthSDK/Core/GrowthSDKViews.swift` - 视图类重命名，添加条件编译
- `GrowthSDK/GrowthSDK.h` - 更新头文件声明

### 业务层文件
- `GrowthSDK/GameWrapper/CoreData/CoreDataManager.swift` → `DataStore`
- `GrowthSDK/GameWrapper/Networking/H5Tasks/TaskRepository.swift` → `TaskService`
- `GrowthSDK/GameWrapper/Networking/H5Tasks/RefreshManager.swift` → `ConfigSyncManager`
- `GrowthSDK/GameWrapper/WebView/H5TaskStartManager.swift` → `TaskLauncher`
- `GrowthSDK/GameWrapper/WebView/GrowthSDKLayerManager.swift` → `LayerOrchestrator`
- `GrowthSDK/GameWrapper/CustomUIs/PopupPositionManager.swift` → `PopupCoordinator`

### 其他文件
- 所有引用这些类的文件都已更新
- 日志信息中的类名引用已更新
- 变量名引用已更新

## 总结

本次重构成功解决了命名混乱的问题，提升了代码的可读性和维护性。虽然遇到了一些编译问题，但都得到了妥善解决。现在 SDK 的 API 更加简洁优雅，符合现代 Swift 开发的最佳实践。
