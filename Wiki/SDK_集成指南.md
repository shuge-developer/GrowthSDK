# SDK 集成指南

## 概述

本文档详细介绍如何将 GrowthSDK 集成到您的 iOS 项目中，包括 CocoaPods 集成、手动集成、权限配置和依赖管理。

## 集成方式

### 使用 CocoaPods（推荐）

#### 1. 添加依赖

在工程根目录的 `Podfile` 中加入依赖（三选一）：

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
  pod 'GrowthSDK', '~> 1.0.0', :subspecs => ['Google', 'Facebook', 'Vungle']
end
```

```ruby
# 方式三：单独指定子模块（也会自动带上 Core）
platform :ios, '14.0'
use_frameworks!

target 'YourAppTarget' do
  pod 'GrowthSDK/Google',   '~> 1.0.0'
  pod 'GrowthSDK/Facebook', '~> 1.0.0'
  pod 'GrowthSDK/Vungle',   '~> 1.0.0'
end
```

#### 2. 安装依赖

执行安装命令：

```bash
pod repo update && pod install
```

#### 3. 打开工程

使用生成的 `.xcworkspace` 打开工程，而不是 `.xcodeproj`。

### 手动集成

#### 1. 添加框架文件

- 将 `GrowthSDK.xcframework`（或静态库与头文件）及资源文件加入到工程
- 在 `Build Settings` 中确保 `Always Embed Swift Standard Libraries` 为 `Yes`（如为混编或非 Swift 主工程）
- 确保依赖的系统框架已勾选（如 `UIKit`, `Foundation`, `WebKit` 等）

#### 2. 必需依赖

手动集成也需要通过 CocoaPods 引入以下第三方 SDK：

```ruby
target 'YourAppTarget' do
  pod 'AdjustSignature', '3.47.0'
  pod 'AppLovinSDK', '13.3.1'
  pod 'KwaiAdsSDK', '1.2.1'
end
```

安装命令：

```bash
pod repo update && pod install
```

#### 3. 可选广告适配器

如需接入更多网络，请在 `:subspecs` 或子模块列表中按需添加：

```ruby
target 'YourAppTarget' do
  # 可选适配器（按需添加）
  pod 'AmazonPublisherServicesSDK', '5.3.0'
  pod 'AppLovinMediationAmazonAdMarketplaceAdapter', '5.3.0.0'
  pod 'AppLovinMediationBidMachineAdapter', '3.4.0.0.0'
  pod 'AppLovinMediationByteDanceAdapter', '7.5.0.5.0'
  pod 'AppLovinMediationBigoAdsAdapter', '4.9.3.0'
  pod 'AppLovinMediationChartboostAdapter', '9.9.2.1'
  pod 'AppLovinMediationCSJAdapter', '6.7.1.6.0'
  pod 'AppLovinMediationFyberAdapter', '8.3.8.0'
  pod 'AppLovinMediationGoogleAdManagerAdapter', '12.9.0.0'
  pod 'AppLovinMediationGoogleAdapter', '12.9.0.0'
  pod 'AppLovinMediationHyprMXAdapter', '6.4.2.0.0'
  pod 'AppLovinMediationInMobiAdapter', '10.8.6.0'
  pod 'AppLovinMediationIronSourceAdapter', '8.11.0.0.0'
  pod 'AppLovinMediationVungleAdapter', '7.5.3.0'
  pod 'AppLovinMediationLineAdapter', '2.9.20250805.0'
  pod 'AppLovinMediationMaioAdapter', '2.1.6.0'
  pod 'AppLovinMediationFacebookAdapter', '6.20.1.0'
  pod 'AppLovinMediationMintegralAdapter', '7.7.9.0.0'
  pod 'AppLovinMediationMobileFuseAdapter', '1.9.2.1'
  pod 'AppLovinMediationMolocoAdapter', '3.12.1.0'
  pod 'AppLovinMediationOguryPresageAdapter', '5.1.0.1'
  pod 'AppLovinMediationPubMaticAdapter', '4.8.1.0'
  pod 'AppLovinMediationSmaatoAdapter', '22.9.3.1'
  pod 'AppLovinMediationTencentGDTAdapter', '4.15.21.1'
  pod 'AppLovinMediationUnityAdsAdapter', '4.16.1.0'
  pod 'AppLovinMediationVerveAdapter', '3.6.1.0'
  pod 'AppLovinMediationMyTargetAdapter', '5.34.1.0'
  pod 'AppLovinMediationYandexAdapter', '7.15.1.0'
  pod 'AppLovinMediationYSONetworkAdapter', '1.1.31.1'
