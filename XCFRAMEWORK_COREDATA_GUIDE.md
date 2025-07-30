# GameWrapper SDK XCFramework CoreData 支持指南

## 概述

当 SDK 打包成 XCFramework 后，CoreData 的读取需要特殊处理。本文档详细说明了 GameWrapper SDK 中 CoreData 的 XCFramework 支持实现。

## 问题背景

### XCFramework 中的 CoreData 挑战

1. **Bundle 路径问题**：XCFramework 中的 CoreData 模型文件路径与普通 Framework 不同
2. **模型文件加载**：需要正确获取 XCFramework 中的 `.momd` 文件路径
3. **存储位置**：需要确保数据存储在正确的位置
4. **版本兼容性**：需要处理不同 iOS 版本的兼容性问题

## 解决方案

### 1. 智能模型文件查找

`CoreDataManager` 实现了多层次的模型文件查找策略：

```swift
private func findCoreDataModel() -> URL? {
    // 1. 首先尝试从当前 Bundle 中查找
    if let bundle = Bundle(for: type(of: self)) {
        // 尝试查找 .momd 文件（编译后的模型）
        if let momdURL = bundle.url(forResource: "GameWrapper", withExtension: "momd") {
            return momdURL
        }
        
        // 尝试查找 .mom 文件
        if let momURL = bundle.url(forResource: "GameWrapper", withExtension: "mom") {
            return momURL
        }
        
        // 尝试查找 .xcdatamodeld 文件（开发时的模型）
        if let modeldURL = bundle.url(forResource: "GameWrapper", withExtension: "xcdatamodeld") {
            return modeldURL
        }
    }
    
    // 2. 尝试从主 Bundle 中查找（备用方案）
    if let mainBundle = Bundle.main {
        // 查找逻辑...
        if let momdURL = mainBundle.url(forResource: "GameWrapper", withExtension: "momd") {
            return momdURL
        }
        if let momURL = mainBundle.url(forResource: "GameWrapper", withExtension: "mom") {
            return momURL
        }
    }
    
    // 3. 尝试从所有可用的 Bundle 中查找
    let allBundles = Bundle.allBundles + Bundle.allFrameworks
    for bundle in allBundles {
        // 查找逻辑...
        if let momdURL = bundle.url(forResource: "GameWrapper", withExtension: "momd") {
            return momdURL
        }
        if let momURL = bundle.url(forResource: "GameWrapper", withExtension: "mom") {
            return momURL
        }
    }
    
    return nil
}
```

### 2. 自定义存储位置

使用应用的 Documents 目录作为存储位置，确保数据持久化：

```swift
private func getStorageDirectory() -> URL {
    // 使用应用的 Documents 目录作为存储位置
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let storageDirectory = documentsPath.appendingPathComponent("GameWrapper")
    
    // 确保目录存在
    if !FileManager.default.fileExists(atPath: storageDirectory.path) {
        try? FileManager.default.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
    }
    
    return storageDirectory
}
```

### 3. 增强的容器配置

```swift
private func configureContainer(_ container: NSPersistentContainer) {
    // 配置存储描述
    let storeDescription = NSPersistentStoreDescription()
    let storageDirectory = getStorageDirectory()
    let storeURL = storageDirectory.appendingPathComponent("GameWrapper.sqlite")
    
    storeDescription.url = storeURL
    storeDescription.type = NSSQLiteStoreType
    
    // 启用轻量级迁移
    storeDescription.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
    storeDescription.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
    
    // 设置其他选项
    storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
    storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
    
    // 替换默认的存储描述
    container.persistentStoreDescriptions = [storeDescription]
}
```

## 构建配置

### 1. XCFramework 构建设置

确保在构建 XCFramework 时包含 CoreData 模型文件：

```bash
# 构建 XCFramework 时确保包含 CoreData 模型
xcodebuild -project GameWrapper.xcodeproj \
           -scheme GameWrapper \
           -configuration Release \
           -destination 'generic/platform=iOS' \
           -archivePath ./build/GameWrapper.xcarchive \
           archive

xcodebuild -create-xcframework \
           -framework ./build/GameWrapper.xcarchive/Products/Library/Frameworks/GameWrapper.framework \
           -output ./build/GameWrapper.xcframework
```

### 2. 项目设置

