//
//  LayerOrchestrator.swift
//  GrowthSDK
//
//  Created by arvin on 2025/8/4.
//

import SwiftUI

// MARK: - 层级类型定义
internal enum LayerType: String, CaseIterable {
    case webView = "webView"
    case unity = "unity"
    
    var displayName: String {
        switch self {
        case .webView: "WebView"
        case .unity: "Unity游戏"
        }
    }
}

// MARK: - 层级编排器
internal final class LayerOrchestrator: ObservableObject {
    // MARK: - 单例
    static let shared = LayerOrchestrator()
    
    // MARK: - 层级状态
    @Published var topLayerType: LayerType = .unity
    @Published var popupZIndex: Double = 200
    @Published var unityZIndex: Double = 99
    @Published var sWebZIndex: Double = 10
    @Published var mWebZIndex: Double = 0
    
    // MARK: - 层级常量
    private enum ZIndex {
        static let unityTop: Double = 99
        static let unityBottom: Double = 10
        
        static let webTop: Double = 99
        static let webBottom: Double = 10
    }
    
    // MARK: - 初始化
    private init() {
        resetToDefault()
    }
    
    // MARK: - 公开层级操作
    /// Unity置顶
    func bringUnityToTop() {
        print("[GrowthSDK] 🔄 切换Unity到顶层")
        withAnimation(.easeInOut(duration: 0.3)) {
            unityZIndex = ZIndex.unityTop
            sWebZIndex = ZIndex.webBottom
        }
        updateTopLayerType()
    }
    
    /// WebView置顶
    func bringWebViewToTop() {
        print("[GrowthSDK] 🔄 切换WebView到顶层")
        withAnimation(.easeInOut(duration: 0.3)) {
            unityZIndex = ZIndex.unityBottom
            sWebZIndex = ZIndex.webTop
        }
        updateTopLayerType()
    }
    
    /// 轮流切换层级
    func switchToNextLayer() {
        switch topLayerType {
        case .webView: bringUnityToTop()
        case .unity: bringWebViewToTop()
        }
    }
    
    /// 重置为默认层级（Unity在上）
    func resetToDefault() {
        print("[GrowthSDK] 🔄 重置为默认层级")
        bringUnityToTop()
    }
    
    // MARK: - 原生层级调整
    /// 调整Unity视图的原生层级
    /// - Parameters:
    ///   - hostController: Unity宿主控制器
    ///   - unityView: Unity视图
    func adjustUnityLayer(hostController: UIViewController?, unityView: UIView?) {
        guard let unityView = unityView, let hostController = hostController else {
            print("[GrowthSDK] ⚠️ Unity视图或宿主控制器不可用，跳过原生层级调整")
            return
        }
        let bringToFront = topLayerType == .unity
        if bringToFront {
            hostController.view.bringSubviewToFront(unityView)
            print("[GrowthSDK] 📤 Unity视图已移至前台")
        } else {
            hostController.view.sendSubviewToBack(unityView)
            print("[GrowthSDK] 📥 Unity视图已移至后台")
        }
        print("[GrowthSDK] 🔄 原生视图层级已调整: Unity \(bringToFront ? "在顶层" : "在底层")")
    }
    
    // MARK: - 私有辅助
    private func updateTopLayerType() {
        let newTopLayer: LayerType = unityZIndex > sWebZIndex ? .unity : .webView
        if newTopLayer != topLayerType {
            topLayerType = newTopLayer
            print("[GrowthSDK] 🔝 顶层切换为: \(topLayerType.displayName)")
            print("[GrowthSDK] 🔢 Unity zIndex: \(unityZIndex), WebView zIndex: \(sWebZIndex)")
        }
    }
}
