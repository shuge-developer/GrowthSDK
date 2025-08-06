# GameWrapper SDK 极简集成指南

## 🎯 SDK 设计理念

**完全黑盒化，外部零感知** - 外部只需提供游戏视图和截图提供者，所有复杂的多层级WebView交互、层级切换、事件穿透等逻辑全部由SDK内部处理。

## 🚀 核心特性

- ✅ **完全黑盒化**: 外部只需2个参数，无需了解内部实现
- ✅ **零感知集成**: 所有复杂逻辑SDK内部处理
- ✅ **自动层级管理**: 游戏层、WebView层、弹窗层自动切换
- ✅ **事件穿透机制**: 弹窗点击自动穿透到WebView广告
- ✅ **双框架支持**: 同时支持 SwiftUI 和 UIKit
- ✅ **截图遮盖**: 自动处理层级切换时的视觉连续性

## 🚀 极简集成示例

### SwiftUI 集成（推荐）

```swift
import SwiftUI
import GameWrapper

struct ContentView: View {
    var body: some View {
        // 只需一行代码，SDK处理所有复杂逻辑
        GameWrapperSwiftUIView(
            gameView: {
                // 你的游戏视图，只需实现UnityLoadable协议
                UnityGameView()
                    .setUnityStateCallback { loaded in
                        // 告知SDK Unity加载状态，其他无需关心
                        print("Unity加载状态: \(loaded)")
                    }
            },
            screenshotProvider: {
                // 提供游戏截图，用于层级切换时的视觉连续性
                return UnityServiceProvider.asyncUnityScreenshot()
            }
        )
    }
}

// 你的游戏视图只需实现UnityLoadable协议
struct UnityGameView: View, UnityLoadable {
    @State private var unityLoaded = false
    
    var body: some View {
        // 你的Unity游戏内容
        UnityView()
            .onAppear {
                // 模拟Unity加载完成
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    unityLoaded = true
                }
            }
    }
    
    func setUnityStateCallback(_ callback: @escaping (Bool) -> Void) -> Self {
        // 监听Unity状态变化并通知SDK
        if unityLoaded {
            callback(true)
        }
        return self
    }
}
```

### 3. UIKit 集成

```swift
class GameViewController: UIViewController {
    
    private var gameWrapperViewController: GameWrapperUIKitViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 创建 GameWrapper 视图控制器
        gameWrapperViewController = GameWrapperUIKitViewController(
            gameViewProvider: {
                // 返回你的游戏视图
                return self.createGameView()
            },
            screenshotProvider: {
                // 提供游戏截图
                return self.captureGameScreenshot()
            }
        )
        
        // 添加到视图层次结构
        addChild(gameWrapperViewController)
        view.addSubview(gameWrapperViewController.view)
        gameWrapperViewController.view.frame = view.bounds
        gameWrapperViewController.didMove(toParent: self)
    }
    
    private func createGameView() -> UIView {
        // 创建你的游戏视图
        return UIView()
    }
    
    private func captureGameScreenshot() -> UIImage? {
        // 捕获游戏截图
        return nil
    }
}
```

## 核心组件说明

### 1. GameWebWrapper
- **主管理器**: 负责 SDK 的初始化和配置
- **网络配置**: 设置 API 接口和加密参数
- **状态管理**: 监控 SDK 运行状态

### 2. GameWrapperLayerManager
- **层级管理**: 管理游戏层、WebView层、弹窗层的显示顺序
- **层级切换**: 提供 `bringUnityToTop()` 和 `bringWebViewToTop()` 方法
- **状态监控**: 通过 `@Published` 属性监控层级变化

### 3. GameWrapperSwiftUIView
- **SwiftUI 适配器**: 提供 SwiftUI 集成接口
- **游戏视图注入**: 通过 `@ViewBuilder` 接收外部游戏视图
- **截图提供者**: 通过闭包接收游戏截图

### 4. GameWrapperUIKitViewController
- **UIKit 适配器**: 提供 UIKit 集成接口
- **视图层次管理**: 管理游戏视图、WebView、弹窗的显示
- **生命周期管理**: 处理视图控制器的生命周期

## 层级切换机制

### 默认层级结构
```
层级3: 弹窗层 (zIndex: 200)
层级2: 游戏层 (zIndex: 99) 
层级1: WebView层 (zIndex: 10)
层级0: 多层WebView (zIndex: 0)
```

### 层级切换流程
1. **广告检测**: SingleLayerViewModel 检测到广告
2. **层级切换**: 调用 `bringWebViewToTop()` 将 WebView 置顶
3. **弹窗显示**: 根据广告位置显示引导弹窗
4. **用户点击**: 用户点击弹窗，触发广告点击
5. **层级恢复**: 调用 `bringUnityToTop()` 恢复游戏层

## 截图机制

### 截图提供者接口
```swift
typealias ScreenshotProvider = () -> UIImage?
```

### 截图使用场景
- **WebView 遮罩**: 在 WebView 上显示游戏截图作为遮罩
- **视觉连续性**: 保持用户视觉体验的连续性
- **层级切换**: 在层级切换时提供平滑的过渡效果

## 注意事项

### 1. Unity 集成
- SDK 不直接集成 Unity 相关代码
- 通过 `screenshotProvider` 接口获取游戏截图
- 游戏视图由外部提供，SDK 只负责层级管理

### 2. 权限要求
- 网络访问权限
- 本地存储权限（CoreData）

### 3. 生命周期管理
- 在 App 启动时初始化 SDK
- 在 App 退出时清理 SDK 资源
- 正确处理视图控制器的生命周期

## 故障排除

### 1. 初始化失败
- 检查网络配置参数
- 确认网络连接正常
- 查看控制台日志获取详细错误信息

### 2. 层级切换异常
- 确认游戏视图正确提供
- 检查截图提供者是否正常工作
- 验证 WebView 容器是否正确显示

### 3. 广告检测失败
- 检查网络配置和 API 接口
- 确认任务数据是否正确加载
- 查看 WebView 加载状态

## 示例项目

参考 SmallGame 项目的集成方式：
- `ContentView.swift`: 主视图结构
- `LayerZIndexManager.swift`: 层级管理
- `CustomPopupView.swift`: 弹窗组件
- `SingleLayerViewModel.swift`: WebView 管理 