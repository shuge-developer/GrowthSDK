# Wiki 文档目录

## 概述

本目录包含 GrowthSDK 的完整接入文档，按模块化方式组织，便于快速查阅与集成。

## 📚 文档结构

### 🎯 快速开始
- **[GrowthSDK_接入指南.md](GrowthSDK_接入指南.md)** - 主要接入指南，包含快速集成流程和文档导航
- **[SDK_说明.md](SDK_说明.md)** - SDK 基本信息、技术规格和系统要求
- **[SDK_集成指南.md](SDK_集成指南.md)** - 详细的集成步骤、权限配置和依赖管理

### 🔧 核心功能
- **[SDK_初始化指南.md](SDK_初始化指南.md)** - 初始化配置、参数说明和各种初始化示例
- **[广告集成指南.md](广告集成指南.md)** - 广告功能集成、回调处理和最佳实践
- **[API_参考文档.md](API_参考文档.md)** - 完整的 API 接口说明和使用示例

### 🛠️ 配置与故障排除
- **[SKAdNetwork_配置参考.md](SKAdNetwork_配置参考.md)** - 完整的 SKAdNetwork 配置列表
- **[错误处理指南.md](错误处理指南.md)** - 错误码、处理方法和恢复策略
- **[常见问题解答.md](常见问题解答.md)** - FAQ 和故障排除指南

### 📱 集成示例
- **[集成示例工程.md](集成示例工程.md)** - Unity 集成、三种工程模板示例和最佳实践

## 🚀 使用建议

1. **新手开发者**：从 [GrowthSDK_接入指南.md](GrowthSDK_接入指南.md) 开始
2. **集成问题**：查看 [常见问题解答.md](常见问题解答.md) 和 [错误处理指南.md](错误处理指南.md)
3. **Unity 集成**：参考 [集成示例工程.md](集成示例工程.md)
4. **API 使用**：查阅 [API_参考文档.md](API_参考文档.md)

## 📝 文档维护

- 这些文档会随 SDK 版本更新
- 如有问题或建议，请通过 GitHub Issues 反馈
- 支持多语言版本，当前为中文版本

---

**开始您的 GrowthSDK 集成之旅！** 🚀

## Podfile 示例（CocoaPods）

```ruby
platform :ios, '14.0'
use_frameworks!

target 'YourAppTarget' do
  # 方式一：一键集成推荐广告网络（最简单）
  pod 'GrowthSDK/Recommended', '~> 1.0.0'
  
  # 方式二：自定义选择广告网络
  # pod 'GrowthSDK', '~> 1.0.0', :subspecs => [
  #   'Google', 'GoogleAdManager', 'Facebook', 'Vungle'
  # ]

  # 方式三：单独指定子模块（也会自动拉取 Core）
  # pod 'GrowthSDK/Google', '~> 1.0.0'
  # pod 'GrowthSDK/Facebook', '~> 1.0.0'
  # pod 'GrowthSDK/Vungle', '~> 1.0.0'
end
```

> 提示：
> - `GrowthSDK/Recommended` 包含 10 个主流广告网络，适合快速开始
> - 任一广告子模块都会自动依赖 `GrowthSDK/Core`，无需单独声明
