# SmallGame 项目集成 GameWrapper SDK 示例

## 概述

本文档展示如何在现有的 SmallGame 项目中集成 GameWrapper SDK，实现最小侵入性的改造。

## 集成步骤

### 1. 修改 ContentView.swift

将现有的 ContentView 改造为使用 GameWrapper SDK：

```swift
//
//  ContentView.swift
//  SmallGame
//
//  Created by arvin on 2025/5/23.
//

import SwiftUI
import GameWrapper

struct ContentView: View {
    
    @StateObject private var startManager = H5TaskStartManager.shared
    @StateObject private var lifecycleManager = UnityLifecycleManager.shared
    @StateObject private var layerManager = LayerZIndexManager.shared
    
    private let popupPositionManager = PopupPositionManager.shared
    @State private var showDebuggerView: Bool = false
    @State private var showClearAlert: Bool = false
    @State private var isLongPressing: Bool = false
    @State private var opacity: Double = 1.0
    
    var body: some View {
        // 使用 GameWrapper SDK 的 SwiftUI 视图
        GameWrapperSwiftUIView(
            gameView: {
                // 原有的 Unity 游戏视图
                UnityViewWrapper()
                    .onUnityLoaded { state in
                        print("[ContentView] 🎉 Unity加载完成回调：\(state)")
                        startManager.setUnityLoaded(true)
                    }
                    .onUnityError { error in
                        print("[ContentView] ❌ Unity错误: \(error)")
                    }
                    .opacity(opacity)
            },
            screenshotProvider: {
                // 提供 Unity 截图
                UnityServiceProvider.asyncUnityScreenshot()
            }
        )
        .environmentObject(lifecycleManager)
        .alert(isPresented: $showClearAlert) {
            Alert(
                title: Text("清理缓存"),
                message: Text("确定要清理所有缓存数据吗？\n清理后应用将自动退出"),
                primaryButton: .destructive(Text("确定")) {
                    clearAllData()
                },
                secondaryButton: .cancel(Text("取消"))
            )
        }
        .onAppear {
            print("[ContentView] 🚀 初始化WebView系统")
        }
        
        // 保留原有的调试功能
        VStack {
            Spacer()
            HStack {
                Spacer()
                LongPressView(isPressed: $isLongPressing) {
                    handleLongPress()
                }
            }
        }
        .zIndex(500)
        
#if DEBUG
        // 快速控制组件
        VStack {
            HStack {
                VStack(spacing: 8) {
                    QuickLayerSwitchButton()
                    WebViewStatusIndicator {
                        showDebuggerView = true
                    } onCleaner: {
                        showClearAlert = true
                    }
                }
                .padding(.horizontal)
                Spacer()
            }
            .padding(.top, 44)
            Spacer()
        }
        .zIndex(102)
        
        if showDebuggerView {
            DebuggerPopupView(
                unityViewOpacity: opacity,
                onMultiLayerOpacityChanged: { opacity in
                    startManager.multiLayerOpacity = opacity
                },
                onSingleLayerOpacityChanged: { opacity in
                    startManager.singleLayerOpacity = opacity
                },
                onUnityViewOpacityChanged: { opacity in
                    self.opacity = opacity
                },
                onScreenshotOpacityChanged: { opacity in
                    startManager.screenshotOpacity = opacity
                },
                onClose: {
                    showDebuggerView = false
                }
            )
            .zIndex(300)
        }
#endif
    }
    
    // MARK: - Private Methods
    private func handleLongPress() {
        // 原有的长按处理逻辑
    }
    
    private func clearAllData() {
        print("[ContentView] 🗑️ 开始清理所有缓存数据")
        KeychainUtils.clear()
        UserDefaults.clearAllData()
        TaskRepository.shared.clearAllData()
        print("[ContentView] ✅ 所有缓存数据已清理完成")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            exit(0)
        }
    }
}

// MARK: - 长按视图组件
struct LongPressView: View {
    @Binding var isPressed: Bool
    let onLongPress: () -> Void
    
    var body: some View {
        RoundedRectangle(cornerRadius: 0)
            .fill(Color.gray.opacity(0.01))
            .frame(width: 80, height: 80)
            .onLongPressGesture(
                minimumDuration: 0.5,
                maximumDistance: 50,
                pressing: { pressing in
                    withAnimation {
                        isPressed = pressing
                    }
                },
                perform: {
                    onLongPress()
                }
            )
    }
}
```

