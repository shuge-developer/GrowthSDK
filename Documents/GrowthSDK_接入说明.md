# GrowthSDK 接入说明（iOS）

本页提供 GrowthSDK 在 iOS 的完整接入指南。

## 1. SDK 说明

- SDK 支持的最低 iOS 版本为 iOS 14.0
- 支持模拟器和真机架构（arm64、x86_64）
- SDK 内部使用 Swift 5+

## 2. 集成 SDK

### 2.1 使用 CocoaPods（推荐）

1) 在工程根目录的 `Podfile` 中加入依赖：

```ruby
platform :ios, '14.0'
use_frameworks!

target 'YourAppTarget' do
  pod 'GrowthSDK', '~> 1.0.0'
end
```

2) 执行安装：

```bash
pod repo update && pod install
```

3) 使用生成的 `.xcworkspace` 打开工程。

### 2.2 手动集成（集成本地 xcframework + 通过 CocoaPods 引入依赖）

- 将 `GrowthSDK.xcframework`（或静态库与头文件）及资源文件加入到工程
- 在 `Build Settings` 中确保 `Always Embed Swift Standard Libraries` 为 `Yes`（如为混编或非 Swift 主工程）
- 确保依赖的系统框架已勾选（如 `UIKit`, `Foundation`, `WebKit` 等）

#### 2.2.1 必须依赖（手动集成也需要通过 CocoaPods 引入以下第三方 SDK）

```ruby
target 'YourAppTarget' do
  pod 'AppLovinSDK', '13.3.1'
  pod 'KwaiAdsSDK', '1.2.0'
end
```

安装命令：

```bash
pod repo update && pod install
```

#### 2.2.2 可选：广告适配器子模块（AppLovin Mediation）

如需接入多平台广告，请在 `Podfile` 中按需添加以下适配器依赖（与 `AppLovinSDK` 版本配套）：

```ruby
target 'YourAppTarget' do
  # 可选适配器（按需添加）
  pod 'AppLovinMediationBigoAdsAdapter', '4.9.3.0'
  pod 'AppLovinMediationByteDanceAdapter', '7.5.0.5.0'
  pod 'AppLovinMediationChartboostAdapter', '9.9.2.1'
  pod 'AppLovinMediationFyberAdapter', '8.3.8.0'
  pod 'AppLovinMediationGoogleAdapter', '12.9.0.0'
  pod 'AppLovinMediationInMobiAdapter', '10.8.6.0'
  pod 'AppLovinMediationVungleAdapter', '7.5.3.0'
  pod 'AppLovinMediationFacebookAdapter', '6.20.1.0'
  pod 'AppLovinMediationMintegralAdapter', '7.7.9.0.0'
  pod 'AppLovinMediationMolocoAdapter', '3.12.1.0'
end
```

> 注意：如集成了上述适配器，需在 `AppDelegate` 暴露 `window` 属性（见 2.3.5）。

### 2.3 添加权限与必要配置

#### 2.3.1 允许 HTTP 请求（必须）

需要访问非 HTTPS 资源，请在 `Info.plist` 中添加：

```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <true/>
</dict>
```

#### 2.3.2 App Tracking Transparency（ATT）权限（必须）

在 `Info.plist` 中添加用途描述，并在合适时机请求权限：

```xml
<key>NSUserTrackingUsageDescription</key>
<string>我们会使用您的设备标识用于投放优化与归因分析。</string>
```

#### 2.3.3 AdMob 应用标识（必须）

