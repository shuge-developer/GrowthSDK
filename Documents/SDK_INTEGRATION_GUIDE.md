# GrowthSDK SDK 集成指南

## 概述

GrowthSDK SDK 是一个用于在Unity游戏上层叠加WebView广告内容的多层级视图交互系统。通过巧妙的层级切换和事件穿透机制来实现广告点击，支持SwiftUI和UIKit两种集成方式。

## 功能特性

- ✅ 多层级视图管理（游戏层、WebView层、弹窗层）
- ✅ 自动层级切换和事件穿透
- ✅ 游戏截图遮罩技术
- ✅ 广告检测和点击处理
- ✅ SwiftUI 和 UIKit 双框架支持
- ✅ 完整的生命周期管理
- ✅ 实时状态监控

## 集成步骤

### 1. 初始化 SDK

```swift
import GrowthSDK

// 1. 设置网络配置
let config = NetworkConfig(
    appid: "your_app_id",
    bundleName: "your_bundle_name", 
    baseUrl: "https://your_api_base_url",
    publicKey: "your_public_key",
    appKey: "your_app_key",
    appIv: "your_app_iv"
)

GameWebWrapper.shared.setup(network: config)

// 2. 初始化 SDK
GameWebWrapper.shared.initialize { result in
    switch result {
    case .success:
        print("SDK 初始化成功")
    case .failure(let error):
        print("SDK 初始化失败: \(error)")
    }
}
```

### 2. SwiftUI 集成方式

#### 2.1 基本集成

```swift
import SwiftUI
import GrowthSDK

struct GameContentView: View {
    @StateObject private var gameWrapperManager = GrowthSDKManager.shared
    
    var body: some View {
        ZStack {
            // 游戏视图（Unity或其他游戏引擎）
            UnityGameView()
            
            // GrowthSDK SDK 视图
            GrowthSDKSwiftUIView()
        }
        .onAppear {
            // 启动 SDK
            gameWrapperManager.start { result in
                switch result {
                case .success:
                    print("GrowthSDK 启动成功")
                case .failure(let error):
                    print("GrowthSDK 启动失败: \(error)")
                }
            }
        }
        .onDisappear {
            // 停止 SDK
            gameWrapperManager.stop()
        }
    }
}
```

#### 2.2 自定义游戏视图集成

```swift
struct CustomGrowthSDKView: View {
    @StateObject private var gameWrapperManager = GrowthSDKManager.shared
    
    var body: some View {
        ZStack {
            // 自定义游戏视图
            YourGameView()
                .zIndex(gameWrapperManager.topLayerType == .game ? 99 : 10)
            
            // WebView 层
            if gameWrapperManager.topLayerType == .webView {
                WebViewLayer()
                    .zIndex(99)
            }
            
            // 弹窗层
            PopupLayer()
                .zIndex(200)
        }
        .onReceive(gameWrapperManager.$topLayerType) { layerType in
            print("当前顶层: \(layerType.displayName)")
        }
    }
}
```

### 3. UIKit 集成方式

#### 3.1 基本集成

```swift
import UIKit
import GrowthSDK

class GameViewController: UIViewController {
    
    private var gameWrapperViewController: GrowthSDKUIKitViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 创建 GrowthSDK 视图控制器
        gameWrapperViewController = GrowthSDKUIKitViewController()
        addChild(gameWrapperViewController)
        view.addSubview(gameWrapperViewController.view)
        gameWrapperViewController.didMove(toParent: self)
        
        // 设置约束
        gameWrapperViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            gameWrapperViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            gameWrapperViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gameWrapperViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gameWrapperViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // 设置游戏视图
        let gameView = createGameView()
        gameWrapperViewController.setGameView(gameView)
        
        // 启动 SDK
        GrowthSDKManager.shared.start { result in
            switch result {
            case .success:
                print("GrowthSDK 启动成功")
            case .failure(let error):
                print("GrowthSDK 启动失败: \(error)")
            }
        }
    }
    
    private func createGameView() -> UIView {
        // 创建你的游戏视图（Unity、Cocos2d等）
        let gameView = UIView()
        gameView.backgroundColor = .black
        return gameView
    }
}
```

#### 3.2 高级集成

```swift
class AdvancedGameViewController: UIViewController {
    
    private var gameWrapperViewController: GrowthSDKUIKitViewController!
    private var gameWrapperManager = GrowthSDKManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGrowthSDK()
        setupObservers()
    }
    
    private func setupGrowthSDK() {
        // 创建 GrowthSDK 视图控制器
        gameWrapperViewController = GrowthSDKUIKitViewController()
        addChild(gameWrapperViewController)
        view.addSubview(gameWrapperViewController.view)
        gameWrapperViewController.didMove(toParent: self)
        
        // 设置约束
        gameWrapperViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            gameWrapperViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            gameWrapperViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gameWrapperViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gameWrapperViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // 设置游戏视图
        let gameView = createUnityGameView()
        gameWrapperViewController.setGameView(gameView)
    }
    
    private func setupObservers() {
        // 监听层级变化
        gameWrapperManager.$topLayerType
            .sink { [weak self] layerType in
                self?.handleLayerChange(layerType)
            }
            .store(in: &cancellables)
        
        // 监听状态变化
        gameWrapperManager.$status
            .sink { [weak self] status in
                self?.handleStatusChange(status)
            }
            .store(in: &cancellables)
    }
    
    private func handleLayerChange(_ layerType: LayerType) {
        switch layerType {
        case .game:
            // 游戏层置顶，恢复游戏交互
            resumeGameInteraction()
        case .webView:
            // WebView层置顶，暂停游戏交互
            pauseGameInteraction()
        }
    }
    
    private func handleStatusChange(_ status: GrowthSDKStatus) {
        switch status {
        case .ready:
            print("GrowthSDK 准备就绪")
        case .running:
            print("GrowthSDK 正在运行")
        case .error(let error):
            print("GrowthSDK 发生错误: \(error)")
        default:
            break
        }
    }
}
```

