# GrowthSDK SDK 简化集成指南

## 🎯 设计理念

基于你的建议，我们采用了更合理和优雅的方案：
- **SDK在App启动时初始化** - 越早越好，避免延迟
- **GrowthSDKUIKitBridge作为根控制器** - 避免视图层级问题
- **保持SwiftUI项目的优雅集成** - 不修改现有实现
- **最小化集成成本** - 简单直接的API设计

## 🚀 快速集成

### SwiftUI项目（保持不变）
```swift
import SwiftUI
import GrowthSDK

struct ContentView: View {
    @State private var unityController: UIViewController?
    
    var body: some View {
        Group {
            if let controller = unityController {
                GrowthSDKSwiftUIView(unityController: controller)
                    .ignoresSafeArea()
            } else {
                EmptyView()
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

### UIKit项目（新架构）

#### 1. AppDelegate - SDK初始化
```swift
import UIKit
import GrowthSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // 在应用启动时尽早初始化GrowthSDK SDK
        initializeGrowthSDKSDK()
        
        return true
    }
    
    private func initializeGrowthSDKSDK() {
        let config = GrowthSDKConfig(
            appid: "your_app_id",
            bundleName: Bundle.main.bundleIdentifier ?? "com.example.app",
            baseUrl: "https://api.example.com",
            publicKey: "your_public_key",
            appKey: "your_app_key",
            appIv: "your_app_iv"
        )
        
        GameWebWrapper.shared.initialize(config: config) { result in
            print("SDK初始化: \(result)")
        }
    }
}
```

#### 2. SceneDelegate - 根控制器设置
```swift
import UIKit
import GrowthSDK

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    private var growthKitBridge: GrowthSDKUIKitBridge?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // 创建窗口
        window = UIWindow(windowScene: windowScene)
        
        // 初始化Unity和GrowthSDK集成
        initializeUnityAndGrowthSDK()
    }
    
    private func initializeUnityAndGrowthSDK() {
        // 初始化Unity
        UnityManager.shared.initializeUnity { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let unityController):
                    self?.setupGrowthSDKBridge(unityController)
                case .failure(let error):
                    print("Unity初始化失败: \(error)")
                }
            }
        }
    }
    
    private func setupGrowthSDKBridge(_ unityController: UIViewController) {
        // 创建GrowthSDK桥接器作为根控制器
        growthKitBridge = GrowthSDKUIKitBridge(unityController: unityController)
        
        // 设置为根控制器
        window?.rootViewController = growthKitBridge
        window?.makeKeyAndVisible()
    }
}
```

## 📱 架构优势

### 1. 早期初始化
- **SDK在App启动时初始化** - 避免运行时延迟
- **网络配置提前完成** - 确保功能可用性
- **错误处理更早** - 及时发现配置问题

### 2. 根控制器设计
- **GrowthSDKUIKitBridge作为根控制器** - 避免视图层级冲突
- **完整的视图生命周期管理** - 确保SDK正常工作
- **更好的内存管理** - 避免循环引用问题
- **自动忽略安全间距** - GrowthSDKUIKitBridge内部自动应用`.ignoresSafeArea()`，填满整个屏幕

### 3. 分离关注点
- **AppDelegate负责SDK初始化** - 应用级别的配置
- **SceneDelegate负责视图设置** - 场景级别的管理
- **无需额外的ViewController** - 简化项目结构

## 🔧 配置说明

```swift
struct GrowthSDKConfig: NetworkConfigurable {
    let appid: String
    let bundleName: String
    let baseUrl: String
    let publicKey: String
    let appKey: String
    let appIv: String
}
```

## 🎉 优势总结

1. **合理的初始化时机** - SDK在应用启动时初始化，越早越好
2. **避免视图层级问题** - GrowthSDKUIKitBridge作为根控制器
3. **保持SwiftUI优雅** - 不修改现有的SwiftUI集成
4. **清晰的架构分离** - 职责明确，易于维护
5. **更好的错误处理** - 早期发现和解决问题
6. **简化的项目结构** - 无需额外的ViewController
7. **完美的UI布局** - 忽略安全间距，填满整个屏幕

这个设计完全符合你的要求：**SDK初始化在App启动阶段，GrowthSDKUIKitBridge作为根控制器，避免视图层级问题，UI布局完美**。 