SDK 集成了 AdMob，宿主应用必须在 `Info.plist` 添加 `GADApplicationIdentifier`：

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy</string>
```

请替换为你自己的 AdMob App ID，否则会导致崩溃。

#### 2.3.4 SKAdNetwork（必须）

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
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>24t9a8vw3c.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>24zw6aqk47.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>252b5q8x7y.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>275upjj5gd.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>294l99pt4k.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>2fnua5tdw4.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>2u9pt9hc89.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>32z4fx6l9h.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>33r6p7g8nc.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>3l6bd9hu43.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>3qcr597p9d.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>3qy4746246.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>3rd42ekr43.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>3sh42y64q3.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>424m5254lk.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>4468km3ulz.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>44jx6755aq.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>44n7hlldy6.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>47vhws6wlr.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>488r3q3dtq.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>4dzt52r2t5.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>4fzdc2evr5.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>4mn522wn87.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>4pfyvq9l8r.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>4w7y6s5ca2.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>523jb4fst2.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>52fl2v3hgk.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>54nzkqm89y.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>55644vm79v.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>55y65gfgn7.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>577p5t736z.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>578prtvx9j.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>5a6flpkh64.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>5l3tpt7t6e.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>5lm9lj6jb7.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>5tjdwbrq8w.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>6964rsfnh4.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>6g9af3uyq4.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>6p4ks3rnbw.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>6rd35atwn8.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>6v7lgmsu45.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>6xzpu9s2p8.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>6yxyv74ff7.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>737z793b9f.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>74b6s63p6l.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>7953jerfzd.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>79pbpufp6p.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>7bxrt786m8.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>7fbxrn65az.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>7fmhfwg9en.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>7rz58n8ntl.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>7ug5zh24hu.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>84993kbrcf.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>87u5trcl3r.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>89z7zv988g.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>8c4e2ghe7u.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>8m87ys6875.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>8r8llnkz5a.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>8s468mfl3y.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>97r2b46745.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>9b89h5y424.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>9g2aggbj52.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>9nlqeag3gk.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>9rd848q2bz.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>9t245vhmpl.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>9vvzujtq5s.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>9yg77x724h.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>a2p9lx4jpn.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>a7xqa6mtl2.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>a8cz6cu7e5.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>av6w8kgt66.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>b9bk5wbcq9.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>bvpn9ufa9b.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>bxvub5ada5.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>c3frkrj4fj.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>c6k4g5qg8m.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>ce8ybjwass.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>cg4yq2srnc.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>cj5566h2ga.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>cp8zw746q7.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>cs644xg564.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>cstr6suwn9.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>cwn433xbcr.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>dbu4b84rxf.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>dkc879ngq3.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>dt3cjx1a9i.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>dzg6xy7pwj.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>e5fvkxwrpn.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>ecpz2srf59.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>eh6m2bh4zr.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>ejvt5qm6ak.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>f38h382jlk.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>f73kdq92p3.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>f7s53z58qe.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>feyaarzu9v.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>fq6vru337s.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>fz2k2k5tej.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>g28c52eehv.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>g2y4y55b64.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>g69uk9uh2b.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>g6gcrrvk4p.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>ggvn48r87g.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>glqzh8vgby.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>gta8lk7p23.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>gta9lk7p23.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>gvmwg8q7h5.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>h65wbv5k3f.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>hb56zgv37p.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>hdw39hrw9y.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>hjevpa356n.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>hs6bdukanm.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>jk2fsx2rgz.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>k674qkevps.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>k6y4y55b64.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>kbd757ywx3.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>kbmxgpxpgc.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>klf5c3l5u5.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>krvm3zuq6h.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>ln5gz23vtd.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>lr83yxwka7.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>ludvb6z3bs.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>m297p6643m.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>m5mvw97r93.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>m8dbw4sv7c.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>mj797d8u6f.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>mlmmfzh3r3.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>mls7yz5dvl.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>mp6xlyr22a.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>mqn7fxpca7.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>mtkv5xtk9e.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>n38lu8286q.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>n66cz3y3bx.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>n6fk4nfna4.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>n9x2a789qt.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>ns5j362hk7.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>nu4557a4je.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>nzq8sh4pbs.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>p78axxw29g.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>ppxm28t8ap.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>prcb7njmu6.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>pu4na253f3.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>pwa73g5rt2.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>pwdxu55a5a.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>qqp299437r.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>qu637u8glc.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>qwpu75vrh2.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>r45fhb6rf7.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>r8lj5b58b5.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>rvh3l7un93.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>rx5hdcabgc.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>s39g8k73mm.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>s69wq72ugq.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>su67r6k2v3.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>t38b2kh725.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>t6d3zquu66.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>tl55sbb4fm.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>tmhh9296z4.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>tvvz7th9br.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>u679fj5vs4.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>uw77j35x4d.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>v4nxqhlyqp.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>v72qych5uu.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>v79kvwwj4g.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>v9wttpbfk9.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>vcra2ehyfk.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>vhf287vqwu.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>vutu7akeur.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>w7jznl3r6g.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>w9q455wk68.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>wg4vff78zm.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>wzmmz9fp6w.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>x44k69ngh6.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>x5l83yy675.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>x8jxxk4ff5.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>x8uqf25wch.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>xga6mpmplv.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>xy9t38ct57.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>y45688jllp.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>y5ghdn5j9k.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>yclnxrl5pm.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>ydx93a7ass.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>yrqqpx2mcb.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>z24wtl6j62.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>z4gj7hsk7h.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>z959bm4gru.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>zmvfpc5aq8.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>zq492l623r.skadnetwork</string>
    </dict>
</array>
```

