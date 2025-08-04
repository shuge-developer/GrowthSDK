//
//  GameWrapperLayerManager.swift
//  GameWrapper
//
//  Created by arvin on 2025/8/4.
//

import SwiftUI
import Combine

// MARK: - 层级类型定义
internal enum LayerType: String, CaseIterable {
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
internal class GameWrapperLayerManager: ObservableObject {
    
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
