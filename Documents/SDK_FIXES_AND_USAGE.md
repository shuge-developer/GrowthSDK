# GrowthSDK SDK 修复和使用指南

## 🔧 修复内容

### 1. 截图传递机制修复

**问题：** 外部传递的截图没有在`SingleLayerViewModel`中使用

**修复：**
- 在`SingleLayerViewModel`中添加了`externalScreenshotProvider`属性
- 添加了`setScreenshotProvider(_:)`方法
- 修改截图获取逻辑，使用外部提供的截图方法而不是直接调用Unity相关代码

```swift
// 在SingleLayerViewModel中
private var externalScreenshotProvider: (() -> UIImage?)?

internal func setScreenshotProvider(_ provider: @escaping () -> UIImage?) {
    externalScreenshotProvider = provider
    print("[H5] [SingleLayerVM] ✅ 外部截图提供者已设置")
}
```

### 2. 视图层级切换机制修复

**问题：** `GrowthSDKLayerManager`缺少实际的视图层级切换

**修复：**
- 添加了`performUnityLayerChange()`和`notifyExternalLayerChange()`方法
- 使用`NotificationCenter`通知外部进行实际的视图层级调整
- 添加了层级切换观察者，监听来自`SingleLayerViewModel`的切换请求

```swift
// 在GrowthSDKLayerManager中
private func performUnityLayerChange() {
    print("[GrowthSDK] 🔄 执行Unity层级变化")
    DispatchQueue.main.async {
        self.notifyExternalLayerChange()
    }
}

private func notifyExternalLayerChange() {
    let layerInfo: [String: Any] = [
        "topLayerType": topLayerType.rawValue,
        "unityZIndex": unityZIndex,
        "sWebZIndex": sWebZIndex
    ]
    
    NotificationCenter.default.post(
        name: .gameWrapperUnityLayerChange,
        object: nil,
        userInfo: layerInfo
    )
}
```

### 3. 截图时机和实时性问题修复

**问题：** 截图提供者是在初始化时设置的固定闭包，无法满足实时截图需求

**修复：**
- 重新设计截图机制，在需要截图时调用外部提供的方法
- 在`switchLayers()`方法中实时获取截图
- 添加应用状态检查，防止在后台状态下截图

```swift
// 在switchLayers()方法中
let screenshot = await MainActor.run {
    if let provider = externalScreenshotProvider {
        print("[H5] [SingleLayerVM] 📸 使用外部截图提供者获取截图")
        return provider()
    } else {
        print("[H5] [SingleLayerVM] ⚠️ 外部截图提供者未设置，无法获取截图")
        return nil
    }
}
```

## 🚀 使用方法

### 1. 基本集成

```swift
import SwiftUI
import GrowthSDK

struct ContentView: View {
    var body: some View {
        GrowthSDKSwiftUIView(
            gameView: {
                // 你的游戏视图
                UnityViewWrapper()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            },
            screenshotProvider: {
                // 提供实时游戏截图的方法
                return UnityViewWrapper.shared.takeScreenshot()
            }
        )
    }
}
```

### 2. 监听层级变化

```swift
class GameViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 监听层级变化通知
        NotificationCenter.default.addObserver(
            forName: .gameWrapperUnityLayerChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let userInfo = notification.userInfo,
                  let topLayerType = userInfo["topLayerType"] as? String else { return }
            
            // 根据层级变化调整游戏视图
            if topLayerType == "unity" {
                self.bringGameViewToFront()
            } else {
                self.sendGameViewToBack()
            }
        }
    }
    
    private func bringGameViewToFront() {
        // 将游戏视图移到最前面
        view.bringSubviewToFront(gameView)
    }
    
    private func sendGameViewToBack() {
        // 将游戏视图移到最后面
        view.sendSubviewToBack(gameView)
    }
}
```

### 3. 实现实时截图

```swift
class UnityViewWrapper {
    static let shared = UnityViewWrapper()
    
    func takeScreenshot() -> UIImage? {
        // 实现实时截图逻辑
        guard let unityView = getUnityView() else { return nil }
        
        // 检查视图状态
        guard !unityView.isHidden,
              unityView.superview != nil,
              !unityView.bounds.size.isZero else {
            return nil
        }
        
        // 执行截图
        return unityView.screenshot()
    }
    
    private func getUnityView() -> UIView? {
        // 获取Unity视图的具体实现
        return nil // 替换为实际实现
    }
}
```

## 📋 注意事项

### 1. 截图提供者要求
- 必须提供实时截图能力
- 截图方法应该检查视图状态（可见性、尺寸等）
- 建议在应用活跃状态下进行截图

### 2. 层级切换要求
- 外部需要监听`gameWrapperUnityLayerChange`通知
- 根据通知中的层级信息调整实际视图层级
- 使用`bringSubviewToFront`和`sendSubviewToBack`方法

### 3. 性能考虑
- 截图操作应该在主线程执行
- 避免频繁截图，只在必要时调用
- 及时释放截图资源

## 🔍 调试建议

### 1. 启用详细日志
```swift
// 在SDK初始化时启用调试模式
GameWebWrapper.shared.enableDebugMode()
```

### 2. 检查截图提供者
```swift
// 验证截图提供者是否正常工作
if let screenshot = screenshotProvider() {
    print("截图成功，尺寸: \(screenshot.size)")
} else {
    print("截图失败")
}
```

### 3. 监控层级变化
```swift
// 监听层级变化
NotificationCenter.default.addObserver(
    forName: .gameWrapperUnityLayerChange,
    object: nil,
    queue: .main
) { notification in
    print("层级变化: \(notification.userInfo ?? [:])")
}
```

## 🐛 常见问题

### 1. 截图失败
- 检查游戏视图是否可见
- 确认视图尺寸是否有效
- 验证应用是否处于活跃状态

### 2. 层级切换不生效
- 确认是否正确监听了层级变化通知
- 检查视图层级调整方法是否正确实现
- 验证zIndex设置是否正确

### 3. 性能问题
- 避免在截图方法中执行耗时操作
- 考虑使用缓存机制减少重复截图
- 在适当时机释放截图资源 