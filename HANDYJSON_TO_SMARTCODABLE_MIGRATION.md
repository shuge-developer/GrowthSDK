# HandyJSON 到系统 Codable 迁移总结

## 迁移概述

本次迁移将 GameWrapper SDK 中的 JSON 解析库从 [HandyJSON](https://github.com/alibaba/HandyJSON) 最终迁移到 Swift 原生的 `Codable` 协议。

迁移历程：
1. **HandyJSON** → 打包 SDK 失败（库不再维护）
2. **SmartCodable** → 打包 SDK 仍然失败
3. **系统 Codable** → ✅ 成功解决打包问题，网络数据解析正常

## 迁移背景

### 1.1 HandyJSON 问题
- **维护状态**：HandyJSON 已停止维护，不再支持最新的 Xcode 和 Swift 版本
- **打包失败**：在构建 XCFramework 时出现编译错误和链接问题
- **兼容性问题**：与新版本 Xcode 的构建系统不兼容

### 1.2 SmartCodable 尝试
- **选择原因**：SmartCodable 基于 Codable 实现，API 与 HandyJSON 高度兼容
- **遇到的问题**：虽然 API 兼容，但在 XCFramework 打包时仍然出现依赖问题
- **根本原因**：第三方 JSON 解析库在 Framework 打包时存在架构兼容性问题

### 1.3 最终解决方案
- **系统 Codable**：使用 Swift 原生的 `Codable` 协议
- **优势**：完全兼容 Xcode 构建系统，无第三方依赖
- **结果**：成功解决打包问题，网络数据解析功能正常

## 迁移内容

### 2. 依赖库更新

**项目文件更新：**
- `GameWrapper.xcodeproj/project.pbxproj`
  - 移除 HandyJSON 包引用
  - 移除 SmartCodable 包引用
  - 使用系统原生 Codable 协议

### 3. 代码修改

#### 3.1 导入语句更新

所有文件都已移除第三方 JSON 库的导入：

```swift
// 修改前
import HandyJSON
import SmartCodable

// 修改后
// 无需导入，使用系统原生 Codable
```

#### 3.2 协议更新

**枚举协议更新：**
```swift
// 修改前
internal enum InitStatus: Int16, HandyJSONEnum {
internal enum AdLoadStatus: String, HandyJSONEnum {
internal enum AdFillStatus: String, HandyJSONEnum {
internal enum AdDisplayStatus: String, HandyJSONEnum {
internal enum AdElementType: String, HandyJSONEnum {

// 修改后
internal enum InitStatus: Int16, Codable, CaseIterable {
internal enum AdLoadStatus: String, Codable, CaseIterable {
internal enum AdFillStatus: String, Codable, CaseIterable {
internal enum AdDisplayStatus: String, Codable, CaseIterable {
internal enum AdElementType: String, Codable, CaseIterable {
```

**结构体协议更新：**
```swift
// 修改前
internal struct H5ConfigModel: HandyJSON {
internal struct H5InitConfig: HandyJSON, ParseValueable {
internal struct H5ExtraConfig: HandyJSON, ParseValueable {
internal struct H5CfgConfig: HandyJSON {
internal struct H5LinkData: HandyJSON, TaskTypeable, ParseValueable {
internal struct H5JSConfig: HandyJSON {
internal struct AdArea: HandyJSON {
internal struct AdElement: HandyJSON {
internal struct FunctionArea: HandyJSON {
internal struct FunctionRect: HandyJSON {

// 修改后
internal struct H5ConfigModel: Codable, ParseValueable, JSONPostMapping {
internal struct H5InitConfig: Codable, ParseValueable, JSONPostMapping {
internal struct H5ExtraConfig: Codable, ParseValueable, JSONPostMapping {
internal struct H5CfgConfig: Codable {
internal struct H5LinkData: Codable, TaskTypeable, ParseValueable, JSONPostMapping {
internal struct H5JSConfig: Codable {
internal struct AdArea: Codable {
internal struct AdElement: Codable {
internal struct FunctionArea: Codable {
internal struct FunctionRect: Codable {
```

#### 3.3 自定义解析逻辑

由于系统 Codable 不支持 HandyJSON 的 `didFinishMapping()` 机制，我们实现了自定义的解析逻辑：

**JSONPostMapping 协议：**
```swift
internal protocol JSONPostMapping {
    mutating func didFinishMapping()
}
```

**JSONExtension 扩展：**
```swift
internal extension Decodable {
    static func deserialize(from jsonString: String?) -> Self? {
        // 实现 JSON 反序列化
        // 自动调用 didFinishMapping() 方法
    }
}

internal extension Encodable {
    func toJSONString() -> String? {
        // 实现 JSON 序列化
    }
}
```

### 4. 修改的文件列表

#### 4.1 核心模型文件
- `GameWrapper/Private/Networking/Models/H5ConfigModel.swift`
- `GameWrapper/Private/WebView/Models/AdElementModel.swift`
- `GameWrapper/Private/WebView/Models/FuncAreaModel.swift`

#### 4.2 扩展文件
- `GameWrapper/Private/Extensions/JSONExtension.swift` - 新增自定义 JSON 解析扩展

#### 4.3 网络服务文件
- `GameWrapper/Private/Networking/NetworkServer.swift`

#### 4.4 业务逻辑文件
- `GameWrapper/Private/WebView/SingleLayerWebView/SingleLayerViewModel.swift`
- `GameWrapper/Private/WebView/MultiLayerWebView/MultiLayerTaskHandler.swift`

#### 4.5 项目配置文件
- `GameWrapper.xcodeproj/project.pbxproj`

### 5. API 兼容性

通过自定义扩展，保持了与 HandyJSON 相同的 API：

- `deserialize(from:)` - JSON 反序列化
- `toJSONString()` - JSON 序列化
- `didFinishMapping()` - 后处理回调
- 枚举的 `rawValue` 支持
- 结构体的默认值初始化

### 6. 优势

#### 6.1 系统 Codable 的优势
- **原生支持**：Swift 原生协议，完全兼容 Xcode 构建系统
- **无第三方依赖**：避免第三方库的维护和兼容性问题
- **类型安全**：强类型系统，编译时错误检查
- **性能优化**：系统级优化，解析性能优秀
- **长期稳定**：Apple 官方维护，长期稳定支持

#### 6.2 迁移优势
- **打包成功**：完全解决 XCFramework 打包失败问题
- **API 兼容**：保持现有业务逻辑不变
- **功能完整**：网络数据解析功能正常工作
- **维护简单**：无第三方依赖，维护成本低

### 7. 验证步骤

1. **编译检查**：✅ 所有文件编译通过
2. **打包测试**：✅ XCFramework 打包成功
3. **功能测试**：✅ JSON 解析功能正常
4. **网络测试**：✅ 网络数据解析正常
5. **集成测试**：✅ SDK 整体功能正常

### 8. 技术实现细节

#### 8.1 自定义解析机制
```swift
// 自动调用 didFinishMapping()
if var postMapping = result as? JSONPostMapping {
    postMapping.didFinishMapping()
    return postMapping as? Self
}
```

#### 8.2 嵌套对象处理
```swift
// 手动处理嵌套对象的 didFinishMapping()
if var initConfig = `init` {
    initConfig.didFinishMapping()
    `init` = initConfig
}
```

#### 8.3 数组解析支持
```swift
// 支持数组元素的自动解析
for (index, result) in results.enumerated() {
    if var postMapping = result as? JSONPostMapping {
        postMapping.didFinishMapping()
        if let processed = postMapping as? Element {
            results[index] = processed
        }
    }
}
```

### 9. 注意事项

1. **协议一致性**：所有模型都需要正确实现 `Codable` 协议
2. **CodingKeys**：需要为属性名不匹配的字段定义 `CodingKeys`
3. **默认值处理**：需要手动处理默认值和可选值
4. **枚举支持**：需要为枚举添加 `CaseIterable` 协议支持
5. **后处理逻辑**：`didFinishMapping()` 需要手动调用嵌套对象

### 10. 后续工作

1. **性能监控**：监控解析性能，确保满足业务需求
2. **错误处理**：完善错误处理机制，提供更好的调试信息
3. **文档更新**：更新相关技术文档和 API 文档
4. **团队培训**：确保团队成员了解新的解析机制

## 总结

本次迁移成功将 GameWrapper SDK 从 HandyJSON 最终迁移到系统原生 Codable，完全解决了 XCFramework 打包失败的问题。

### 🎯 关键成果

1. **✅ 打包问题解决**：XCFramework 构建成功，无编译错误
2. **✅ 功能完整性**：网络数据解析功能正常工作
3. **✅ API 兼容性**：保持现有业务逻辑不变
4. **✅ 长期稳定性**：使用系统原生协议，无第三方依赖风险

### 🚀 技术价值

- **架构优化**：移除第三方依赖，简化项目架构
- **维护成本**：降低维护成本，提高项目稳定性
- **兼容性**：完全兼容最新的 Xcode 和 Swift 版本
- **性能**：系统级优化，解析性能优秀

系统 Codable 作为 Swift 原生的数据解析方案，为 SDK 提供了最稳定、最可靠的 JSON 处理能力，确保了项目的长期健康发展。 