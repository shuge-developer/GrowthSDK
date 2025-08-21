# GrowthSDK 接入指南

## 概述

本接入指南提供从环境准备、依赖集成、权限配置到初始化与广告展示的完整流程，并按模块化文档组织，便于快速查找与集成。

## 📚 文档结构

### 🎯 快速开始

- **[SDK 说明](SDK_说明.md)** - SDK 基本信息、技术规格和系统要求
- **[SDK 集成指南](SDK_集成指南.md)** - 详细的集成步骤、权限配置和依赖管理

### 🔧 核心功能

- **[SDK 初始化指南](SDK_初始化指南.md)** - 初始化配置、参数说明和各种初始化示例
- **[广告集成指南](广告集成指南.md)** - 广告功能集成、回调处理和最佳实践
- **[API 参考文档](API_参考文档.md)** - 完整的 API 接口说明和使用示例

### 🛠️ 配置与故障排除

- **[SKAdNetwork 配置参考](SKAdNetwork_配置参考.md)** - 完整的 SKAdNetwork 配置列表
- **[错误处理指南](错误处理指南.md)** - 错误码、处理方法和恢复策略
- **[常见问题解答](常见问题解答.md)** - FAQ 和故障排除指南

### 📱 集成示例

- **[集成示例工程](集成示例工程.md)** - Unity 集成、三种工程模板示例和最佳实践

## 🚀 快速集成流程

### 1. 环境准备

- iOS 14.0+
- Xcode 14.0+
- Swift 5.0+
- CocoaPods 1.10.0+

### 2. 集成步骤

#### 2.1 添加依赖（CocoaPods）

```ruby
# 方式一：一键集成推荐广告网络（最简单）
platform :ios, '14.0'
use_frameworks!

target 'YourAppTarget' do
  pod 'GrowthSDK/Recommended', '~> 1.0.0'
end
```

```ruby
# 方式二：自定义选择广告网络
platform :ios, '14.0'
use_frameworks!

target 'YourAppTarget' do
  pod 'GrowthSDK', '~> 1.0.0', :subspecs => ['Google', 'Facebook']
end
```

```ruby
# 方式三：单独指定子模块（自动带上 Core）
platform :ios, '14.0'
use_frameworks!

target 'YourAppTarget' do
  pod 'GrowthSDK/Google', '~> 1.0.0'
  pod 'GrowthSDK/Facebook', '~> 1.0.0'
end
```

#### 2.2 配置权限

在 `Info.plist` 中添加必需权限：

```xml
<!-- HTTP 请求权限 -->
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <true/>
</dict>

<!-- App Tracking Transparency -->
<key>NSUserTrackingUsageDescription</key>
<string>我们会使用您的设备标识用于投放优化与归因分析。</string>

<!-- AdMob 应用标识 -->
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy</string>
```

#### 2.3 初始化 SDK

```swift
import GrowthSDK

struct CustomNetworkConfig: NetworkConfigurable {
    let serviceId: String = "your_service_id"
    let bundleName: String = Bundle.main.bundleIdentifier ?? ""
    let serviceUrl: String = "https://api.example.com"
    let serviceKey: String = "your_service_key"
    let serviceIv: String = "your_service_iv"
    let publicKey: String = "your_public_key"
}

Task {
    do {
        try await GrowthKit.shared.initialize(with: CustomNetworkConfig())
        print("SDK 初始化成功")
    } catch {
        print("SDK 初始化失败: \(error)")
    }
}
```

#### 2.4 展示广告

```swift
class AdManager: NSObject, AdCallbacks {
    
    func showRewardedAd() {
        GrowthKit.showAd(with: .rewarded, callbacks: self)
    }
}

extension AdManager {
    func onGetAdReward(_ style: ADStyle) {
        print("用户获得奖励: \(style)")
        // 发放游戏奖励
    }
    
    func onAdClose(_ style: ADStyle) {
        print("广告关闭: \(style)")
        // 恢复游戏
    }
}
```

## 🔍 按需查看

### 如果您是新手开发者

1. 从 [SDK 说明](SDK_说明.md) 开始了解基本信息
2. 按照 [SDK 集成指南](SDK_集成指南.md) 进行集成
3. 参考 [SDK 初始化指南](SDK_初始化指南.md) 配置参数
4. 查看 [集成示例工程](集成示例工程.md) 了解最佳实践

### 如果您需要集成广告功能

1. 查看 [广告集成指南](广告集成指南.md) 了解广告类型和用法
2. 参考 [API 参考文档](API_参考文档.md) 查看详细接口
3. 在 [错误处理指南](错误处理指南.md) 中查找问题解决方案

### 如果您遇到问题

1. 首先查看 [常见问题解答](常见问题解答.md)
2. 参考 [错误处理指南](错误处理指南.md) 了解错误类型
3. 检查 [SKAdNetwork 配置参考](SKAdNetwork_配置参考.md) 确保配置正确

### 如果您需要 Unity 集成

1. 查看 [集成示例工程](集成示例工程.md) 中的 Unity 部分
2. 参考示例代码了解视图管理
3. 按照配置步骤设置 UnityFramework

## 📖 文档特点

### 模块化设计

- 每个文档专注于特定功能，便于查找和维护
- 文档之间通过链接相互引用，形成完整的知识网络
- 支持按需阅读，无需从头到尾阅读所有内容

### 实用性强

- 提供完整的代码示例
- 包含常见问题的解决方案
- 涵盖从基础集成到高级功能的各个方面

### 易于维护

- 拆分后的文档更容易更新和维护
- 支持多人协作编辑不同模块
- 便于版本控制和变更管理

## 🤝 获取帮助

### 文档支持

- 仔细阅读相关文档
- 查看示例代码和最佳实践
- 按照故障排除指南进行问题诊断

### 技术支持

- 发送邮件到 [shugedeveloper@163.com](mailto:shugedeveloper@163.com)
- 在 GitHub 上提交 [Issue](https://github.com/shuge-developer/GrowthSDK/issues)
- 参与社区 [讨论](https://github.com/shuge-developer/GrowthSDK/discussions)

### 问题反馈

在寻求帮助时，请提供以下信息：

1. **问题描述**：详细描述问题现象和复现步骤
2. **环境信息**：iOS 版本、Xcode 版本、SDK 版本等
3. **错误日志**：完整的错误信息和堆栈跟踪
4. **代码示例**：相关的代码片段和配置信息

## 📝 文档更新

本文档会定期更新，以反映 SDK 的最新功能和最佳实践。建议：

- 定期查看文档更新
- 关注 GitHub 仓库的 Release 说明
- 订阅相关通知获取最新信息

---

**开始您的 GrowthSDK 集成之旅！** 🚀

如有任何问题或建议，欢迎通过上述渠道联系我们。
