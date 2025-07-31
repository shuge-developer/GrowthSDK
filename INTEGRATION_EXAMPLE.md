# GameWrapper SDK 集成示例

## 在 SmallGame 项目中的集成

基于现有的 SmallGame 项目结构，以下是具体的集成示例：

### 1. 修改 ContentView.swift

```swift
import SwiftUI
import GameWrapper

struct ContentView: View {
    @StateObject private var gameWrapperManager = GameWrapperManager.shared
    @StateObject private var layerManager = LayerZIndexManager.shared
    
    var body: some View {
        ZStack {
            // 游戏层
            UnityGameView()
                .zIndex(layerManager.unityZIndex)
            
            // GameWrapper SDK 层
            GameWrapperSwiftUIView()
                .zIndex(layerManager.sWebZIndex)
            
            // 原生弹窗层
            if showPopup {
                CustomPopupView(position: .center) {
                    showPopup = false
                }
                .zIndex(layerManager.popupZIndex)
            }
        }
        .onAppear {
            setupGameWrapper()
        }
        .onDisappear {
            GameWrapperManager.shared.stop()
        }
    }
    
    private func setupGameWrapper() {
        // 设置截图提供者
        GameWrapperManager.shared.setScreenshotProvider { [weak self] in
            return self?.captureUnityScreenshot()
        }
        
        // 启动 SDK
        GameWrapperManager.shared.start { result in
            switch result {
            case .success:
                print("GameWrapper 启动成功")
            case .failure(let error):
                print("GameWrapper 启动失败: \(error)")
            }
        }
    }
    
    private func captureUnityScreenshot() -> UIImage? {
        // 使用现有的 Unity 截图方法
        return UnityServiceProvider.asyncUnityScreenshot()
    }
}
```

### 2. 修改 LayerZIndexManager.swift

```swift
import SwiftUI
import Combine
import GameWrapper

final class LayerZIndexManager: ObservableObject {
    
    static let shared = LayerZIndexManager()
    
    @Published var topLayerType: LayerType = .unity
    @Published var popupZIndex: Double = 200
    @Published var unityZIndex: Double = 99
    @Published var sWebZIndex: Double = 10
    @Published var mWebZIndex: Double = 0
    
    private enum ZIndexConfig {
        static let topLayer: Double = 99
        static let btmLayer: Double = 10
    }
    
    private init() {
        unityZIndex = ZIndexConfig.topLayer
        sWebZIndex = ZIndexConfig.btmLayer
        updateTopLayerType()
        
        // 监听 GameWrapper 的层级变化
        setupGameWrapperObserver()
    }
    
    private func setupGameWrapperObserver() {
        GameWrapperManager.shared.$topLayerType
            .sink { [weak self] layerType in
                DispatchQueue.main.async {
                    switch layerType {
                    case .game:
                        self?.bringUnityToTop()
                    case .webView:
                        self?.bringWebViewToTop()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // ... 其他现有方法保持不变
}
```

### 3. 创建 GameWrapper 适配器

```swift
// GameWrapperAdapter.swift
import SwiftUI
import GameWrapper

class GameWrapperAdapter: ObservableObject {
    static let shared = GameWrapperAdapter()
    
    private var gameWrapperManager = GameWrapperManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupObservers()
    }
    
    private func setupObservers() {
        // 监听广告点击事件
        NotificationCenter.default.publisher(for: .gameWrapperAdClicked)
            .sink { [weak self] _ in
                self?.handleAdClick()
            }
            .store(in: &cancellables)
    }
    
    private func handleAdClick() {
        // 处理广告点击，可以触发层级切换
        gameWrapperManager.switchLayer(to: .game)
    }
    
    func start() {
        gameWrapperManager.start { result in
            switch result {
            case .success:
                print("GameWrapper 适配器启动成功")
            case .failure(let error):
                print("GameWrapper 适配器启动失败: \(error)")
            }
        }
    }
    
    func stop() {
        gameWrapperManager.stop()
    }
}
```

### 4. 修改 AppDelegate.swift

```swift
import UIKit
import GameWrapper

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // 设置 GameWrapper 网络配置
        let config = NetworkConfig(
            appid: "your_app_id",
            bundleName: Bundle.main.bundleIdentifier ?? "",
            baseUrl: "https://your_api_base_url",
            publicKey: "your_public_key",
            appKey: "your_app_key",
            appIv: "your_app_iv"
        )
        
        GameWebWrapper.shared.setup(network: config)
        
        // 初始化 GameWrapper
        GameWebWrapper.shared.initialize { result in
            switch result {
            case .success:
                print("GameWrapper 初始化成功")
            case .failure(let error):
                print("GameWrapper 初始化失败: \(error)")
            }
        }
        
        return true
    }
}
```

### 5. 简化集成方案

如果你希望更简单的集成，可以创建一个包装器：

```swift
// SimpleGameWrapper.swift
import SwiftUI
import GameWrapper

struct SimpleGameWrapper {
    
    static func setup() {
        // 自动设置网络配置（从 Info.plist 读取）
        setupNetworkConfig()
        
        // 自动初始化
        GameWebWrapper.shared.initialize { result in
            switch result {
            case .success:
                print("SimpleGameWrapper 初始化成功")
            case .failure(let error):
                print("SimpleGameWrapper 初始化失败: \(error)")
            }
        }
    }
    
    static func start() {
        GameWrapperManager.shared.start { _ in }
    }
    
    static func stop() {
        GameWrapperManager.shared.stop()
    }
    
    private static func setupNetworkConfig() {
        guard let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path) else {
            return
        }
        
        let config = NetworkConfig(
            appid: plist["GameWrapperAppID"] as? String ?? "",
            bundleName: Bundle.main.bundleIdentifier ?? "",
            baseUrl: plist["GameWrapperBaseURL"] as? String ?? "",
            publicKey: plist["GameWrapperPublicKey"] as? String ?? "",
            appKey: plist["GameWrapperAppKey"] as? String ?? "",
            appIv: plist["GameWrapperAppIV"] as? String ?? ""
        )
        
        GameWebWrapper.shared.setup(network: config)
    }
}

// 在 ContentView 中使用
struct ContentView: View {
    var body: some View {
        ZStack {
            UnityGameView()
            GameWrapperSwiftUIView()
        }
        .onAppear {
            SimpleGameWrapper.start()
        }
        .onDisappear {
            SimpleGameWrapper.stop()
        }
    }
}
```

### 6. Info.plist 配置

```xml
<key>GameWrapperAppID</key>
<string>your_app_id</string>
<key>GameWrapperBaseURL</key>
<string>https://your_api_base_url</string>
<key>GameWrapperPublicKey</key>
<string>your_public_key</string>
<key>GameWrapperAppKey</key>
<string>your_app_key</string>
<key>GameWrapperAppIV</key>
<string>your_app_iv</string>
```

## 集成优势

1. **最小侵入性**: 只需要在现有代码中添加几行代码
2. **保持现有架构**: 不破坏现有的 LayerZIndexManager 等组件
3. **渐进式集成**: 可以逐步替换现有功能
4. **向后兼容**: 现有功能继续工作，新功能作为增强

## 迁移路径

1. **第一阶段**: 添加 GameWrapper SDK，保持现有功能
2. **第二阶段**: 逐步将 WebView 相关功能迁移到 SDK
3. **第三阶段**: 完全使用 SDK 的功能，移除冗余代码

这样的集成方案既保持了现有项目的稳定性，又为未来的功能扩展提供了良好的基础。 