# GrowthKit SDK 最终集成指南

## 🎉 编译成功！

经过修复，GrowthKit SDK 现在已经可以正常编译了。以下是完整的集成指南。

## 📋 功能特性

- ✅ **多层级视图管理**: 游戏层、WebView层、弹窗层的动态切换
- ✅ **事件穿透机制**: 弹窗点击事件穿透到下层WebView
- ✅ **截图遮罩技术**: 游戏截图作为WebView遮罩，保持视觉连续性
- ✅ **广告检测处理**: 自动检测和点击广告元素
- ✅ **双框架支持**: 同时支持 SwiftUI 和 UIKit
- ✅ **最小侵入性**: 不集成Unity相关代码，通过接口与游戏交互

## 🚀 快速开始

### 1. 初始化 SDK

```swift
import GrowthKit

// 设置网络配置
let config = NetworkConfig(
    appid: "your_app_id",
    bundleName: "your_bundle_name", 
    baseUrl: "https://your_api_base_url",
    publicKey: "your_public_key",
    appKey: "your_app_key",
    appIv: "your_app_iv"
)

GameWebWrapper.shared.setup(network: config)

// 初始化 SDK
GameWebWrapper.shared.initialize { result in
    switch result {
    case .success:
        print("SDK 初始化成功")
    case .failure(let error):
        print("SDK 初始化失败: \(error)")
    }
}
```

### 2. SwiftUI 集成

```swift
import SwiftUI
import GrowthKit

struct ContentView: View {
    var body: some View {
        GrowthKitSwiftUIView(
            gameView: {
                // 你的游戏视图
                UnityViewWrapper()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            },
            screenshotProvider: {
                // 提供游戏截图的方法
                return UnityViewWrapper.shared.takeScreenshot()
            }
        )
    }
}
```

### 3. UIKit 集成

```swift
import UIKit
import GrowthKit

class GameViewController: UIViewController {
    
    private var gameWrapperViewController: GrowthKitUIKitViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 创建 GrowthKit 视图控制器
        gameWrapperViewController = GrowthKitUIKitViewController(
            gameViewProvider: {
                // 返回你的游戏视图
                return self.createGameView()
            },
            screenshotProvider: {
                // 提供游戏截图的方法
                return self.takeGameScreenshot()
            }
        )
        
        // 添加到视图层级
        addChild(gameWrapperViewController)
        view.addSubview(gameWrapperViewController.view)
        gameWrapperViewController.view.frame = view.bounds
        gameWrapperViewController.didMove(toParent: self)
    }
    
    private func createGameView() -> UIView {
        // 创建你的游戏视图
        return UIView() // 替换为实际的游戏视图
    }
    
    private func takeGameScreenshot() -> UIImage? {
        // 实现游戏截图逻辑
        return nil // 替换为实际的截图逻辑
    }
}
```

## 🎮 层级管理

### 手动控制层级切换

```swift
import GrowthKit

// 获取层级管理器
let layerManager = GrowthKitLayerManager.shared

// 切换Unity到顶层
layerManager.bringUnityToTop()

// 切换WebView到顶层
layerManager.bringWebViewToTop()

// 切换到下一个层级（轮流切换）
layerManager.switchToNextLayer()

// 重置为默认层级
layerManager.resetToDefault()
```

### 监听层级变化

```swift
import Combine

class GameViewController: UIViewController {
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 监听层级变化
        GrowthKitLayerManager.shared.$topLayerType
            .sink { layerType in
                print("当前顶层: \(layerType.displayName)")
            }
            .store(in: &cancellables)
    }
}
```

## 🔧 高级配置

### 自定义弹窗位置

```swift
import GrowthKit

// 获取弹窗位置管理器
let popupManager = PopupPositionManager.shared

// 监听位置变化
popupManager.$currentPosition
    .sink { position in
        print("弹窗位置: \(position)")
    }
    .store(in: &cancellables)
```

### 任务管理

```swift
import GrowthKit

// 开始任务处理
SingleLayerViewModel.shared.startTaskProcess()

// 监听任务状态
SingleLayerViewModel.shared.$currentTask
    .compactMap { $0 }
    .sink { task in
        print("当前任务: \(task.taskDescription)")
    }
    .store(in: &cancellables)
```

## 📱 在 SmallGame 项目中的集成

### 修改 ContentView.swift

```swift
import SwiftUI
import GrowthKit

struct ContentView: View {
    @StateObject private var startManager = H5TaskStartManager.shared
    @StateObject private var lifecycleManager = UnityLifecycleManager.shared
    
    var body: some View {
        ZStack {
            // 使用 GrowthKit SDK
            GrowthKitSwiftUIView(
                gameView: {
                    UnityViewWrapper()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                },
                screenshotProvider: {
                    // 提供Unity截图
                    return UnityViewWrapper.shared.takeScreenshot()
                }
            )
            
            // 调试按钮（可选）
            VStack {
                Spacer()
                HStack {
                    Button("开始任务") {
                        startManager.startH5Task()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    Spacer()
                }
                .padding()
            }
        }
        .onAppear {
            // 初始化SDK（如果还没有初始化）
            if !GameWebWrapper.shared.isInitialized {
                // 这里应该已经初始化过了
            }
        }
    }
}
```

## 🐛 故障排除

### 常见问题

1. **编译错误**: 确保所有依赖都已正确安装
2. **初始化失败**: 检查网络配置参数是否正确
3. **层级切换不生效**: 确保游戏视图正确提供
4. **截图失败**: 检查截图提供者方法是否正确实现

### 调试模式

```swift
// 启用详细日志
GameWebWrapper.shared.enableDebugMode()

// 查看当前状态
print("SDK 状态: \(GameWebWrapper.shared.initStatus)")
print("是否已初始化: \(GameWebWrapper.shared.isInitialized)")
```

## 📚 API 参考

### 主要类

- `GameWebWrapper`: SDK 主管理器
- `GrowthKitLayerManager`: 层级管理器
- `GrowthKitSwiftUIView`: SwiftUI 适配器视图
- `GrowthKitUIKitViewController`: UIKit 适配器视图控制器
- `PopupPositionManager`: 弹窗位置管理器
- `SingleLayerViewModel`: 单层WebView视图模型

### 主要枚举

- `LayerType`: 层级类型（unity, webView）
- `PopupPosition`: 弹窗位置（top, center, bottom）
- `GrowthKitInitStatus`: 初始化状态
- `GrowthKitInitError`: 初始化错误类型

## 🎯 最佳实践

1. **初始化时机**: 在 App 启动时尽早初始化 SDK
2. **错误处理**: 始终处理初始化失败的情况
3. **内存管理**: 使用 `weak self` 避免循环引用
4. **状态监听**: 监听相关状态变化，及时响应用户操作
5. **测试**: 在不同设备和iOS版本上测试集成效果

## 📞 技术支持

如果在集成过程中遇到问题，请检查：

1. SDK 版本是否最新
2. 网络配置是否正确
3. 游戏视图是否正确提供
4. 截图方法是否正确实现

---

**GrowthKit SDK** - 让游戏与WebView完美融合！🎮✨ 