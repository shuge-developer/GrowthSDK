# GrowthSDK SDK 统一API集成指南

## 🎯 新的API设计理念

### 问题解决
- **统一管理**: 通过`GrowthSDKManager`统一管理SDK生命周期
- **框架无关**: 提供SwiftUI和UIKit两种适配器
- **简化集成**: 隐藏内部实现细节，提供简洁的API
- **类型安全**: 使用Swift的类型系统确保API安全性

### 核心组件
- `GrowthSDKManager`: 统一管理器
- `GrowthSDKSwiftUIAdapter`: SwiftUI适配器
- `GrowthSDKUIKitAdapter`: UIKit适配器

## 🚀 快速开始

### 1. 初始化SDK

```swift
import GrowthSDK

// 创建配置
let config = GrowthSDKConfig(
    appid: "your_app_id",
    bundleName: Bundle.main.bundleIdentifier ?? "com.example.app",
    baseUrl: "https://api.example.com",
    publicKey: "your_public_key",
    appKey: "your_app_key",
    appIv: "your_app_iv"
)

// 初始化SDK
GrowthSDKManager.shared.initialize(config: config) { result in
    switch result {
    case .success:
        print("SDK初始化成功")
    case .failure(let error):
        print("SDK初始化失败: \(error)")
    }
}
```

### 2. SwiftUI集成

```swift
import SwiftUI
import GrowthSDK

struct ContentView: View {
    @StateObject private var growthKitManager = GrowthSDKManager.shared
    @State private var unityController: UIViewController?
    
    var body: some View {
        Group {
            if let controller = unityController {
                GrowthSDKSwiftUIAdapter()
                    .ignoresSafeArea()
                    .onAppear {
                        growthKitManager.setUnityController(controller)
                    }
            } else {
                ProgressView("正在初始化Unity...")
            }
        }
        .onAppear {
            initializeUnity()
        }
    }
    
    private func initializeUnity() {
        UnityManager.shared.initializeUnity { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let controller):
                    self.unityController = controller
                case .failure(let error):
                    print("Unity初始化失败: \(error)")
                }
            }
        }
    }
}
```

### 3. UIKit集成

```swift
import UIKit
import GrowthSDK

class GameViewController: UIViewController {
    private var unityController: UIViewController?
    private var growthKitAdapter: GrowthSDKUIKitAdapter?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGrowthSDKAdapter()
        initializeUnity()
    }
    
    private func setupGrowthSDKAdapter() {
        growthKitAdapter = GrowthSDKUIKitAdapter()
        addChild(growthKitAdapter!)
        view.addSubview(growthKitAdapter!.view)
        growthKitAdapter!.didMove(toParent: self)
        
        // 设置约束
        growthKitAdapter!.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            growthKitAdapter!.view.topAnchor.constraint(equalTo: view.topAnchor),
            growthKitAdapter!.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            growthKitAdapter!.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            growthKitAdapter!.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func initializeUnity() {
        UnityManager.shared.initializeUnity { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let controller):
                    self?.unityController = controller
                    GrowthSDKManager.shared.setUnityController(controller)
                    
                    // 将Unity视图添加到适配器
                    if let adapter = self?.growthKitAdapter {
                        adapter.addChild(controller)
                        adapter.view.addSubview(controller.view)
                        controller.didMove(toParent: adapter)
                        
                        controller.view.translatesAutoresizingMaskIntoConstraints = false
                        NSLayoutConstraint.activate([
                            controller.view.topAnchor.constraint(equalTo: adapter.view.topAnchor),
                            controller.view.leadingAnchor.constraint(equalTo: adapter.view.leadingAnchor),
                            controller.view.trailingAnchor.constraint(equalTo: adapter.view.trailingAnchor),
                            controller.view.bottomAnchor.constraint(equalTo: adapter.view.bottomAnchor)
                        ])
                    }
                case .failure(let error):
                    print("Unity初始化失败: \(error)")
                }
            }
        }
    }
}
```

## 📱 API参考

### GrowthSDKManager

#### 属性
- `isInitialized: Bool` - SDK是否已初始化
- `currentLayerType: LayerType` - 当前层级类型
- `showPopupView: Bool` - 是否显示弹窗

#### 方法
- `initialize(config:completion:)` - 初始化SDK
- `setUnityController(_:)` - 设置Unity控制器
- `bringGameToTop()` - 切换到游戏层
- `bringWebViewToTop()` - 切换到WebView层
- `closePopup()` - 关闭弹窗

### GrowthSDKSwiftUIAdapter

