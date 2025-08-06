# GrowthKit SDK 集成示例

## 在 SmallGame 项目中的集成

基于现有的 SmallGame 项目结构，以下是具体的集成示例：

### 1. 修改 ContentView.swift

```swift
import SwiftUI
import GrowthKit

struct ContentView: View {
    @StateObject private var gameWrapperManager = GrowthKitManager.shared
    @StateObject private var layerManager = LayerZIndexManager.shared
    
    var body: some View {
        ZStack {
            // 游戏层
            UnityGameView()
                .zIndex(layerManager.unityZIndex)
            
            // GrowthKit SDK 层
            GrowthKitSwiftUIView()
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
            setupGrowthKit()
        }
        .onDisappear {
            GrowthKitManager.shared.stop()
        }
    }
    
    private func setupGrowthKit() {
        // 设置截图提供者
        GrowthKitManager.shared.setScreenshotProvider { [weak self] in
            return self?.captureUnityScreenshot()
        }
        
        // 启动 SDK
        GrowthKitManager.shared.start { result in
            switch result {
            case .success:
                print("GrowthKit 启动成功")
            case .failure(let error):
                print("GrowthKit 启动失败: \(error)")
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
import GrowthKit

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
        
        // 监听 GrowthKit 的层级变化
        setupGrowthKitObserver()
    }
    
    private func setupGrowthKitObserver() {
        GrowthKitManager.shared.$topLayerType
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

### 3. 创建 GrowthKit 适配器

```swift
// GrowthKitAdapter.swift
import SwiftUI
import GrowthKit

class GrowthKitAdapter: ObservableObject {
    static let shared = GrowthKitAdapter()
    
    private var gameWrapperManager = GrowthKitManager.shared
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
                print("GrowthKit 适配器启动成功")
            case .failure(let error):
                print("GrowthKit 适配器启动失败: \(error)")
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
import GrowthKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // 设置 GrowthKit 网络配置
        let config = NetworkConfig(
            appid: "your_app_id",
            bundleName: Bundle.main.bundleIdentifier ?? "",
            baseUrl: "https://your_api_base_url",
            publicKey: "your_public_key",
            appKey: "your_app_key",
            appIv: "your_app_iv"
        )
        
        GameWebWrapper.shared.setup(network: config)
        
        // 初始化 GrowthKit
        GameWebWrapper.shared.initialize { result in
            switch result {
            case .success:
                print("GrowthKit 初始化成功")
            case .failure(let error):
                print("GrowthKit 初始化失败: \(error)")
            }
        }
        
        return true
    }
}
```

### 5. 简化集成方案

如果你希望更简单的集成，可以创建一个包装器：

```swift
// SimpleGrowthKit.swift
import SwiftUI
import GrowthKit

struct SimpleGrowthKit {
    
    static func setup() {
        // 自动设置网络配置（从 Info.plist 读取）
        setupNetworkConfig()
        
        // 自动初始化
        GameWebWrapper.shared.initialize { result in
            switch result {
            case .success:
                print("SimpleGrowthKit 初始化成功")
            case .failure(let error):
                print("SimpleGrowthKit 初始化失败: \(error)")
            }
        }
    }
    
    static func start() {
        GrowthKitManager.shared.start { _ in }
    }
    
    static func stop() {
        GrowthKitManager.shared.stop()
    }
    
    private static func setupNetworkConfig() {
        guard let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path) else {
            return
        }
        
        let config = NetworkConfig(
            appid: plist["GrowthKitAppID"] as? String ?? "",
            bundleName: Bundle.main.bundleIdentifier ?? "",
            baseUrl: plist["GrowthKitBaseURL"] as? String ?? "",
            publicKey: plist["GrowthKitPublicKey"] as? String ?? "",
            appKey: plist["GrowthKitAppKey"] as? String ?? "",
            appIv: plist["GrowthKitAppIV"] as? String ?? ""
        )
        
        GameWebWrapper.shared.setup(network: config)
    }
}

// 在 ContentView 中使用
struct ContentView: View {
    var body: some View {
        ZStack {
            UnityGameView()
            GrowthKitSwiftUIView()
        }
        .onAppear {
            SimpleGrowthKit.start()
        }
        .onDisappear {
            SimpleGrowthKit.stop()
        }
    }
}
```

### 6. Info.plist 配置

```xml
<key>GrowthKitAppID</key>
<string>your_app_id</string>
<key>GrowthKitBaseURL</key>
<string>https://your_api_base_url</string>
<key>GrowthKitPublicKey</key>
<string>your_public_key</string>
<key>GrowthKitAppKey</key>
<string>your_app_key</string>
<key>GrowthKitAppIV</key>
<string>your_app_iv</string>
```

## 集成优势

1. **最小侵入性**: 只需要在现有代码中添加几行代码
2. **保持现有架构**: 不破坏现有的 LayerZIndexManager 等组件
3. **渐进式集成**: 可以逐步替换现有功能
4. **向后兼容**: 现有功能继续工作，新功能作为增强

## 迁移路径

1. **第一阶段**: 添加 GrowthKit SDK，保持现有功能
2. **第二阶段**: 逐步将 WebView 相关功能迁移到 SDK
3. **第三阶段**: 完全使用 SDK 的功能，移除冗余代码

这样的集成方案既保持了现有项目的稳定性，又为未来的功能扩展提供了良好的基础。 