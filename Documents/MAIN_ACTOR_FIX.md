# MainActor 线程隔离修复

## 问题描述

在 `GrowthKit.swift` 中的 `isAppOpenAdAvailable` 属性报错：

```
Call to main actor-isolated instance method 'isAdAvailable()' in a synchronous nonisolated context
```

## 问题分析

错误原因：
1. `AppOpenAdManager` 类被标记为 `@MainActor`
2. 它的 `isAdAvailable()` 方法因此也是主线程隔离的
3. 但我们在非主线程上下文中调用了这个方法

## 解决方案

### ✅ 修复前的代码：
```swift
/// 检查开屏广告是否可用
@objc public var isAppOpenAdAvailable: Bool {
    return AppOpenAdManager.shared.isAdAvailable()  // ❌ 错误：非隔离上下文调用主线程方法
}
```

### ✅ 修复后的代码：
```swift
/// 检查开屏广告是否可用
@MainActor @objc public var isAppOpenAdAvailable: Bool {
    return AppOpenAdManager.shared.isAdAvailable()  // ✅ 正确：主线程上下文调用
}
```

### 其他相关修复：

**1. 开屏广告管理器设置**
```swift
@MainActor internal func setupAppOpenAdManager() {
    let appOpenManager = AppOpenAdManager.shared
    
    // 设置统一的回调处理器，避免重复设置
    appOpenManager.adStateComplete = { [weak self] (state: AdCallback.AdLoadState) in
        self?.handleAppOpenAdState(state, callbacks: self?.appOpenAdCallbacks)
    }
}
```

**2. 属性访问级别调整**
```swift
// 从 private 改为 internal，允许扩展文件访问
internal var appOpenAdCallbacks: AdCallbacks?
```

## 使用注意事项

### ✅ 正确使用方式：

```swift
// 在主线程上下文中检查
Task { @MainActor in
    if GrowthKit.shared.isAppOpenAdAvailable {
        // 展示开屏广告
        GrowthKit.showAd(with: .appOpen, callbacks: self)
    }
}

// 或者在已经是主线程的方法中
@MainActor
func checkAndShowAppOpenAd() {
    if GrowthKit.shared.isAppOpenAdAvailable {
        GrowthKit.showAd(with: .appOpen, callbacks: self)
    }
}
```

### ❌ 错误使用方式：

```swift
// 在非主线程上下文中直接访问
func someBackgroundMethod() {
    // ❌ 这会导致编译错误
    if GrowthKit.shared.isAppOpenAdAvailable {
        // ...
    }
}
```

## Swift 并发最佳实践

### 1. MainActor 隔离
- 所有UI相关的操作都应该在主线程
- 使用 `@MainActor` 标记确保线程安全

### 2. 异步调用模式
```swift
// 推荐的异步调用模式
Task { @MainActor in
    // 主线程操作
    let isAvailable = GrowthKit.shared.isAppOpenAdAvailable
    if isAvailable {
        GrowthKit.showAd(with: .appOpen, callbacks: self)
    }
}
```

### 3. 属性访问设计
- 对于需要跨文件访问的属性，使用 `internal` 而不是 `private`
- 确保线程隔离的一致性

## 总结

修复后的代码现在：
- ✅ **线程安全**: 正确使用 `@MainActor` 隔离
- ✅ **类型安全**: 添加了必要的类型注解
- ✅ **访问控制**: 合理的访问级别设置
- ✅ **最佳实践**: 符合 Swift 并发编程规范

这个修复确保了开屏广告功能在多线程环境下的安全性和正确性。
