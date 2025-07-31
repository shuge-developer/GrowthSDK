# HandyJSON 到 SmartCodable 迁移总结

## 迁移概述

本次迁移将 GameWrapper SDK 中的 JSON 解析库从 [HandyJSON](https://github.com/alibaba/HandyJSON) 替换为 [SmartCodable](https://github.com/iAmMccc/SmartCodable)。

SmartCodable 是基于 Codable 实现的数据解析库，API 和功能几乎和 HandyJSON 一致，支持快速迁移。

## 迁移内容

### 1. 依赖库更新

**项目文件更新：**
- `GameWrapper.xcodeproj/project.pbxproj`
  - 将 HandyJSON 包引用替换为 SmartCodable
  - 更新仓库 URL：`https://github.com/iAmMccc/SmartCodable`
  - 更新最低版本：`5.0.0`

### 2. 代码修改

#### 2.1 导入语句更新

所有使用 HandyJSON 的文件都已更新导入语句：

```swift
// 修改前
import HandyJSON
internal import HandyJSON

// 修改后
import SmartCodable
```

#### 2.2 协议更新

**枚举协议更新：**
```swift
// 修改前
internal enum InitStatus: Int16, HandyJSONEnum {
internal enum AdLoadStatus: String, HandyJSONEnum {
internal enum AdFillStatus: String, HandyJSONEnum {
internal enum AdDisplayStatus: String, HandyJSONEnum {
internal enum AdElementType: String, HandyJSONEnum {

// 修改后
internal enum InitStatus: Int16, SmartCaseDefaultable {
internal enum AdLoadStatus: String, SmartCaseDefaultable {
internal enum AdFillStatus: String, SmartCaseDefaultable {
internal enum AdDisplayStatus: String, SmartCaseDefaultable {
internal enum AdElementType: String, SmartCaseDefaultable {
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
internal struct H5ConfigModel: SmartCodable {
internal struct H5InitConfig: SmartCodable, ParseValueable {
internal struct H5ExtraConfig: SmartCodable, ParseValueable {
internal struct H5CfgConfig: SmartCodable {
internal struct H5LinkData: SmartCodable, TaskTypeable, ParseValueable {
internal struct H5JSConfig: SmartCodable {
internal struct AdArea: SmartCodable {
internal struct AdElement: SmartCodable {
internal struct FunctionArea: SmartCodable {
internal struct FunctionRect: SmartCodable {
```

### 3. 修改的文件列表

#### 3.1 核心模型文件
- `GameWrapper/Private/Networking/Models/H5ConfigModel.swift`
- `GameWrapper/Private/WebView/Models/AdElementModel.swift`
- `GameWrapper/Private/WebView/Models/FuncAreaModel.swift`

#### 3.2 网络服务文件
- `GameWrapper/Private/Networking/NetworkServer.swift`

#### 3.3 业务逻辑文件
- `GameWrapper/Private/WebView/SingleLayerWebView/SingleLayerViewModel.swift`
- `GameWrapper/Private/WebView/MultiLayerWebView/MultiLayerTaskHandler.swift`

#### 3.4 项目配置文件
- `GameWrapper.xcodeproj/project.pbxproj`

### 4. API 兼容性

SmartCodable 与 HandyJSON 的 API 高度兼容，以下方法保持不变：

- `deserialize(from:)` - JSON 反序列化
- `toJSONString()` - JSON 序列化
- 枚举的 `rawValue` 支持
- 结构体的默认值初始化

### 5. 优势

#### 5.1 SmartCodable 的优势
- **基于 Codable**：使用 Swift 原生的 Codable 协议，更好的类型安全
- **更好的兼容性**：更强的错误处理和类型转换能力
- **活跃维护**：持续更新，支持最新的 Swift 版本
- **性能优化**：更高效的解析性能

#### 5.2 迁移优势
- **API 兼容**：几乎无需修改现有业务逻辑
- **渐进式迁移**：可以逐步迁移，不影响现有功能
- **更好的错误处理**：SmartCodable 提供更详细的错误信息

### 6. 验证步骤

1. **编译检查**：确保所有文件编译通过
2. **功能测试**：验证 JSON 解析功能正常
3. **性能测试**：确认解析性能符合预期
4. **集成测试**：确保 SDK 整体功能正常

### 7. 注意事项

1. **版本兼容性**：SmartCodable 5.0.0+ 需要 Swift 5.7+
2. **错误处理**：SmartCodable 的错误处理机制略有不同，需要关注异常情况
3. **性能监控**：建议监控迁移后的解析性能
4. **回滚准备**：保留 HandyJSON 的备份，以便需要时快速回滚

### 8. 后续工作

1. **测试验证**：全面测试所有 JSON 解析场景
2. **性能优化**：根据实际使用情况优化解析性能
3. **文档更新**：更新相关技术文档
4. **团队培训**：确保团队成员了解新的解析库

## 总结

本次迁移成功将 GameWrapper SDK 从 HandyJSON 迁移到 SmartCodable，保持了 API 的兼容性，同时获得了更好的类型安全和错误处理能力。迁移过程平滑，对现有业务逻辑影响最小。

SmartCodable 作为基于 Codable 的现代 JSON 解析库，为 SDK 提供了更稳定、更高效的 JSON 处理能力。 