### 2. 修改 SmallGameApp.swift

在 App 启动时初始化 GameWrapper SDK：

```swift
//
//  SmallGameApp.swift
//  SmallGame
//
//  Created by arvin on 2025/5/23.
//

import SwiftUI
import GameWrapper

@main
struct SmallGameApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    initializeGameWrapperSDK()
                }
        }
    }
    
    private func initializeGameWrapperSDK() {
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
                print("[SmallGameApp] ✅ GameWrapper SDK 初始化成功")
            case .failure(let error):
                print("[SmallGameApp] ❌ GameWrapper SDK 初始化失败: \(error)")
            }
        }
    }
}
```

### 3. 修改 AppDelegate.swift

在 App 生命周期中管理 SDK：

```swift
//
//  AppDelegate.swift
//  SmallGame
//
//  Created by arvin on 2025/5/23.
//

import UIKit
import GameWrapper

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // 原有的初始化逻辑
        setupUnityFramework()
        
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // 清理 SDK 资源
        GameWebWrapper.shared.cleanup()
    }
    
    private func setupUnityFramework() {
        // 原有的 Unity 框架设置逻辑
    }
}
```

## 核心变化说明

### 1. 视图结构变化

**原有结构**：
```swift
ZStack {
    // 多层WebView容器
    MultiLayerWebContainer()
    
    // 单层WebView容器  
    SingleLayerWebContainer()
    
    // Unity游戏视图
    UnityViewWrapper()
    
    // 弹窗视图
    CustomPopupView()
}
```

**新结构**：
```swift
GameWrapperSwiftUIView(
    gameView: {
        UnityViewWrapper()
    },
    screenshotProvider: {
        UnityServiceProvider.asyncUnityScreenshot()
    }
)
```

### 2. 层级管理变化

**原有方式**：
- 使用 `LayerZIndexManager` 直接管理层级
- 在 `ContentView` 中手动控制层级切换

**新方式**：
- 使用 `GameWrapperLayerManager` 统一管理层级
- SDK 内部自动处理层级切换逻辑

### 3. 弹窗管理变化

**原有方式**：
- 在 `ContentView` 中手动控制弹窗显示
- 通过 `PopupPositionManager` 管理弹窗位置

**新方式**：
- SDK 内部自动管理弹窗显示
- 保持原有的 `PopupPositionManager` 逻辑

## 优势对比

### 原有方案的问题
1. **代码耦合度高**: 层级管理逻辑分散在多个文件中
2. **维护困难**: 需要手动管理复杂的层级切换逻辑
3. **扩展性差**: 难以在其他项目中复用

### 新方案的优势
1. **封装性好**: 将复杂的层级管理逻辑封装在 SDK 中
2. **复用性强**: 可以在其他项目中轻松集成
3. **维护简单**: 统一的接口和清晰的职责分离
4. **最小侵入**: 对现有代码的改动最小

## 迁移注意事项

### 1. 保持兼容性
- 保留原有的调试功能
- 保持原有的生命周期管理
- 维持原有的错误处理机制

### 2. 渐进式迁移
- 可以先在测试环境中验证
- 逐步替换核心组件
- 保留回滚方案

### 3. 性能考虑
- SDK 初始化在 App 启动时进行
- 避免在关键路径上增加额外开销
- 合理管理内存和资源

## 测试验证

### 1. 功能测试
- 验证层级切换是否正常
- 确认广告检测和点击功能
- 测试弹窗显示和交互

### 2. 性能测试
- 检查内存使用情况
- 验证启动时间影响
- 测试长时间运行稳定性

### 3. 兼容性测试
- 在不同设备上测试
- 验证不同 iOS 版本兼容性
- 测试网络异常情况

## 总结

通过这种集成方式，我们可以：

1. **最小化改动**: 只需要修改 `ContentView.swift` 和添加初始化代码
2. **保持功能**: 所有原有功能都得到保留
3. **提升可维护性**: 通过 SDK 封装，代码结构更清晰
4. **增强复用性**: 其他项目可以轻松集成相同的功能

这种方案既满足了 SDK 化的需求，又最大程度地保护了现有投资。 