SwiftUI视图适配器，自动处理层级管理和视图更新。

### GrowthSDKUIKitAdapter

UIKit视图控制器适配器，提供完整的视图生命周期管理。

## 🔄 层级管理

### 自动层级切换
SDK会根据业务逻辑自动切换层级：
- 游戏正常运行时：Unity层在上
- 检测到广告时：WebView层在上，显示弹窗
- 用户关闭弹窗：自动切换回Unity层

### 手动层级控制
```swift
// 切换到游戏层
GrowthSDKManager.shared.bringGameToTop()

// 切换到WebView层
GrowthSDKManager.shared.bringWebViewToTop()

// 关闭弹窗
GrowthSDKManager.shared.closePopup()
```

## 📊 状态监听

### 使用Combine监听状态
```swift
import Combine

class GameViewController: UIViewController {
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupStatusMonitoring()
    }
    
    private func setupStatusMonitoring() {
        // 监听初始化状态
        GrowthSDKManager.shared.$isInitialized
            .sink { isInitialized in
                print("SDK初始化状态: \(isInitialized)")
            }
            .store(in: &cancellables)
        
        // 监听层级变化
        GrowthSDKManager.shared.$currentLayerType
            .sink { layerType in
                print("当前层级: \(layerType)")
            }
            .store(in: &cancellables)
        
        // 监听弹窗状态
        GrowthSDKManager.shared.$showPopupView
            .sink { show in
                print("弹窗显示状态: \(show)")
            }
            .store(in: &cancellables)
    }
}
```

## 🎮 Unity集成

### UnityManager使用
```swift
// 初始化Unity
UnityManager.shared.initializeUnity { result in
    switch result {
    case .success(let controller):
        // 将控制器传递给GrowthSDK
        GrowthSDKManager.shared.setUnityController(controller)
    case .failure(let error):
        print("Unity初始化失败: \(error)")
    }
}

// 发送消息到Unity
let message = UnityMessage(
    obj: "GameManager",
    method: "OnAdClicked",
    msg: "ad_clicked"
)
UnityManager.shared.sendMessage(message)
```

## 🔧 配置说明

### NetworkConfigurable协议
```swift
public protocol NetworkConfigurable {
    var appid: String { get }
    var bundleName: String { get }
    var baseUrl: String { get }
    var publicKey: String { get }
    var appKey: String { get }
    var appIv: String { get }
}
```

### 配置示例
```swift
struct GrowthSDKConfig: NetworkConfigurable {
    let appid: String
    let bundleName: String
    let baseUrl: String
    let publicKey: String
    let appKey: String
    let appIv: String
}

let config = GrowthSDKConfig(
    appid: "your_app_id",
    bundleName: Bundle.main.bundleIdentifier ?? "com.example.app",
    baseUrl: "https://api.example.com",
    publicKey: "your_public_key",
    appKey: "your_app_key",
    appIv: "your_app_iv"
)
```

## 🚨 注意事项

### 1. 初始化顺序
1. 先初始化GrowthSDK SDK
2. 再初始化Unity
3. 最后设置Unity控制器

### 2. 内存管理
- 使用`weak self`避免循环引用
- 及时清理`cancellables`集合

### 3. 线程安全
- 所有UI更新必须在主线程进行
- 使用`DispatchQueue.main.async`确保线程安全

### 4. 错误处理
- 始终处理初始化失败的情况
- 提供用户友好的错误提示

## 📝 迁移指南

### 从旧API迁移

#### 旧版本
```swift
// 旧版本使用GrowthSDKSwiftUIView
GrowthSDKSwiftUIView(unityController: controller)
```

#### 新版本
```swift
// 新版本使用GrowthSDKSwiftUIAdapter
GrowthSDKSwiftUIAdapter()
// 然后设置Unity控制器
GrowthSDKManager.shared.setUnityController(controller)
```

### 主要变化
1. 不再需要直接传递Unity控制器给视图
2. 通过`GrowthSDKManager`统一管理
3. 更好的状态管理和错误处理
4. 支持UIKit和SwiftUI两种框架

## 🎉 总结

新的API设计提供了：
- **统一的接口**: 一套API支持两种框架
- **更好的封装**: 隐藏内部实现细节
- **类型安全**: 利用Swift类型系统
- **易于使用**: 简化的集成流程
- **状态管理**: 完整的生命周期管理

通过这个新的API设计，开发者可以更轻松地在SwiftUI和UIKit项目中集成GrowthSDK SDK，享受统一的开发体验。
