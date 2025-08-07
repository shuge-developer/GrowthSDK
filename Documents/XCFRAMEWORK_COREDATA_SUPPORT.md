# XCFramework CoreData 支持说明

## 问题

当 SDK 打包成 XCFramework 后，CoreData 模型文件的路径会发生变化，需要特殊处理。

## 解决方案

### 1. 智能模型文件查找

`CoreDataManager` 已实现多层次的模型文件查找：

```swift
private func findCoreDataModel() -> URL? {
    // 1. 从当前 Bundle 查找
    if let bundle = Bundle(for: type(of: self)) {
        if let momdURL = bundle.url(forResource: "GrowthKit", withExtension: "momd") {
            return momdURL
        }
    }
    
    // 2. 从主 Bundle 查找
    if let mainBundle = Bundle.main {
        if let momdURL = mainBundle.url(forResource: "GrowthKit", withExtension: "momd") {
            return momdURL
        }
    }
    
    // 3. 从所有 Bundle 查找
    let allBundles = Bundle.allBundles + Bundle.allFrameworks
    for bundle in allBundles {
        if let momdURL = bundle.url(forResource: "GrowthKit", withExtension: "momd") {
            return momdURL
        }
    }
    
    return nil
}
```

### 2. 自定义存储位置

使用应用的 Documents 目录：

```swift
private func getStorageDirectory() -> URL {
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let storageDirectory = documentsPath.appendingPathComponent("GrowthKit")
    
    if !FileManager.default.fileExists(atPath: storageDirectory.path) {
        try? FileManager.default.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
    }
    
    return storageDirectory
}
```

### 3. 增强的容器配置

```swift
private func configureContainer(_ container: NSPersistentContainer) {
    let storeDescription = NSPersistentStoreDescription()
    let storageDirectory = getStorageDirectory()
    let storeURL = storageDirectory.appendingPathComponent("GrowthKit.sqlite")
    
    storeDescription.url = storeURL
    storeDescription.type = NSSQLiteStoreType
    
    // 启用迁移
    storeDescription.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
    storeDescription.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
    
    container.persistentStoreDescriptions = [storeDescription]
}
```

## 构建要求

1. 确保 `GrowthKit.xcdatamodeld` 被添加到 Framework 的 Bundle Resources
2. 确保模型文件会被编译成 `.momd` 文件
3. 确保模型文件属于 Framework target

## 使用方式

使用方式保持不变，CoreData 会自动处理：

```swift
GameWebWrapper.shared.initialize { result in
    // CoreData 会自动初始化
}
```

## 数据存储位置

```
~/Documents/GrowthKit/GrowthKit.sqlite
```

## 调试日志

SDK 会输出详细的初始化日志，便于调试：

```
[CoreData] 🔍 从当前 Bundle 查找模型文件
[CoreData] ✅ 找到 .momd 文件
[CoreData] 📁 创建存储目录
[CoreData] ✅ 持久化存储加载成功
``` 