end
```

> **注意**：如集成了上述适配器，需在 `AppDelegate` 暴露 `window` 属性（见下文）。

## 权限与配置

### HTTP 请求权限（必须）

需要访问非 HTTPS 资源，请在 `Info.plist` 中添加：

```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <true/>
</dict>
```

### App Tracking Transparency（ATT）权限（必须）

在 `Info.plist` 中添加用途描述，并在合适时机请求权限：

```xml
<key>NSUserTrackingUsageDescription</key>
<string>我们会使用您的设备标识用于投放优化与归因分析。</string>
```

### AdMob 应用标识（必须）

SDK 集成了 AdMob，宿主应用必须在 `Info.plist` 添加 `GADApplicationIdentifier`：

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy</string>
```

请替换为你自己的 AdMob App ID，否则会导致崩溃。

### SKAdNetwork（必须）

为确保归因与广告网络兼容性，请在宿主 App 的 `Info.plist` 中添加 `SKAdNetworkItems`。

```xml
<key>SKAdNetworkItems</key>
<array>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>22mmun2rn5.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>238da6jt44.skadnetwork</string>
    </dict>
    <!-- 更多 SKAdNetwork 标识符... -->
</array>
```

> **注意**：完整的 SKAdNetwork 列表请参考 [SKAdNetwork 配置参考](SKAdNetwork_配置参考.md)。

### AppDelegate window 属性（部分网络要求）

若集成了 InMobi 等适配器，请确保 `AppDelegate` 中暴露可读的 `window` 属性，否则第三方 SDK 可能崩溃：

```swift
var window: UIWindow?
```

请勿移除该属性。

## 依赖管理

### 必需依赖

- **AdjustSignature**: 3.47.0
- **AppLovinSDK**: 13.3.1
- **KwaiAdsSDK**: 1.2.1

### 可选广告中介适配器

- **BigoAds**: 4.9.3.0
- **ByteDance**: 7.5.0.5.0
- **Chartboost**: 9.9.2.1
- **Fyber**: 8.3.8.0
- **Google**: 12.9.0.0
- **InMobi**: 10.8.6.0
- **Vungle**: 7.5.3.0
- **Facebook**: 6.20.1.0
- **Mintegral**: 7.7.9.0.0
- **Moloco**: 3.12.1.0

## 构建配置

### Xcode 设置

1. **Swift 标准库嵌入**：确保 `Always Embed Swift Standard Libraries` 设置为 `Yes`
2. **架构支持**：确保支持 arm64 和 x86_64 架构
3. **部署目标**：最低 iOS 版本设置为 14.0

### 框架链接

确保以下系统框架已正确链接：
- UIKit
- Foundation
- WebKit
- AdSupport
- AppTrackingTransparency

## 验证集成

### 编译检查

1. 清理项目：`Product → Clean Build Folder`
2. 重新构建项目
3. 检查是否有编译错误或警告

### 运行时检查

1. 在真机上运行应用
2. 检查控制台日志
3. 验证 SDK 初始化是否成功

## 常见问题

### 编译错误

- **Swift 标准库错误**：确保 `Always Embed Swift Standard Libraries` 为 `Yes`
- **架构不匹配**：确保所有依赖都支持相同的架构
- **版本冲突**：检查依赖版本兼容性

### 运行时错误

- **AdMob ID 错误**：确保在 Info.plist 中正确配置了 AdMob App ID
- **权限错误**：确保所有必需的权限都已配置
- **依赖缺失**：确保所有第三方 SDK 都已正确安装

## 下一步

集成完成后，请参考：
- [SDK 初始化指南](SDK_初始化指南.md) — 配置结构与初始化流程（包含 Swift/ObjC 示例）
- [API 参考文档](API_参考文档.md) — 全量 API 与类型说明
