//
//  GameWrapperViews.swift
//  GameWrapper
//
//  Created by arvin on 2025/1/27.
//

import SwiftUI
import Combine
import UIKit





// MARK: - Unity视图包装器
/// Unity视图包装器，将UIView包装成SwiftUI View
public struct UnityViewWrapper: UIViewRepresentable {
    let unityView: UIView
    
    public func makeUIView(context: Context) -> UIView {
        return unityView
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {
        // 视图更新时的处理
    }
}

// MARK: - SwiftUI 适配器视图
/// GameWrapper SDK 的主要入口视图
/// 完全封装多层级WebView和游戏视图的交互逻辑
/// 外部只需提供Unity控制器和截图提供者，其他全部由SDK内部处理
public struct GameWrapperSwiftUIView: View {
    
    // MARK: - 内部管理器（外部不可见）
    @StateObject private var startManager = H5TaskStartManager.shared
    @StateObject private var layerManager = GameWrapperLayerManager.shared
    @StateObject private var singleLayerViewModel = SingleLayerViewModel.shared
    @StateObject private var popupPositionManager = PopupPositionManager.shared
    
    // MARK: - 内部状态（外部不可见）
    @State private var showPopupView: Bool = false
    
    // MARK: - 外部输入
    /// Unity控制器（由外部提供）
    private let unityController: UIViewController
    
    // 便捷访问Unity视图
    private var unityView: UIView {
        return unityController.view
    }
    
    // MARK: - 初始化方法
    /// 创建GameWrapper视图
    /// - Parameters:
    ///   - unityController: Unity控制器
    public init(unityController: UIViewController) {
        self.unityController = unityController
    }
    
    // MARK: - 视图构建
    public var body: some View {
        ZStack {
            // 层级0：多层WebView容器（底层，用户不可见）
            // 包含：展示、滑动、功能点击、滑动+功能点击
            if startManager.shouldShowMultiLayerWebView {
                MultiLayerWebContainer()
                    .zIndex(layerManager.mWebZIndex)
                    .onAppear {
                        print("[GameWrapper] 📱 多层WebView容器显示")
                    }
            }
            
            // 层级1：单层广告点击容器（条件可见）
            // 包含：广告点击、滑动+广告点击
            if startManager.shouldShowAdClickWebView {
                SingleLayerWebContainer()
                    .zIndex(layerManager.sWebZIndex)
                    .onAppear {
                        print("[GameWrapper] 📱 单层广告点击容器显示")
                    }
            }
            
            // 层级2：游戏视图（主要交互层）
            UnityViewWrapper(unityView: unityView)
                .zIndex(layerManager.unityZIndex)
                .onAppear {
                    print("[GameWrapper] 📱 Unity视图显示")
                }
            
            // 层级3：弹窗视图（最顶层）
            if showPopupView {
                CustomPopupView {
                    // 点击弹窗按钮，触发关闭，恢复游戏层级展示
                    showPopupView = false
                    self.bringGameToTop()
                }
                .zIndex(layerManager.popupZIndex)
                .onAppear {
                    print("[GameWrapper] 📱 弹窗视图显示")
                }
            }
        }
        .onChange(of: layerManager.topLayerType) { newValue in
            print("[GameWrapper] 🔄 视图层级变更: \(newValue)")
            self.handleLayerChange(newValue)
        }
        .onAppear {
            self.setupSDK()
        }
    }
    
    // MARK: - 私有方法（外部不可见）
    
    
    
    /// 设置SDK
    private func setupSDK() {
        // 将Unity控制器传递给SingleLayerViewModel，用于内部截图
        SingleLayerViewModel.shared.setUnityController(unityController)
        print("[GameWrapper] 📸 Unity控制器已传递到SingleLayerViewModel，支持内部截图")
    }
    
    // MARK: - 私有方法（外部不可见）
    
    
    
    /// 处理层级变化
    private func handleLayerChange(_ layerType: LayerType) {
        switch layerType {
        case .unity:
            print("[GameWrapper] 🔄 层级已切换到Unity游戏层")
        case .webView:
            print("[GameWrapper] 🔄 层级已切换到WebView层")
            bringWebViewToTop()
            updatePopupPositionShow()
        }
    }
    
    private func updatePopupPositionShow() {
        let adViewModel = SingleLayerViewModel.shared
        let bestMatchedAd = adViewModel.bestMatchedAd
        if let adArea = bestMatchedAd?.area {
            print("[ContentView] 📍 检测到广告区域，更新弹窗位置")
            print("[ContentView] 📊 广告区域详情: left=\(adArea.left), top=\(adArea.top), width=\(adArea.width), height=\(adArea.height)")
            print("[ContentView] 📊 广告中心点: \(adArea.center.x), \(adArea.center.y)")
            
            popupPositionManager.updatePopupPosition(for: adArea)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showPopupView = true
            }
        }
    }
    
    
    
    
    /// 切换到游戏层（Unity）
    private func bringGameToTop() {
        print("[GameWrapper] 🔄 切换到游戏层")
        layerManager.bringUnityToTop()
        // 调整Unity视图的原生层级
        print("[GameWrapper] bringGameToTop: unityView: \(unityView), unityController: \(unityController)")
        layerManager.adjustUnityLayer(unityView: unityView, hostController: unityController)
    }
    
    /// 切换到WebView层
    private func bringWebViewToTop() {
        print("[GameWrapper] 🔄 切换到WebView层")
        //        layerManager.bringWebViewToTop()
        // 调整Unity视图的原生层级
        print("[GameWrapper] bringWebViewToTop: unityView: \(unityView), unityController: \(unityController)")
        layerManager.adjustUnityLayer(unityView: unityView, hostController: unityController)
    }
    
}