#### 2.3.5 AppDelegate `window` 属性（当集成 AdsDeps 适配器时必须）

若集成了 InMobi 等适配器，请确保 `AppDelegate` 中暴露可读的 `window` 属性，否则第三方 SDK 可能崩溃：

```swift
var window: UIWindow?
```

请勿移除该属性。

## 3. SDK 初始化

GrowthSDK 的对外主入口为 `GrowthKit`。初始化时需要传入 `NetworkConfig` 配置。

### 3.1 配置参数说明

`NetworkConfig` 字段：

- serviceId: 服务/应用 ID（字符串）
- bundleName: 包名（通常为 `Bundle.main.bundleIdentifier`）
- serviceUrl: 服务基础地址（字符串）
- serviceKey: 服务密钥（字符串）
- serviceIv: 服务向量（字符串）
- publicKey: 公钥（字符串）
- configKeyItems: 结构化配置键（数组）
- other: 其它可选扩展字段（`OtherConfig`，主要用于 Objective-C 项目）

`OtherConfig` 扩展字段：

- thirdId: 第三方 ID（可选，字符串）
- instanceId: 实例 ID（可选，字符串）
- campaign: 活动标识（可选，字符串）
- referer: 来源标识（可选，字符串）
- adid: 广告 ID（可选，字符串）

> **注意**：`other` 字段主要是为了适配 Objective-C 项目。在 Swift 和 SwiftUI 项目中，可以直接通过实现 `NetworkConfigurable` 协议来注入这些扩展字段，无需使用 `OtherConfig`。

如需通过结构化配置驱动 SDK 内部的配置拉取，可传入 `configKeyItems`：

```swift
let configKeys: [ConfigKeyItem] = [
    .init(configKey: "your_config_key"),
    .init(adjustKey: "your_adjust_key"),
    .init(adUnitKey: "your_adunit_key")
]
```

### 3.2 初始化示例（Swift · UIKit · async/await）

使用 `NetworkConfigurable` 自定义配置并在 `AppDelegate` 中使用 `async/await` 初始化：

```swift
import UIKit
import GrowthSDK

struct CustomNetworkConfig: NetworkConfigurable {
    let serviceId: String = "your_service_id"
    let bundleName: String = "com.example.app"
    let serviceUrl: String = "https://api.example.com"
    let publicKey: String = "your_public_key_pem"
    let serviceKey: String = "your_service_key"
    let serviceIv: String = "your_service_iv"
    var configKeyItems: [ConfigKeyItem]? {
        [
            ConfigKeyItem(adjustKey: "your_adjust_key"),
            ConfigKeyItem(configKey: "your_config_key"),
            ConfigKeyItem(adUnitKey: "your_adunit_key")
        ]
    }
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Task {
            do {
                try await GrowthKit.shared.initialize(with: CustomNetworkConfig())
                print("SDK 初始化成功")
            } catch {
                print("SDK 初始化失败: \(error)")
            }
        }
        return true
    }
}
```

### 3.3 初始化示例（Objective-C · UIKit）

在 `AppDelegate` 中通过回调方式初始化。注意引入自动生成的 Swift 头文件：`#import <GrowthSDK/GrowthSDK-Swift.h>`。

```objective-c
// AppDelegate.m
#import <GrowthSDK/GrowthSDK-Swift.h>

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self initializeGrowthKitSDK:launchOptions];
    return YES;
}

- (void)initializeGrowthKitSDK:(NSDictionary *)launchOptions {
    NSArray<ConfigKeyItem *> *configKeys = @[
        [[ConfigKeyItem alloc] initWithAdjustKey:@"your_adjust_key"],
        [[ConfigKeyItem alloc] initWithConfigKey:@"your_config_key"],
        [[ConfigKeyItem alloc] initWithAdUnitKey:@"your_adunit_key"]
    ];

    NetworkConfig *config = [[NetworkConfig alloc] initWithServiceId:@"your_service_id"
                                                         bundleName:@"com.example.app"
                                                         serviceUrl:@"https://api.example.com"
                                                         serviceKey:@"your_service_key"
                                                          serviceIv:@"your_service_iv"
                                                          publicKey:@"your_public_key_pem"
                                                     configKeyItems:configKeys
                                                              other:nil];

    [[GrowthKit shared] initializeWith:config launchOptions:launchOptions completion:^(NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                NSLog(@"SDK 初始化失败: %@", error.localizedDescription);
            } else {
                NSLog(@"SDK 初始化成功");
            }
        });
    }];
}
```

