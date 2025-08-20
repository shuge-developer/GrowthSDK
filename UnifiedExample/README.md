# UnifiedExample 多 Target 集成示例

该工程包含三个 target（ObjcExample/SwiftExample/SwiftUIExample），统一引入 `UnityProject`（发布仓库中默认不包含 Unity 原始子工程，请按下文手动添加），并通过 CocoaPods 管理第三方依赖。

## 目录结构
- UnityProject：Unity iOS 子工程目录（发布仓库完全忽略该目录；请在本地手动新建 `UnityProject/` 目录，并将 Unity 导出的 iOS 工程拷入该目录）
- ObjcExample：Objective-C 示例源文件
- SwiftExample：Swift 示例源文件
- SwiftUIExample：SwiftUI 示例源文件

## 快速开始

### 0. 准备 Unity 子工程（首次必做）
发布仓库不包含 Unity 工程，请先在本地创建目录并拷贝 Unity iOS 导出：
```bash
cd UnifiedExample
mkdir -p UnityProject
# 将你本地 Unity 导出的 iOS 工程完整复制到当前目录下的 UnityProject/
```

### 1. 打开工程
```bash
# 打开工作区（必须使用 .xcworkspace，不要使用 .xcodeproj）
open UnifiedExample.xcworkspace
```

### 2. 选择 Target
在 Xcode 中选择要运行的 Target：
- `ObjcExample` - Objective-C 示例
- `SwiftExample` - Swift 示例  
- `SwiftUIExample` - SwiftUI 示例

### 3. 配置 Unity Framework（重要）
由于 Unity 子工程的自动配置较复杂，需要手动完成以下步骤：

1. 在 Xcode 中选择任意一个 App Target
2. 进入 "Build Phases" → "Frameworks, Libraries, and Embedded Content"
3. 点击 "+" 按钮
4. 在 "Unity-iPhone.xcodeproj" → "Products" 下找到 `UnityFramework.framework`（若看不到 `Unity-iPhone.xcodeproj`，请先执行上面的“准备 Unity 子工程”步骤：新建 `UnityProject/` 并拷入 Unity iOS 工程）
5. 将其添加到当前 Target，并设置为 "Embed & Sign"
6. 对另外两个 App Target 重复此步骤

### 4. 必要的 Info.plist 配置（已预置）
- CFBundleIdentifier = $(PRODUCT_BUNDLE_IDENTIFIER)
- CFBundleShortVersionString = 1.0
- CFBundleVersion = 1
- CFBundleExecutable = $(EXECUTABLE_NAME)
- CFBundleDisplayName/CFBundleName = $(PRODUCT_NAME)
- 启动屏：
  - ObjcExample/SwiftExample：`UILaunchStoryboardName = LaunchScreen`
  - SwiftUIExample：`UILaunchStoryboardName = LaunchScreen`
  说明：未配置 Launch Screen 时，可能出现 320×480 的旧布局尺寸。

### 5. 运行示例
选择目标设备或模拟器，点击运行按钮即可。

## 重新生成工程

如果需要重新生成工程文件：

```bash
# 安装脚本依赖
sudo gem install xcodeproj --no-document

# 生成 Xcode 工程
ruby scripts/gen_project.rb

# 安装 Pods
pod install
```

## 故障排除

### Xcode 崩溃问题
如果打开工程时 Xcode 崩溃，请尝试以下步骤：

1. 删除生成的工程文件：
   ```bash
   rm -rf UnifiedExample.xcodeproj
   rm -rf UnifiedExample.xcworkspace
   ```

2. 重新生成工程：
   ```bash
   ruby scripts/gen_project.rb
   pod install
   ```

3. 使用命令行验证工程：
   ```bash
   xcodebuild -workspace UnifiedExample.xcworkspace -list
   ```

### Unity Framework 链接问题
如果运行时提示找不到 Unity Framework：

1. 确保已按上述步骤手动添加 `UnityFramework.framework`
2. 检查 "Embed & Sign" 设置
3. 确保 Unity 子工程路径正确：`UnityProject/Unity-iPhone.xcodeproj`

### 320×480 小屏问题（已修复方式）
- 现象：真机为 iPhone X/XS 等，但界面仅 320×480。
- 原因：缺少 Launch Screen 或工程恢复旧版窗口尺寸。
- 解决：为各 Target 设置 `UILaunchStoryboardName = LaunchScreen`，并确保使用 `.xcworkspace` 打开。

### 设备安装失败（Invalid bundle/缺键）
- 错误：`missing or invalid CFBundleIdentifier/CFBundleExecutable`。
- 解决：确认上文 Info.plist 必备键存在；改完后 Clean、删除设备上旧 App、再安装。

## 依赖说明
- GrowthSDK：本地 SDK 依赖（通过 `:path => '..'` 添加）
- AppLovinSDK：广告 SDK
- KwaiAdsSDK：快手广告 SDK

## 注意事项
- 必须使用 `.xcworkspace` 文件打开工程，不要使用 `.xcodeproj`
- 三个 target 共享相同的 Pod 依赖版本
- Unity 子工程需要手动配置 Framework 链接
- 所有示例都包含 `UnityManager.swift`，可直接调用 Unity 功能

---

附：一键生成与安装
```bash
cd UnifiedExample
ruby scripts/gen_project.rb
pod install
open UnifiedExample.xcworkspace
```