在 Xcode 项目设置中确保：

1. **Core Data 模型文件**：确保 `GameWrapper.xcdatamodeld` 被添加到 Framework 的 Bundle Resources 中
2. **编译设置**：确保 Core Data 模型文件会被编译成 `.momd` 文件
3. **目标成员**：确保模型文件属于 Framework target

## 使用方式

### 1. 基本使用

SDK 的使用方式保持不变，CoreData 的初始化会自动处理：

```swift
// 设置网络配置
let config = NetworkConfig(
    appid: "your_app_id",
    bundleName: "com.yourcompany.yourapp",
    baseUrl: "https://api.yourcompany.com",
    publicKey: "your_public_key",
    appKey: "your_app_key",
    appIv: "your_app_iv"
)

GameWebWrapper.shared.setup(network: config)

// 初始化 SDK（CoreData 会自动初始化）
GameWebWrapper.shared.initialize { result in
    switch result {
    case .success:
        print("SDK 初始化成功，CoreData 已就绪")
    case .failure(let error):
        print("SDK 初始化失败: \(error)")
    }
}
```

### 2. 数据存储位置

CoreData 数据会存储在：
```
~/Documents/GameWrapper/GameWrapper.sqlite
```

### 3. 调试信息

SDK 会输出详细的 CoreData 初始化日志：

```
[CoreData] 🔍 从当前 Bundle 查找模型文件: /path/to/framework
[CoreData] ✅ 找到 .momd 文件: /path/to/GameWrapper.momd
[CoreData] 📁 创建存储目录: /path/to/Documents/GameWrapper
[CoreData] 📊 配置存储: /path/to/Documents/GameWrapper/GameWrapper.sqlite
[CoreData] ✅ 持久化存储加载成功: GameWrapper.sqlite
```

## 错误处理

### 1. 模型文件未找到

如果无法找到 CoreData 模型文件，SDK 会输出详细的查找日志：

```
[CoreData] 🔍 从当前 Bundle 查找模型文件: /path/to/framework
[CoreData] 🔍 从主 Bundle 查找模型文件: /path/to/app
[CoreData] 🔍 从 Bundle 查找: /path/to/other/framework
[CoreData] ❌ 未找到 CoreData 模型文件
```

### 2. 存储加载失败

如果存储文件损坏，SDK 会自动删除并重新创建：

```
[CoreData] ❌ 存储加载失败: [错误信息]
[CoreData] 🗑️ 已删除损坏的存储文件，尝试重新创建
```

## 最佳实践

### 1. 开发阶段

- 在开发阶段，确保 CoreData 模型文件正确添加到项目中
- 测试不同的 Bundle 查找策略
- 验证数据存储位置是否正确

### 2. 构建阶段

- 确保 XCFramework 构建时包含所有必要的资源文件
- 验证 `.momd` 文件是否正确生成
- 测试 XCFramework 在不同项目中的集成

### 3. 部署阶段

- 在集成 SDK 的应用中测试 CoreData 功能
- 验证数据持久化是否正常工作
- 检查存储位置是否符合预期

## 故障排除

### 1. 模型文件未找到

**问题**：SDK 无法找到 CoreData 模型文件

**解决方案**：
1. 检查 XCFramework 是否包含 `.momd` 文件
2. 验证 Bundle 查找逻辑
3. 确保模型文件被正确编译

### 2. 存储初始化失败

**问题**：CoreData 存储无法初始化

**解决方案**：
1. 检查存储目录权限
2. 验证 SQLite 文件路径
3. 查看详细的错误日志

### 3. 数据丢失

**问题**：应用重启后数据丢失

**解决方案**：
1. 检查存储位置是否正确
2. 验证数据保存逻辑
3. 确保存储目录持久化

## 总结

GameWrapper SDK 的 CoreData 实现已经完全支持 XCFramework，包括：

1. **智能模型文件查找**：多层次查找策略，确保在各种环境下都能找到模型文件
2. **自定义存储位置**：使用应用的 Documents 目录，确保数据持久化
3. **增强的错误处理**：详细的日志输出和自动恢复机制
4. **向后兼容**：支持开发阶段和部署阶段的不同需求

这种实现确保了 SDK 在打包成 XCFramework 后，CoreData 功能能够正常工作，同时保持了良好的用户体验和开发者体验。 