//
//  MultiLayerGameWebView.swift
//  GrowthSDK
//
//  Created by arvin on 2025/6/15.
//

import Foundation
import SwiftUI
import WebKit

// MARK: - 多层WebView专用
internal struct MultiLayerGameWebView: UIViewControllerRepresentable {
    
    private let url: URL?
    private let layerId: String  // 添加层级ID标识
    private var onDidReceive: ((WebViewCoordinator.Message) -> Void)?
    private var onLoadIframe: ((WebViewCoordinator) -> Void)?
    private var onDidFinish: ((WebViewCoordinator) -> Void)?
    private var onDidFail: ((Error) -> Void)?
    
    // 多层WebView专用的静态资源 - 按层级ID管理
    private static var coordinators: [String: WebViewCoordinator] = [:]
    private static var webViews: [String: SGWebView] = [:]
    
    init(_ url: String, layerId: String) {
        let url = URL(string: url)
        self.url = url
        self.layerId = layerId
    }
    
    // MARK: -
    func makeCoordinator() -> WebViewCoordinator {
        // 每个层级使用独立的协调器
        if let coordinator = MultiLayerGameWebView.coordinators[layerId] {
            coordinator.onDidReceive = onDidReceive
            coordinator.onLoadIframe = onLoadIframe
            coordinator.onDidFinish = onDidFinish
            coordinator.onDidFail = onDidFail
            print("[H5] [MultiLayerGameWebView] 复用层级 \(layerId) 的协调器")
            return coordinator
        }
        
        let coordinator = WebViewCoordinator()
        print("[H5] [MultiLayerGameWebView] 创建层级 \(layerId) 的协调器")
        coordinator.onDidReceive = onDidReceive
        coordinator.onLoadIframe = onLoadIframe
        coordinator.onDidFinish = onDidFinish
        coordinator.onDidFail = onDidFail
        MultiLayerGameWebView.coordinators[layerId] = coordinator
        return coordinator
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let webView: SGWebView
        if let existingWebView = MultiLayerGameWebView.webViews[layerId] {
            webView = existingWebView
            print("[H5] [MultiLayerGameWebView] 复用层级 \(layerId) 的WebView")
        } else {
            webView = context.coordinator.makeWebView()
            MultiLayerGameWebView.webViews[layerId] = webView
            print("[H5] [MultiLayerGameWebView] 创建层级 \(layerId) 的新WebView")
        }
        
        context.coordinator.webView = webView
        
        let container = UIViewController()
        container.view.addSubview(webView)
        webView.pin(to: container.view)
        
        if let url = url, webView.url != url {
            // 立即加载，减少延迟
            print("[H5] [MultiLayerGameWebView] 层级 \(layerId) 立即加载URL：\(url)")
            let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30.0)
            webView.load(request)
        }
        return container
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if let webView = context.coordinator.webView, webView.superview == nil {
            uiViewController.view.addSubview(webView)
            webView.pin(to: uiViewController.view)
            print("[H5] [MultiLayerGameWebView] 层级 \(layerId) 重新添加WebView到视图层次")
        }
    }
    
    static func cleanupSharedResources() {
        print("[H5] [MultiLayerGameWebView] 清理所有共享资源")
        coordinators.removeAll()
        webViews.removeAll()
    }
    
    static func cleanupLayerResources(layerId: String) {
        print("[H5] [MultiLayerGameWebView] 清理层级 \(layerId) 的资源")
        coordinators.removeValue(forKey: layerId)
        webViews.removeValue(forKey: layerId)
    }
    
}

// MARK: -
internal extension MultiLayerGameWebView {
    
    @discardableResult
    func onReceiveMessage(_ didReceive: @escaping ((WebViewCoordinator.Message) -> Void)) -> MultiLayerGameWebView {
        var view = self
        view.onDidReceive = didReceive
        return view
    }
    
    @discardableResult
    func onLoadIframe(_ loadIframe: @escaping ((WebViewCoordinator) -> Void)) -> MultiLayerGameWebView {
        var view = self
        view.onLoadIframe = loadIframe
        return view
    }
    
    @discardableResult
    func onLoadFinish(_ didFinish: @escaping ((WebViewCoordinator) -> Void)) -> MultiLayerGameWebView {
        var view = self
        view.onDidFinish = didFinish
        return view
    }
    
    @discardableResult
    func onLoadFail(_ didFail: @escaping ((Error) -> Void)) -> MultiLayerGameWebView {
        var view = self
        view.onDidFail = didFail
        return view
    }
    
}
