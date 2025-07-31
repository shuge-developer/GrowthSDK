//
//  GameWrapperViews.swift
//  GameWrapper
//
//  Created by arvin on 2025/1/27.
//

import SwiftUI
import Combine

// MARK: - 层级类型定义
public enum LayerType: String, CaseIterable {
    case unity = "unity"
    case webView = "webView"
    
    public var displayName: String {
        switch self {
        case .unity:
            return "Unity游戏"
        case .webView:
            return "WebView"
        }
    }
}

// MARK: - 层级管理器（移植自SmallGame）
public class GameWrapperLayerManager: ObservableObject {
    
    public static let shared = GameWrapperLayerManager()
    
    // MARK: - 发布属性
    @Published public var topLayerType: LayerType = .unity
    @Published public var popupZIndex: Double = 200
    @Published public var unityZIndex: Double = 99
    @Published public var sWebZIndex: Double = 10
    @Published public var mWebZIndex: Double = 0
    
    // MARK: - 配置常量
    private enum ZIndexConfig {
        static let topLayer: Double = 99
        static let btmLayer: Double = 10
    }
    
    private init() {
        // 默认设置Unity在上层，WebView在下层
        unityZIndex = ZIndexConfig.topLayer
        sWebZIndex = ZIndexConfig.btmLayer
        updateTopLayerType()
    }
    
    // MARK: - 公开方法
    /// 切换层级：Unity置顶
    public func bringUnityToTop() {
        print("[GameWrapper] 🔄 切换Unity到顶层")
        unityZIndex = ZIndexConfig.topLayer
        sWebZIndex = ZIndexConfig.btmLayer
        updateTopLayerType()
    }
    
    /// 切换层级：WebView置顶
    public func bringWebViewToTop() {
        print("[GameWrapper] 🔄 切换WebView到顶层")
        unityZIndex = ZIndexConfig.btmLayer
        sWebZIndex = ZIndexConfig.topLayer
        updateTopLayerType()
    }
    
    /// 切换到下一个层级（轮流切换）
    public func switchToNextLayer() {
        switch topLayerType {
        case .unity:
            bringWebViewToTop()
        case .webView:
            bringUnityToTop()
        }
    }
    
    /// 重置为默认层级（Unity在上）
    public func resetToDefault() {
        print("[GameWrapper] 🔄 重置为默认层级")
        bringUnityToTop()
    }
    
    // MARK: - 私有方法
    private func updateTopLayerType() {
        let newTopLayer: LayerType = unityZIndex > sWebZIndex ? .unity : .webView
        if newTopLayer != topLayerType {
            topLayerType = newTopLayer
            print("[GameWrapper] 🔝 顶层切换为: \(topLayerType.displayName)")
            print("[GameWrapper] 🔢 Unity zIndex: \(unityZIndex), WebView zIndex: \(sWebZIndex)")
        }
    }
}

// MARK: - SwiftUI 适配器视图
public struct GameWrapperSwiftUIView<GameView: View>: View {
    
    @StateObject private var layerManager = GameWrapperLayerManager.shared
    @StateObject private var singleLayerViewModel = SingleLayerViewModel.shared
    @StateObject private var popupPositionManager = PopupPositionManager.shared
    
    @State private var showPopupView: Bool = false
    @State private var showDebuggerView: Bool = false
    @State private var showClearAlert: Bool = false
    @State private var isLongPressing: Bool = false
    @State private var opacity: Double = 1.0
    
    /// 游戏视图（由外部提供）
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
            if shouldShowMultiLayerWebView {
                // 使用现有的 MultiLayerWebContainer
                Color.clear
                    .zIndex(layerManager.mWebZIndex)
                    .onAppear {
                        print("[GameWrapper] 📱 多层WebView容器显示")
                    }
            }
            
            // 层级1：单层广告点击容器（中间层，条件可见）
            if shouldShowAdClickWebView {
                // 使用现有的 SingleLayerWebContainer
                Color.clear
                    .zIndex(layerManager.sWebZIndex)
                    .onAppear {
                        print("[GameWrapper] 📱 单层广告点击容器显示")
                    }
            }
            
            // 层级2：游戏视图（主要交互层，默认顶层）
            gameView
                .zIndex(layerManager.unityZIndex)
            
            // 层级3：弹窗视图
            if showPopupView {
                CustomPopupView {
                    // 点击弹窗按钮，触发关闭，恢复游戏层级展示
                    layerManager.bringUnityToTop()
                    showPopupView = false
                }
                .zIndex(layerManager.popupZIndex)
            }
        }
        .onChange(of: layerManager.topLayerType) { newValue in
            print("[GameWrapper] 🔄 视图层级变更: \(newValue)")
            if newValue == .webView { // web 在顶层时，展示弹窗
                updatePopupPositionShow()
            }
        }
        .onAppear {
            setupScreenshotProvider()
        }
    }
    
    // MARK: - 私有方法
    
    private var shouldShowMultiLayerWebView: Bool {
        // 根据任务类型判断是否显示多层WebView
        return false // 暂时不显示，根据实际需求调整
    }
    
    private var shouldShowAdClickWebView: Bool {
        // 根据任务类型判断是否显示单层WebView
        return singleLayerViewModel.currentTask != nil
    }
    
    private func setupScreenshotProvider() {
        // 设置截图提供者到SingleLayerViewModel
        if let provider = screenshotProvider {
            // 这里需要修改SingleLayerViewModel来支持外部截图提供者
            print("[GameWrapper] 📸 截图提供者已设置")
        }
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
