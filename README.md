# GrowthSDK

[![Platform](https://img.shields.io/badge/platform-iOS%2014.0%2B-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.0%2B-orange.svg)](https://swift.org/)
[![CocoaPods](https://img.shields.io/badge/CocoaPods-1.10.0%2B-red.svg)](https://cocoapods.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

GrowthSDK 是一个专为游戏增长和变现设计的综合性 iOS SDK 框架，提供强大的广告集成、用户参与工具和分析功能。

## 🌟 核心特性

- 🎮 **游戏增长工具** - 全面的游戏变现和用户留存解决方案
- 📱 **iOS 14.0+ 支持** - 现代化的 iOS 开发体验
- 🚀 **高性能架构** - 优化的架构设计，确保流畅的游戏体验
- 🔒 **安全优先** - 企业级加密和数据保护
- 📦 **简单集成** - 简单的 CocoaPods 集成和全面的文档支持
- 🌍 **多平台广告** - 支持主流广告网络（AdMob、AppLovin、KwaiAds）
- 📊 **数据分析** - 详细的性能指标和用户行为分析
- 🎯 **智能定向** - 高级用户分群和个性化体验

## 📋 系统要求

- **iOS**: 14.0+
- **Xcode**: 14.0+
- **Swift**: 5.0+
- **CocoaPods**: 1.10.0+

## 🚀 快速开始

### 安装

#### CocoaPods（推荐）

在您的 `Podfile` 中添加：

```ruby
platform :ios, '14.0'
use_frameworks!

target 'YourApp' do
  pod 'GrowthSDK', '~> 1.0.0'
end
```

然后运行：

```bash
pod install
```

#### 手动集成

1. 下载 `GrowthSDK.xcframework`
2. 将框架拖拽到您的 Xcode 项目中
3. 在"Frameworks, Libraries, and Embedded Content"中设置为"Embed & Sign"

### 基础使用

```swift
import GrowthSDK

// 初始化 SDK
let config = NetworkConfig(
    serviceId: "your_service_id",
    bundleName: Bundle.main.bundleIdentifier ?? "",
    serviceUrl: "https://api.example.com",
    serviceKey: "your_service_key",
    serviceIv: "your_service_iv",
    publicKey: "your_public_key"
)

Task {
    do {
        try await GrowthKit.shared.initialize(with: config)
        print("SDK 初始化成功")
    } catch {
        print("SDK 初始化失败: \(error)")
    }
}

// 展示广告
GrowthKit.showAd(with: .rewarded)
```

## 📚 文档导航

### 📖 [完整接入指南](Wiki/GrowthSDK_接入指南.md)
以下是基于完整接入文档拆分的指南，结构清晰，内容详细。

### 🎯 快速参考

- **[SDK 说明](Wiki/SDK_说明.md)** - SDK 基本信息和技术规格
- **[SDK 集成指南](Wiki/SDK_集成指南.md)** - 详细的集成步骤和配置说明
- **[SDK 初始化指南](Wiki/SDK_初始化指南.md)** - 初始化配置和示例代码
- **[广告集成指南](Wiki/广告集成指南.md)** - 广告功能集成和 API 使用
- **[API 参考文档](Wiki/API_参考文档.md)** - 完整的 API 接口说明
- **[错误处理指南](Wiki/错误处理指南.md)** - 错误码和处理方法
- **[常见问题解答](Wiki/常见问题解答.md)** - FAQ 和故障排除
- **[集成示例工程](Wiki/集成示例工程.md)** - Unity 集成和示例项目

### 🔧 配置参考

- **[网络配置说明](Wiki/SDK_初始化指南.md#配置参数说明)** - 网络配置参数详解
- **[权限设置指南](Wiki/SDK_集成指南.md#权限与配置)** - 必需的权限和配置项
- **[依赖管理说明](Wiki/SDK_集成指南.md#必需依赖)** - 第三方依赖管理
- **[SKAdNetwork 配置](Wiki/SKAdNetwork_配置参考.md)** - 完整的 SKAdNetwork 配置

## 🎯 应用场景

- **移动游戏** - 变现和用户参与
- **应用发布商** - 收入优化和分析
- **游戏工作室** - 玩家留存和增长工具
- **广告网络** - 多平台广告解决方案

## 🔗 依赖关系

### 必需依赖
- AppLovinSDK (13.3.1+)
- KwaiAdsSDK (1.2.0+)

### 可选广告中介适配器
- BigoAds、ByteDance、Chartboost、Fyber
- Google、InMobi、Vungle、Facebook
- Mintegral、Moloco 等

## 📱 支持的广告格式

- **激励视频广告** - 用户参与并获得奖励
- **插屏广告** - 全屏广告体验
- **开屏广告** - 启动屏幕变现
- **竞价广告** - 实时竞价优化

## 🤝 技术支持

### 文档资源
- 📖 [接入指南](Wiki/GrowthSDK_接入指南.md) - 完整的集成说明
- 🎯 [示例工程](Wiki/集成示例工程.md) - 集成示例和最佳实践

### 社区支持
- 🐛 [问题反馈](https://github.com/shuge-developer/GrowthSDK/issues)
- 📧 [邮件支持](mailto:shugedeveloper@163.com)

### 开发资源
- 🎯 [示例工程](UnifiedExample/) - 完整的集成示例
- 📱 [Unity 支持](Wiki/集成示例工程.md) - Unity 游戏集成

## 📄 许可证

版权所有 © 2024 Shuge Developer。基于 [MIT 许可证](LICENSE) 授权。
