//
//  SingleLayerGameWebView.swift
//  GrowthSDK
//
//  Created by arvin on 2025/6/15.
//

import Foundation
import SwiftUI
import WebKit

// MARK: - 单层WebView专用
internal struct SingleLayerGameWebView: UIViewControllerRepresentable {
    
    private let url: URL?
    private var onDidReceive: ((WebViewCoordinator.Message) -> Void)?
    private var onLoadIframe: ((WebViewCoordinator) -> Void)?
    private var onDidFinish: ((WebViewCoordinator) -> Void)?
    private var onDidFail: ((Error) -> Void)?
    
    // 单层WebView专用的静态资源
    private static var coordinator: WebViewCoordinator?
    private static var webView: SGWebView?
    
    init(_ url: String) {
        let url = URL(string: url)
        self.url = url
    }
    
    // MARK: -
    func makeCoordinator() -> WebViewCoordinator {
        // 单层WebView复用同一个协调器，但确保回调正确设置
        if let coordinator = SingleLayerGameWebView.coordinator {
            coordinator.onDidReceive = onDidReceive
            coordinator.onLoadIframe = onLoadIframe
            coordinator.onDidFinish = onDidFinish
            coordinator.onDidFail = onDidFail
            print("[H5] [SingleLayerGameWebView] 复用单层WebView协调器")
            return coordinator
        }
        
        let coordinator = WebViewCoordinator()
        print("[H5] [SingleLayerGameWebView] 创建单层WebView协调器")
        coordinator.onDidReceive = onDidReceive
        coordinator.onLoadIframe = onLoadIframe
        coordinator.onDidFinish = onDidFinish
        coordinator.onDidFail = onDidFail
        SingleLayerGameWebView.coordinator = coordinator
        return coordinator
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let webView: SGWebView
        if let existingWebView = SingleLayerGameWebView.webView {
            webView = existingWebView
            print("[H5] [SingleLayerGameWebView] 复用单层WebView")
        } else {
            webView = context.coordinator.makeWebView()
            SingleLayerGameWebView.webView = webView
            print("[H5] [SingleLayerGameWebView] 创建单层WebView")
        }
        
        context.coordinator.webView = webView
        
        let container = UIViewController()
        container.view.addSubview(webView)
        webView.pin(to: container.view)
        
        if let url = url, webView.url != url {
            // 立即加载，减少延迟
            print("[H5] [SingleLayerGameWebView] 立即加载URL：\(url)")
            let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30.0)
            webView.load(request)
        }
        return container
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if let webView = context.coordinator.webView, webView.superview == nil {
            uiViewController.view.addSubview(webView)
            webView.pin(to: uiViewController.view)
            print("[H5] [SingleLayerGameWebView] 重新添加WebView到视图层次")
        }
    }
    
    static func cleanupSharedResources() {
        print("[H5] [SingleLayerGameWebView] 清理共享资源")
        coordinator = nil
        webView = nil
    }
    
}

// MARK: -
internal extension SingleLayerGameWebView {
    
    @discardableResult
    func onReceiveMessage(_ didReceive: @escaping ((WebViewCoordinator.Message) -> Void)) -> SingleLayerGameWebView {
        var view = self
        view.onDidReceive = didReceive
        return view
    }
    
    @discardableResult
    func onLoadIframe(_ loadIframe: @escaping ((WebViewCoordinator) -> Void)) -> SingleLayerGameWebView {
        var view = self
        view.onLoadIframe = loadIframe
        return view
    }
    
    @discardableResult
    func onLoadFinish(_ didFinish: @escaping ((WebViewCoordinator) -> Void)) -> SingleLayerGameWebView {
        var view = self
        view.onDidFinish = didFinish
        return view
    }
    
    @discardableResult
    func onLoadFail(_ didFail: @escaping ((Error) -> Void)) -> SingleLayerGameWebView {
        var view = self
        view.onDidFail = didFail
        return view
    }
    
}
