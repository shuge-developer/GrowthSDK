# GrowthSDK

GrowthSDK 是一个用于 iOS 应用开发的 SDK 框架，提供游戏增长相关的功能。

## 功能特性

- 🎮 游戏增长功能
- 📱 iOS 14.0+ 支持
- 🚀 高性能架构
- 🔒 安全加密
- 📦 CocoaPods 集成

## 系统要求

- iOS 14.0+
- Xcode 14.0+
- Swift 5.0+
- CocoaPods 1.10.0+

## 安装

### CocoaPods

在您的 `Podfile` 中添加：

```ruby
pod 'GrowthSDK', '~> 1.0.0'
```

然后运行：

```bash
pod install
```

### 手动集成

1. 下载 `GrowthSDK.xcframework`
2. 将框架拖拽到您的 Xcode 项目中
3. 确保在 "Frameworks, Libraries, and Embedded Content" 中设置为 "Embed & Sign"

## 快速开始

### 初始化

```swift
import GrowthSDK

// 初始化 SDK
GrowthKit.configure(with: config)
```

### 基本使用

```swift
// 启动任务
GrowthKit.launchTask(with: taskConfig)
```

## 版本历史

请查看 [Releases](https://github.com/shuge-developer/GrowthSDK/releases) 页面了解版本更新历史。

## 文档

详细的 API 文档请参考项目文档。

## 许可证

版权所有 © 2024 Shuge Developer

## 支持

如果您在使用过程中遇到问题，请通过以下方式联系我们：

- 提交 Issue：[GitHub Issues](https://github.com/shuge-developer/GrowthSDK/issues)
- 邮箱：support@shuge.com
