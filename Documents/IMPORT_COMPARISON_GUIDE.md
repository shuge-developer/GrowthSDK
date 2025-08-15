# Swift 依赖导入方式对比指南

## 概述

Swift 提供了多种方式来导入和管理模块依赖，其中 `@_implementationOnly import` 和 `internal import` 都用于隐藏内部依赖，但它们有不同的特性和使用场景。

## 语法对比

### 1. @_implementationOnly import (Swift 5.1+)
```swift
@_implementationOnly import GoogleMobileAds
@_implementationOnly import AppLovinSDK
```

### 2. internal import (Swift 5.9+)
```swift
internal import GoogleMobileAds
internal import AppLovinSDK
```

## 详细对比

### 可见性控制

#### @_implementationOnly import
```swift
// 在框架内部
@_implementationOnly import GoogleMobileAds

class AdMobProvider {
    func initialize() {
        let sdk = MobileAds.shared  // ✅ 内部可以使用
    }
}

// 下游应用
import GrowthSDK

let provider = AdMobProvider()      // ✅ 可以使用我们的类
let sdk = MobileAds.shared          // ❌ 完全无法访问
```

#### internal import
```swift
// 在框架内部
internal import GoogleMobileAds

class AdMobProvider {
    func initialize() {
        let sdk = MobileAds.shared  // ✅ 内部可以使用
    }
}

// 下游应用
import GrowthSDK

let provider = AdMobProvider()      // ✅ 可以使用我们的类
let sdk = MobileAds.shared          // ❌ 无法访问（但可能有例外情况）
```

### 编译时检查严格程度

#### @_implementationOnly import
- **更严格**：确保导入的模块符号不会在任何公共API中暴露
- **编译时验证**：如果尝试在公共接口中使用，会直接报错
- **类型安全**：提供更强的类型安全保障

#### internal import
- **相对宽松**：主要依赖 Swift 的访问控制机制
- **运行时行为**：在某些复杂情况下可能有不同的行为
- **灵活性**：提供更多的灵活性，但可能带来风险

### 使用场景

#### @_implementationOnly import 适用于：
- 需要完全隐藏内部依赖
- 严格的符号隔离要求
- 避免任何可能的符号泄露
- 框架开发中的最佳实践

#### internal import 适用于：
- 较新的 Swift 项目（5.9+）
- 需要更灵活的依赖管理
- 简单的内部依赖隐藏
- 现代 Swift 开发实践

## 实际代码示例

### 示例 1：基本使用
```swift
// 使用 @_implementationOnly
@_implementationOnly import GoogleMobileAds

class AdManager {
    private func loadAd() {
        let request = GADRequest()  // ✅ 内部使用
    }
    
    public func showAd() {
        // 不暴露任何 GADRequest 相关类型
    }
}

// 使用 internal import
internal import GoogleMobileAds

class AdManager {
    private func loadAd() {
        let request = GADRequest()  // ✅ 内部使用
    }
    
    public func showAd() {
        // 同样不暴露 GADRequest 相关类型
    }
}
```

### 示例 2：错误处理
```swift
// @_implementationOnly 的错误处理
@_implementationOnly import GoogleMobileAds

enum AdError: Error {
    case loadFailed
    case showFailed
    // ❌ 不能直接使用 GADRequestError
    // case admobError(GADRequestError)  // 编译错误
}

// internal import 的错误处理
internal import GoogleMobileAds

enum AdError: Error {
    case loadFailed
    case showFailed
    // ❌ 同样不能直接使用 GADRequestError
    // case admobError(GADRequestError)  // 编译错误
}
```

### 示例 3：类型包装
```swift
// 两种方式都需要类型包装
@_implementationOnly import GoogleMobileAds
// 或
internal import GoogleMobileAds

// 包装类型
public struct AdConfig {
    public let adUnitId: String
    public let appId: String
    
    // 内部使用 GoogleMobileAds 类型
    internal func createRequest() -> GADRequest {
        return GADRequest()
    }
}
```

## 迁移建议

### 从 @_implementationOnly 迁移到 internal import

如果你的项目使用 Swift 5.9+，可以考虑迁移：

```swift
// 旧方式
@_implementationOnly import GoogleMobileAds

// 新方式
internal import GoogleMobileAds
```

### 迁移步骤：
1. 确保项目使用 Swift 5.9+
2. 批量替换 `@_implementationOnly import` 为 `internal import`
3. 测试编译和功能
4. 验证符号隔离效果

## 最佳实践建议

### 1. 选择标准
- **Swift 5.9+ 项目**：推荐使用 `internal import`
- **需要严格符号隔离**：继续使用 `@_implementationOnly import`
- **向后兼容性要求**：使用 `@_implementationOnly import`

### 2. 一致性
- 在同一个项目中保持一致的导入方式
- 避免混用不同的导入方式
- 建立团队编码规范

### 3. 文档化
- 在项目文档中说明选择的导入方式
- 记录迁移决策和原因
- 为团队成员提供使用指南

## 总结

| 特性 | @_implementationOnly | internal import |
|------|---------------------|-----------------|
| 引入版本 | Swift 5.1+ | Swift 5.9+ |
| 严格程度 | 更严格 | 相对宽松 |
| 编译检查 | 强类型检查 | 访问控制检查 |
| 向后兼容 | 更好 | 需要新版本 |
| 推荐场景 | 严格隔离 | 现代项目 |

对于 GrowthSDK 项目，建议：
1. 如果使用 Swift 5.9+，可以迁移到 `internal import`
2. 如果需要严格的符号隔离，继续使用 `@_implementationOnly import`
3. 保持项目内部的一致性