### 3.4 初始化示例（SwiftUI · @UIApplicationDelegateAdaptor）

通过 `@UIApplicationDelegateAdaptor` 适配 `AppDelegate` 并在启动时初始化：

```swift
import SwiftUI
import GrowthSDK
import UIKit

struct CustomNetworkConfig: NetworkConfigurable {
    let serviceId: String = "your_service_id"
    let bundleName: String = "com.example.app"
    let serviceUrl: String = "https://api.example.com"
    let publicKey: String = "your_public_key_pem"
    let serviceKey: String = "your_service_key"
    let serviceIv: String = "your_service_iv"
    var configKeyItems: [ConfigKeyItem]? {
        [
            ConfigKeyItem(adjustKey: "your_adjust_key"),
            ConfigKeyItem(configKey: "your_config_key"),
            ConfigKeyItem(adUnitKey: "your_adunit_key")
        ]
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        Task {
            do {
                try await GrowthKit.shared.initialize(with: CustomNetworkConfig())
                print("SDK 初始化成功")
            } catch {
                print("SDK 初始化失败: \(error)")
            }
        }
        return true
    }
}

@main
struct YourApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

## 4. 广告集成

> **注意**：广告集成相关 API 和详细说明请参考 [5.5 广告相关 API](#55-广告相关-api) 章节。

## 5. SDK API 参考

GrowthSDK 提供 广告展示、Unity 视图管理 功能。

### 5.1 版本信息

```swift
// 获取 SDK 版本号
let version = GrowthKit.sdkVersion
```

### 5.2 状态查询

```swift
// 查询 SDK 初始化状态
let isReady = GrowthKit.shared.isInitialized

// 查询 SDK 当前状态
let state = GrowthKit.shared.state
// InitState.uninitialized  - 未初始化
// InitState.initializing   - 初始化中  
// InitState.initialized    - 已初始化
// InitState.failed         - 初始化失败
```

### 5.3 日志控制

```swift
// 启用/禁用 SDK 日志输出
GrowthKit.isLoggingEnabled = true  // 默认启用
```

### 5.4 视图管理（Unity 集成）

#### 5.4.1 UIKit 方式

```swift
// 创建 GrowthSDK 视图控制器
let sdkController = GrowthKit.createController(with: unityController)
```

#### 5.4.2 SwiftUI 方式

```swift
// 创建 GrowthSDK SwiftUI 视图
let sdkView = GrowthKit.createView(with: unityController)
```

> **注意**：视图管理 API 主要用于 Unity 游戏集成场景。

### 5.5 广告相关 API

#### 5.5.1 广告展示

```swift
// 展示激励广告（无回调）
GrowthKit.showAd(with: .rewarded)

// 展示激励广告（带回调）
GrowthKit.showAd(with: .rewarded, callbacks: adCallbacks)

// 展示插屏广告
GrowthKit.showAd(with: .inserted)

// 展示开屏广告
GrowthKit.showAd(with: .appOpen)
```

#### 5.5.2 广告预加载

```swift
// 重新加载开屏广告
GrowthKit.shared.reloadAppOpenAd()

