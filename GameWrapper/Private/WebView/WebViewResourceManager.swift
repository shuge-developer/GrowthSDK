//
//  WebViewResourceManager.swift
//  GameWrapper
//
//  Created by arvin on 2025/6/15.
//

import Foundation

// MARK: - WebView资源管理器
/// 统一管理多层和单层WebView的资源清理
class WebViewResourceManager {
    
    static let shared = WebViewResourceManager()
    
    private init() {}
    
    /// 清理所有WebView资源
    func cleanupAllResources() {
        print("[H5] [WebViewResourceManager] 🧹 开始清理所有WebView资源")
        
        // 清理多层WebView资源
        MultiLayerGameWebView.cleanupSharedResources()
        
        // 清理单层WebView资源
        SingleLayerGameWebView.cleanupSharedResources()
        
        print("[H5] [WebViewResourceManager] ✅ 所有WebView资源清理完成")
    }
    
    /// 清理多层WebView资源
    func cleanupMultiLayerResources() {
        print("[H5] [WebViewResourceManager] 🧹 清理多层WebView资源")
        MultiLayerGameWebView.cleanupSharedResources()
    }
    
    /// 清理多层WebView指定层级的资源
    func cleanupMultiLayerResources(for layerId: String) {
        print("[H5] [WebViewResourceManager] 🧹 清理多层WebView层级 \(layerId) 的资源")
        MultiLayerGameWebView.cleanupLayerResources(layerId: layerId)
    }
    
    /// 清理单层WebView资源
    func cleanupSingleLayerResources() {
        print("[H5] [WebViewResourceManager] 🧹 清理单层WebView资源")
        SingleLayerGameWebView.cleanupSharedResources()
    }
    
}
