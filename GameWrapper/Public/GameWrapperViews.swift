//
//  GameWrapperViews.swift
//  GameWrapper
//
//  Created by arvin on 2025/1/27.
//

import SwiftUI
import UIKit

// MARK: - Unity视图包装器
private struct UnityViewWrapper: UIViewRepresentable {
    let unityView: UIView
    
    public func makeUIView(context: Context) -> UIView {
        return unityView
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {
        // 视图更新时的处理
    }
}

// MARK: - GameWrapper SwiftUI 主视图
public struct GameWrapperSwiftUIView: View {
    
    // MARK: - 属性
    /// Unity控制器（由外部提供）
    private let unityController: UIViewController
    
    /// 便捷访问Unity视图
    private var unityView: UIView {
        return unityController.view
    }
    
    // MARK: - 状态管理
    @StateObject private var startManager = H5TaskStartManager.shared
    @StateObject private var layerManager = GameWrapperLayerManager.shared
    @StateObject private var singleLayerViewModel = SingleLayerViewModel.shared
    @StateObject private var popupPositionManager = PopupPositionManager.shared
    @State private var showPopupView: Bool = false
    
    // MARK: - 初始化
    /// 创建GameWrapper视图
    /// - Parameter unityController: Unity控制器
    public init(unityController: UIViewController) {
        self.unityController = unityController
    }
    
    // MARK: - 视图构建
    public var body: some View {
        ZStack {
            buildMultiLayerWebView()
            buildSingleLayerWebView()
            buildUnityView()
            buildPopupView()
        }
        .onChange(of: layerManager.topLayerType) { newValue in
            handleLayerChange(newValue)
        }
        .onAppear {
            setupSDK()
        }
    }
}

// MARK: - 视图构建方法
private extension GameWrapperSwiftUIView {
    
    /// 构建多层WebView容器
    @ViewBuilder
    func buildMultiLayerWebView() -> some View {
        if startManager.shouldShowMultiLayerWebView {
            MultiLayerWebContainer()
                .zIndex(layerManager.mWebZIndex)
                .onAppear {
                    logInfo("多层WebView容器显示")
                }
        }
    }
    
    /// 构建单层广告点击容器
    @ViewBuilder
    func buildSingleLayerWebView() -> some View {
        if startManager.shouldShowAdClickWebView {
            SingleLayerWebContainer()
                .zIndex(layerManager.sWebZIndex)
                .onAppear {
                    logInfo("单层广告点击容器显示")
                }
        }
    }
    
    /// 构建Unity游戏视图
    @ViewBuilder
    func buildUnityView() -> some View {
        UnityViewWrapper(unityView: unityView)
            .zIndex(layerManager.unityZIndex)
            .onAppear {
                logInfo("Unity视图显示")
            }
    }
    
    /// 构建弹窗视图
    @ViewBuilder
    func buildPopupView() -> some View {
        if showPopupView {
            CustomPopupView {
                showPopupView = false
                bringGameViewToTop()
            }
            .zIndex(layerManager.popupZIndex)
            .onAppear {
                logInfo("弹窗视图显示")
            }
        }
    }
}

// MARK: - SDK 设置
private extension GameWrapperSwiftUIView {
    
    /// 设置SDK
    func setupSDK() {
        singleLayerViewModel.setUnityController(unityController)
        logInfo("Unity控制器已传递到SingleLayerViewModel，支持内部截图")
    }
}

// MARK: - 层级管理
private extension GameWrapperSwiftUIView {
    
    /// 处理层级变化
    func handleLayerChange(_ layerType: LayerType) {
        logInfo("视图层级变更: \(layerType)")
        switch layerType {
        case .unity:
            logInfo("层级已切换到Unity游戏层")
        case .webView:
            logInfo("层级已切换到WebView层")
            bringWebViewToTop()
            setPopupPosition()
        }
    }
    
    /// 切换到游戏层（Unity）
    func bringGameViewToTop() {
        logInfo("切换到游戏层")
        layerManager.bringUnityToTop()
        adjustUnityLayer()
    }
    
    /// 切换到WebView层
    func bringWebViewToTop() {
        logInfo("切换到WebView层")
        adjustUnityLayer()
    }
    
    /// 调整Unity视图的原生层级
    func adjustUnityLayer() {
        layerManager.adjustUnityLayer(
            hostController: unityController,
            unityView: unityView
        )
    }
}

// MARK: - 弹窗管理
private extension GameWrapperSwiftUIView {
    
    /// 更新弹窗位置并显示
    func setPopupPosition() {
        let bestMatchedAd = singleLayerViewModel.bestMatchedAd
        guard let adArea = bestMatchedAd?.area else { return }
        
        logInfo("检测到广告区域，更新弹窗位置")
        
        popupPositionManager.updatePopupPosition(for: adArea)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showPopupView = true
        }
    }
}

// MARK: - 日志工具
private extension GameWrapperSwiftUIView {
    
    /// 记录信息日志
    func logInfo(_ message: String) {
        print("[GameWrapper] 📱 \(message)")
    }
}
