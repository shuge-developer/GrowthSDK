# GrowthKit SDK 统一API集成指南

## 🎯 新的API设计

### 核心组件
- `GrowthKitManager`: 统一管理器
- `GrowthKitSwiftUIAdapter`: SwiftUI适配器  
- `GrowthKitUIKitAdapter`: UIKit适配器

## 🚀 快速集成

### SwiftUI项目
```swift
import SwiftUI
import GrowthKit

struct ContentView: View {
    @StateObject private var growthKitManager = GrowthKitManager.shared
    @State private var unityController: UIViewController?
    
    var body: some View {
        Group {
            if let controller = unityController {
                GrowthKitSwiftUIAdapter()
                    .ignoresSafeArea()
                    .onAppear {
                        growthKitManager.setUnityController(controller)
                    }
            } else {
                ProgressView("正在初始化Unity...")
            }
        }
        .onAppear {
            initializeSDK()
            initializeUnity()
        }
    }
    
    private func initializeSDK() {
        let config = GrowthKitConfig(
            appid: "your_app_id",
            bundleName: Bundle.main.bundleIdentifier ?? "com.example.app",
            baseUrl: "https://api.example.com",
            publicKey: "your_public_key",
            appKey: "your_app_key",
            appIv: "your_app_iv"
        )
        
        GrowthKitManager.shared.initialize(config: config) { result in
            print("SDK初始化: \(result)")
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

### UIKit项目
```swift
import UIKit
import GrowthKit

class GameViewController: UIViewController {
    private var unityController: UIViewController?
    private var growthKitAdapter: GrowthKitUIKitAdapter?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGrowthKitAdapter()
        initializeSDK()
        initializeUnity()
    }
    
    private func setupGrowthKitAdapter() {
        growthKitAdapter = GrowthKitUIKitAdapter()
        addChild(growthKitAdapter!)
        view.addSubview(growthKitAdapter!.view)
        growthKitAdapter!.didMove(toParent: self)
        
        growthKitAdapter!.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            growthKitAdapter!.view.topAnchor.constraint(equalTo: view.topAnchor),
            growthKitAdapter!.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            growthKitAdapter!.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            growthKitAdapter!.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func initializeSDK() {
        let config = GrowthKitConfig(
            appid: "your_app_id",
            bundleName: Bundle.main.bundleIdentifier ?? "com.example.app",
            baseUrl: "https://api.example.com",
            publicKey: "your_public_key",
            appKey: "your_app_key",
            appIv: "your_app_iv"
        )
        
        GrowthKitManager.shared.initialize(config: config) { result in
            print("SDK初始化: \(result)")
        }
    }
    
    private func initializeUnity() {
        UnityManager.shared.initializeUnity { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let controller):
                    self?.unityController = controller
                    GrowthKitManager.shared.setUnityController(controller)
                    self?.setupUnityIntegration(controller)
                case .failure(let error):
                    print("Unity初始化失败: \(error)")
                }
            }
        }
    }
    
    private func setupUnityIntegration(_ controller: UIViewController) {
        guard let adapter = growthKitAdapter else { return }
        
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
}
```

## 📱 API参考

### GrowthKitManager
- `initialize(config:completion:)` - 初始化SDK
- `setUnityController(_:)` - 设置Unity控制器
- `bringGameToTop()` - 切换到游戏层
- `bringWebViewToTop()` - 切换到WebView层
- `closePopup()` - 关闭弹窗

### 状态监听
```swift
GrowthKitManager.shared.$isInitialized
    .sink { isInitialized in
        print("SDK初始化状态: \(isInitialized)")
    }
    .store(in: &cancellables)

GrowthKitManager.shared.$currentLayerType
    .sink { layerType in
        print("当前层级: \(layerType)")
    }
    .store(in: &cancellables)
```

## 🎉 优势

1. **统一API**: 一套代码支持SwiftUI和UIKit
2. **简化集成**: 隐藏内部实现细节
3. **类型安全**: 利用Swift类型系统
4. **状态管理**: 完整的生命周期管理
5. **易于维护**: 清晰的架构设计