// 重新加载竞价广告
GrowthKit.shared.reloadBiddingAd()
```

#### 5.5.3 广告调试

```swift
// 打开广告调试面板
GrowthKit.shared.showAdDebugger()
```

### 5.6 广告回调协议

```swift
@objc protocol AdCallbacks {
    @objc optional func onStartLoading(_ style: ADStyle)      // 开始加载
    @objc optional func onLoadSuccess(_ style: ADStyle)       // 加载成功
    @objc optional func onLoadFailed(_ style: ADStyle, error: Error?)  // 加载失败
    @objc optional func onShowSuccess(_ style: ADStyle)       // 展示成功
    @objc optional func onShowFailed(_ style: ADStyle, error: Error?)  // 展示失败
    @objc optional func onGetAdReward(_ style: ADStyle)       // 获得激励
    @objc optional func onAdClick(_ style: ADStyle)           // 广告点击
    @objc optional func onAdClose(_ style: ADStyle)           // 广告关闭
}
```

### 5.7 广告样式枚举

```swift
@objc enum ADStyle: Int {
    case rewarded = 0   // 激励广告
    case inserted = 1   // 插屏广告
    case appOpen = 2    // 开屏广告
}
```

## 6. 错误码与错误处理

初始化阶段的错误类型（示例）：

- InitError.alreadyInitialized: 重复初始化
- InitError.storageInitFailed(String): 数据存储初始化失败
- InitError.serviceInitFailed(String): 任务/服务初始化失败

广告阶段的错误通过 `AdCallbacks` 的 `onLoadFailed` / `onShowFailed` 返回。

## 6. 常见问题（FAQ）

### 6.1 IDFA 获取

- 确保在 `Info.plist` 添加 `NSUserTrackingUsageDescription`
- 在合适时机调用 `ATTrackingManager.requestTrackingAuthorization` 申请授权
- 未授权时广告相关个性化与归因可能受限

### 6.2 请求广告失败的常见原因

- 未完成 SDK 初始化或配置未就绪
- 网络异常或服务器返回异常
- 广告无填充（No Fill）
- 频控/策略限制（如冷却时间未到）
- IDFA/权限受限导致竞价或定向能力受限

## 7. 集成示例工程（UnifiedExample）

为方便验证 SDK 与 Unity 集成、三种工程模板（Objc/Swift/SwiftUI）的使用方式，仓库内提供多 Target 示例工程 `UnifiedExample/`。

### 7.1 目录结构
- `UnifiedExample/ObjcExample`：Objective-C 示例
- `UnifiedExample/SwiftExample`：Swift 示例（UIKit）
- `UnifiedExample/SwiftUIExample`：SwiftUI 示例
- `UnifiedExample/UnityProject`：Unity iOS 子工程目录（发布仓库完全忽略该目录；请在本地手动新建 `UnityProject/` 并将 Unity 导出的 iOS 工程拷入）
- `UnifiedExample/README.md`：该示例的详细使用说明

### 7.2 准备与首次打开
先在本地创建并导入 Unity 工程：
```bash
cd UnifiedExample
mkdir -p UnityProject
# 将你本地 Unity 导出的 iOS 工程完整复制到 UnityProject/
```

然后安装依赖并打开：
```bash
cd UnifiedExample
pod install
open UnifiedExample.xcworkspace
```

在 Xcode 顶部 Scheme 中选择任一 Target 运行：`ObjcExample`、`SwiftExample`、`SwiftUIExample`。

### 7.3 Unity 引入（重要）
由于 Unity 子项目自动化配置较复杂，示例已预置子项目引用；但仍需在每个 App Target 手动完成以下操作：
1) 进入 Target → General → Frameworks, Libraries, and Embedded Content
2) 确保你已将 Unity iOS 导出工程复制至 `UnifiedExample/UnityProject/`，并能看到 `Unity-iPhone.xcodeproj`
3) 点击“+”，在 `Unity-iPhone.xcodeproj` → Products 下添加 `UnityFramework.framework`
4) 将其设置为“Embed & Sign”

完成后即可在三个示例中统一使用 Unity 视图（SDK 内部提供 `GrowthKit.createController` 与 `createView`）。

### 7.4 Info.plist 必要项（示例已预置）
- `CFBundleIdentifier`、`CFBundleVersion`、`CFBundleShortVersionString`、`CFBundleExecutable`、`CFBundleDisplayName/Name`
- 启动屏：为避免回退至旧布局（320×480），示例已设置：
  - ObjcExample/SwiftExample：`UILaunchStoryboardName = LaunchScreen`
  - SwiftUIExample：同样使用 Launch Screen（或 `UILaunchScreen`）

### 7.5 常见问题
- 运行界面仅 320×480：
  - 原因：缺少 Launch Screen 或工程恢复旧窗口尺寸
  - 处理：如上启用 `LaunchScreen.storyboard`，清理后重装
- 设备安装失败（invalid bundle / 缺键）：
  - 检查 Info.plist 是否包含 `CFBundleIdentifier/CFBundleExecutable` 等必备键
  - 清理（Product → Clean Build Folder），卸载设备上旧 App 后重装
- 找不到 UnityFramework：
  - 确认已在每个 Target 中添加并设置为“Embed & Sign”

### 7.6 一键生成（如需重新生成示例工程）
```bash
cd UnifiedExample
ruby scripts/gen_project.rb
pod install
open UnifiedExample.xcworkspace
```

更多细节请参见 `UnifiedExample/README.md`。