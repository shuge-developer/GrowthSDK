//
//  GameWrapperViews.swift
//  GameWrapper
//
//  Created by arvin on 2025/1/27.
//

import SwiftUI

// MARK: - Unity加载状态协议
/// Unity加载状态协议
/// 要求游戏视图实现此协议来正确管理Unity加载状态
public protocol UnityLoadable {
    /// 设置Unity加载状态变化回调，返回自身以支持链式调用
    @discardableResult
    func setUnityStateCallback(_ callback: @escaping (Bool) -> Void) -> Self
}

// MARK: - SwiftUI 适配器视图
public struct GameWrapperSwiftUIView<GameView: View & UnityLoadable>: View {
    
    @StateObject private var startManager = H5TaskStartManager.shared
    @StateObject private var layerManager = GameWrapperLayerManager.shared
    @StateObject private var singleLayerViewModel = SingleLayerViewModel.shared
    @StateObject private var popupPositionManager = PopupPositionManager.shared
    
    @State private var showPopupView: Bool = false
    @State private var showGameView: Bool = true
    @State private var showWebView: Bool = false
    @State private var isUnityLoaded: Bool = false
    
    /// 游戏视图（由外部提供，必须实现UnityLoadable协议）
    private let gameView: GameView
    
    /// 截图提供者（由外部提供）
    private let screenshotProvider: (() -> UIImage?)?
    
    
    public init(
        @ViewBuilder gameView: () -> GameView,
        screenshotProvider: (() -> UIImage?)? = nil
    ) {
        self.gameView = gameView()
        self.screenshotProvider = screenshotProvider
    }
    
    public var body: some View {
        ZStack {
            // 层级0：多层WebView容器（底层，用户不可见）
            // 包含：展示、滑动、功能点击、滑动+功能点击
            if startManager.shouldShowMultiLayerWebView {
                // 使用现有的 MultiLayerWebContainer
                MultiLayerWebContainer()
                    .zIndex(layerManager.mWebZIndex)
                    .onAppear {
                        print("[GameWrapper] 📱 多层WebView容器显示")
                    }
            }
            
            // 层级1：单层广告点击容器（条件可见）
            // 包含：广告点击、滑动+广告点击
            if showWebView {
                if startManager.shouldShowAdClickWebView {
                    // 使用现有的 SingleLayerWebContainer
                    SingleLayerWebContainer()
                        .zIndex(layerManager.sWebZIndex)
                        .onAppear {
                            print("[GameWrapper] 📱 单层广告点击容器显示")
                        }
                }
            }
            
            // 层级2：游戏视图（主要交互层）
            if showGameView {
                gameView
                    .setUnityStateCallback { loaded in
                        self.handleUnityStateChange(loaded)
                    }
                    .zIndex(layerManager.unityZIndex)
                    .onAppear {
                        print("[GameWrapper] 📱 游戏视图显示")
                    }
            }
            
            // 层级3：弹窗视图
            if showPopupView {
                CustomPopupView {
                    // 点击弹窗按钮，触发关闭，恢复游戏层级展示
                    bringGameToTop()
                    showPopupView = false
                }
                .zIndex(layerManager.popupZIndex)
                .onAppear {
                    print("[GameWrapper] 📱 弹窗视图显示")
                }
            }
        }
        .onChange(of: layerManager.topLayerType) { newValue in
            print("[GameWrapper] 🔄 视图层级变更: \(newValue)")
            handleLayerChange(newValue)
        }
        .onAppear {
            setupScreenshotProvider()
        }
    }
    
    // MARK: - 私有方法
    
    /// 处理Unity状态变化
    private func handleUnityStateChange(_ loaded: Bool) {
        guard isUnityLoaded != loaded else { return }
        
        isUnityLoaded = loaded
        print("[GameWrapper] 🎮 Unity加载状态变更: \(loaded)")
        
        // 通知H5TaskStartManager Unity加载状态
        startManager.setUnityLoaded(loaded)
        
        // 根据状态执行相应操作
        if loaded {
            print("[GameWrapper] ✅ Unity已加载完成，可以显示WebView")
        } else {
            print("[GameWrapper] ⏳ Unity未加载或已卸载")
        }
    }
    
    private func setupScreenshotProvider() {
        // 设置截图提供者到SingleLayerViewModel
        if let provider = screenshotProvider {
            singleLayerViewModel.setScreenshotProvider(provider)
            print("[GameWrapper] 📸 截图提供者已设置到SingleLayerViewModel")
        } else {
            print("[GameWrapper] ⚠️ 未提供截图提供者，层级切换功能可能受限")
        }
    }
    
    private func handleLayerChange(_ layerType: LayerType) {
        switch layerType {
        case .unity:
            bringGameToTop()
        case .webView:
            bringWebViewToTop()
        }
    }
    
    /// 切换到游戏层（Unity）
    private func bringGameToTop() {
        print("[GameWrapper] 🔄 切换到游戏层")
        withAnimation(.easeInOut(duration: 0.2)) {
            showGameView = true
            showWebView = false
        }
    }
    
    /// 切换到WebView层
    private func bringWebViewToTop() {
        print("[GameWrapper] 🔄 切换到WebView层")
        withAnimation(.easeInOut(duration: 0.2)) {
            showGameView = false
            showWebView = true
        }
        updatePopupPositionShow()
    }
    
    private func updatePopupPositionShow() {
        let bestMatchedAd = singleLayerViewModel.bestMatchedAd
        if let adArea = bestMatchedAd?.area {
            print("[GameWrapper] 📍 检测到广告区域，更新弹窗位置")
            print("[GameWrapper] 📊 广告区域详情: left=\(adArea.left), top=\(adArea.top), width=\(adArea.width), height=\(adArea.height)")
            print("[GameWrapper] 📊 广告中心点: \(adArea.center.x), \(adArea.center.y)")
            
            popupPositionManager.updatePopupPosition(for: adArea)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showPopupView = true
            }
        }
    }
}
