//
//  GrowthKitViews.swift
//  GrowthKit
//
//  Created by arvin on 2025/1/27.
//

import SwiftUI

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

// MARK: - GrowthKit SwiftUI 主视图
public struct GrowthKitSwiftUIView: View {
    
    // MARK: - 属性
    /// Unity控制器（由外部提供）
    private let unityController: UIViewController
    
    /// 便捷访问Unity视图
    private var unityView: UIView {
        return unityController.view
    }
    
    // MARK: - 状态管理
    @StateObject private var startManager = H5TaskStartManager.shared
    @StateObject private var layerManager = GrowthKitLayerManager.shared
    @StateObject private var singleLayerViewModel = SingleLayerViewModel.shared
    @StateObject private var popupPositionManager = PopupPositionManager.shared
    @State private var showPopupView: Bool = false
    
    // MARK: - 初始化
    /// 创建GrowthKit视图
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
private extension GrowthKitSwiftUIView {
    
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
private extension GrowthKitSwiftUIView {
    
    /// 设置SDK
    func setupSDK() {
        singleLayerViewModel.setUnityController(unityController)
        logInfo("Unity控制器已传递到SingleLayerViewModel，支持内部截图")
    }
}

// MARK: - 层级管理
private extension GrowthKitSwiftUIView {
    
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
private extension GrowthKitSwiftUIView {
    
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
private extension GrowthKitSwiftUIView {
    
    /// 记录信息日志
    func logInfo(_ message: String) {
        print("[GrowthKit] 📱 \(message)")
    }
}

// MARK: - UIKit 桥接器
#if canImport(UIKit)
import UIKit

/// UIKit桥接器，用于在UIKit项目中集成GrowthKit
public class GrowthKitUIKitBridge: UIViewController {
    
    private var hostingController: UIHostingController<GrowthKitSwiftUIView>?
    
    /// 初始化UIKit桥接器
    /// - Parameter unityController: Unity视图控制器
    public init(unityController: UIViewController) {
        super.init(nibName: nil, bundle: nil)
        setupSwiftUIView(unityController: unityController)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSwiftUIView(unityController: UIViewController) {
        let swiftUIView = GrowthKitSwiftUIView(unityController: unityController)
        
        hostingController = UIHostingController(swiftUIView, ignoreSafeArea: true)
        
        if let hostingController = hostingController {
            addChild(hostingController)
            view.addSubview(hostingController.view)
            hostingController.didMove(toParent: self)
            
            // 设置约束 - 忽略安全间距，填满整个屏幕
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
                hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
    }
}
#endif