### 4. 设置游戏截图提供者

为了支持层级切换时的游戏截图遮罩功能，需要设置截图提供者：

```swift
// 设置截图提供者
GrowthSDKManager.shared.setScreenshotProvider { [weak self] in
    // 返回当前游戏画面的截图
    return self?.captureGameScreenshot()
}

private func captureGameScreenshot() -> UIImage? {
    // 根据你的游戏引擎实现截图逻辑
    // Unity 示例：
    // return UnityServiceProvider.asyncUnityScreenshot()
    
    // Cocos2d 示例：
    // return CCDirector.shared.screenshot()
    
    // 通用截图方法：
    guard let window = UIApplication.shared.windows.first else { return nil }
    UIGraphicsBeginImageContextWithOptions(window.bounds.size, false, 0)
    window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
    let screenshot = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return screenshot
}
```

### 5. 代理回调设置

```swift
// 设置层级切换代理
GrowthSDKManager.shared.layerDelegate = self

// 设置 WebView 事件代理
GrowthSDKManager.shared.webViewDelegate = self

// 实现代理方法
extension GameViewController: GrowthSDKLayerDelegate {
    func layerSwitchWillBegin() {
        print("层级切换即将开始")
    }
    
    func layerSwitchDidComplete() {
        print("层级切换完成")
    }
    
    func layerSwitchDidFail(_ error: Error) {
        print("层级切换失败: \(error)")
    }
}

extension GameViewController: GrowthSDKWebViewDelegate {
    func webViewDidFinishLoad() {
        print("WebView 加载完成")
    }
    
    func webViewDidFailLoad(_ error: Error) {
        print("WebView 加载失败: \(error)")
    }
    
    func adDidClick() {
        print("广告被点击")
    }
}
```

## 配置说明

### 网络配置参数

| 参数 | 类型 | 说明 |
|------|------|------|
| appid | String | 应用ID |
| bundleName | String | Bundle名称 |
| baseUrl | String | API基础URL |
| publicKey | String | 公钥 |
| appKey | String | 应用密钥 |
| appIv | String | 初始化向量 |

### 层级类型

| 类型 | 说明 |
|------|------|
| game | 游戏层（默认顶层） |
| webView | WebView层（广告层） |

### SDK状态

| 状态 | 说明 |
|------|------|
| notInitialized | 未初始化 |
| initializing | 初始化中 |
| ready | 准备就绪 |
| running | 运行中 |
| paused | 已暂停 |
| error | 错误状态 |

## 最佳实践

### 1. 生命周期管理

```swift
class GameViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGrowthSDK()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        GrowthSDKManager.shared.start { _ in }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        GrowthSDKManager.shared.stop()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // 可选：清理资源
        GameWebWrapper.shared.cleanup()
    }
}
```

### 2. 错误处理

```swift
GrowthSDKManager.shared.start { result in
    switch result {
    case .success:
        print("SDK 启动成功")
    case .failure(let error):
        print("SDK 启动失败: \(error.localizedDescription)")
        
        // 根据错误类型进行处理
        if let wrapperError = error as? GrowthSDKInitError {
            switch wrapperError {
            case .configNotSet:
                print("请先设置网络配置")
            case .coreDataInitFailed(let message):
                print("CoreData 初始化失败: \(message)")
            case .taskRepositoryInitFailed(let message):
                print("任务仓库初始化失败: \(message)")
            }
        }
    }
}
```

### 3. 性能优化

```swift
// 1. 延迟初始化
private func setupGrowthSDKLazily() {
    DispatchQueue.global(qos: .userInitiated).async {
        // 在后台线程进行初始化
        GameWebWrapper.shared.initialize { result in
            DispatchQueue.main.async {
                // 在主线程处理结果
                self.handleInitializationResult(result)
            }
        }
    }
}

// 2. 内存管理
private func cleanupResources() {
    // 清理 WebView 缓存
    GameWebView.cleanupSharedResources()
    
    // 清理任务数据
    TaskRepository.shared.clearAllData()
    
    // 重置管理器状态
    GrowthSDKManager.shared.stop()
}
```

## 常见问题

### Q1: 如何自定义弹窗样式？

A: 可以通过修改 `CustomPopupView.swift` 或 `GrowthSDKUIKitViewController.swift` 中的弹窗实现来自定义样式。

### Q2: 如何控制广告展示时机？

A: 通过调用 `GrowthSDKManager.shared.switchLayer(to: .webView)` 来手动触发层级切换。

### Q3: 如何获取广告点击事件？

A: 实现 `GrowthSDKWebViewDelegate` 协议中的 `adDidClick()` 方法。

### Q4: 如何调试层级切换？

A: 监听 `GrowthSDKManager.shared.$topLayerType` 来观察层级变化。

## 技术支持

如果在集成过程中遇到问题，请：

1. 检查控制台日志输出
2. 确认网络配置正确
3. 验证初始化流程完整
4. 查看错误回调信息

更多技术细节请参考源码注释和API文档。 