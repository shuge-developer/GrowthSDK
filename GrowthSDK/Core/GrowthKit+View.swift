//
//  GrowthKit+View.swift
//  GrowthSDK
//
//  Created by arvin on 2025/7/28.
//

import Foundation
import Combine

#if canImport(UIKit)
import SwiftUI
import UIKit

// MARK: - SDK 初始化状态管理器
private class SDKInitializationManager: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    @Published var isReady: Bool = false
    
    func startMonitoring() {
        if GrowthKit.shared.isInitialized {
            isReady = true
            return
        }
        GrowthKit.shared.$isInitialized
            .receive(on: DispatchQueue.main)
            .sink { [weak self] initialized in
                if initialized {
                    self?.isReady = true
                }
            }
            .store(in: &cancellables)
    }
    
    deinit {
        cancellables.removeAll()
    }
}

// MARK: - 视图管理扩展
public extension GrowthKit {
    
    /// 创建主视图控制器
    /// - Parameter unityController: Unity 视图控制器
    /// - Returns: GrowthSDK 视图控制器
    @objc static func createController(with unityController: UIViewController) -> UIViewController {
        return GrowthSDKViewController(unityController)
    }
    
    /// 创建 SwiftUI 视图
    /// - Parameter unityController: Unity 视图控制器
    /// - Returns: SwiftUI 视图
    static func createView(with unityController: UIViewController) -> some View {
        return GrowthSDKView(unityController)
    }
}

// MARK: - Unity视图包装器
private struct UnityViewWrapper: UIViewRepresentable {
    let unityView: UIView
    
    func makeUIView(context: Context) -> UIView {
        return unityView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // 视图更新时的处理
    }
}

// MARK: - SwiftUI 主视图
private struct GrowthSDKView: View {
    
    // MARK: - 属性
    private let unityController: UIViewController
    
    private var unityView: UIView {
        return unityController.view
    }
    
    // MARK: - 状态管理
    @StateObject private var startManager = TaskLauncher.shared
    @StateObject private var layerManager = LayerOrchestrator.shared
    @StateObject private var initializationManager = SDKInitializationManager()
    @StateObject private var singleLayerViewModel = SingleLayerViewModel.shared
    @StateObject private var popupPositionManager = PopupCoordinator.shared
    @State private var showPopupView: Bool = false
    
    // MARK: - 初始化
    init(_ unityController: UIViewController) {
        self.unityController = unityController
    }
    
    // MARK: - 视图构建
    var body: some View {
        ZStack {
            if initializationManager.isReady {
                buildMultiLayerWebView()
                buildSingleLayerWebView()
                buildUnityView()
                buildPopupView()
            } else {
                Color.hex("201D1D")
            }
        }
        .onChange(of: layerManager.topLayerType) { newValue in
            handleLayerChange(newValue)
        }
        .ignoresSafeArea()
        .onAppear {
            setupSDK()
        }
    }
    
    // MARK: - 视图构建方法
    @ViewBuilder
    private func buildMultiLayerWebView() -> some View {
        if startManager.shouldShowMultiLayerWebView {
            MultiLayerWebContainer()
                .zIndex(layerManager.mWebZIndex)
                .onAppear {
                    Logger.info("多层WebView容器显示")
                }
        }
    }
    
    @ViewBuilder
    private func buildSingleLayerWebView() -> some View {
        if startManager.shouldShowAdClickWebView {
            SingleLayerWebContainer()
                .zIndex(layerManager.sWebZIndex)
                .onAppear {
                    Logger.info("单层广告点击容器显示")
                }
        }
    }
    
    @ViewBuilder
    private func buildUnityView() -> some View {
        UnityViewWrapper(unityView: unityView)
            .zIndex(layerManager.unityZIndex)
            .onAppear {
                Logger.info("Unity视图显示")
            }
    }
    
    @ViewBuilder
    private func buildPopupView() -> some View {
        if showPopupView {
            CustomPopupView {
                showPopupView = false
                bringGameViewToTop()
            }
            .zIndex(layerManager.popupZIndex)
            .onAppear {
                Logger.info("弹窗视图显示")
            }
        }
    }
    
    // MARK: - 私有方法
    private func setupSDK() {
        // 立即设置 Unity 控制器
        singleLayerViewModel.setUnityController(unityController)
        Logger.info("Unity控制器已传递到SingleLayerViewModel，支持内部截图")
        
        // 启动初始化管理器（内部异步处理）
        initializationManager.startMonitoring()
    }
    
    private func handleLayerChange(_ layerType: LayerType) {
        Logger.info("视图层级变更: \(layerType)")
        switch layerType {
        case .unity:
            Logger.info("层级已切换到Unity游戏层")
        case .webView:
            Logger.info("层级已切换到WebView层")
            bringWebViewToTop()
            setPopupPosition()
        }
    }
    
    private func bringGameViewToTop() {
        Logger.info("切换到Unity游戏层")
        layerManager.bringUnityToTop()
        adjustUnityLayer()
    }
    
    private func bringWebViewToTop() {
        Logger.info("切换到WebView层")
        adjustUnityLayer()
    }
    
    private func adjustUnityLayer() {
        layerManager.adjustUnityLayer(
            hostController: unityController,
            unityView: unityView
        )
    }
    
    private func setPopupPosition() {
        let bestMatchedAd = singleLayerViewModel.bestMatchedAd
        guard let adArea = bestMatchedAd?.area else { return }
        
        Logger.info("检测到广告区域，更新弹窗位置")
        
        popupPositionManager.updatePopupPosition(for: adArea)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showPopupView = true
        }
    }
}

// MARK: - 根视图控制器
private final class GrowthSDKViewController: UIViewController {
    
    // MARK: - 私有属性
    private var contentController: UIViewController?
    private let unityController: UIViewController
    
    // MARK: - 初始化方法
    init(_ unityController: UIViewController) {
        self.unityController = unityController
        super.init(nibName: nil, bundle: nil)
        Logger.info("GrowthSDK 视图控制器创建完成")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        setupController()
    }
    
    // MARK: - 私有方法
    private func setupController() {
        // 立即创建 SwiftUI 视图（内部会处理初始化状态）
        let contentView = GrowthSDKView(unityController)
        let hostingController = UIHostingController(
            contentView, ignoresSafeArea: true
        )
        
        // 添加到视图层级
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        // 设置约束
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        self.contentController = hostingController
        Logger.info("GrowthSDK 视图控制器加载完成")
    }
}

#endif
