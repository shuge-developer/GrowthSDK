//
//  GameWebView.swift
//  GameWrapper
//
//  Created by arvin on 2025/5/28.
//

import Foundation
import SwiftUI
import WebKit

// MARK: -
internal struct GameWebView: UIViewControllerRepresentable {
    
    private let url: URL?
    private var onDidReceive: ((WebViewCoordinator.Message) -> Void)?
    private var onLoadIframe: ((WebViewCoordinator) -> Void)?
    private var onDidFinish: ((WebViewCoordinator) -> Void)?
    private var onDidFail: ((Error) -> Void)?
    
    private static var coordinator: WebViewCoordinator?
    private static var webView: SGWebView?
    
    internal init(_ url: String) {
        let url = URL(string: url)
        self.url = url
    }
    
    // MARK: -
    func makeCoordinator() -> WebViewCoordinator {
        if let coordinator = GameWebView.coordinator {
            coordinator.onDidReceive = onDidReceive
            coordinator.onLoadIframe = onLoadIframe
            coordinator.onDidFinish = onDidFinish
            coordinator.onDidFail = onDidFail
            return coordinator
        }
        let coordinator = WebViewCoordinator()
        coordinator.onDidReceive = onDidReceive
        coordinator.onLoadIframe = onLoadIframe
        coordinator.onDidFinish = onDidFinish
        coordinator.onDidFail = onDidFail
        GameWebView.coordinator = coordinator
        return coordinator
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let webView: SGWebView
        if let existingWebView = GameWebView.webView {
            webView = existingWebView
            print("[H5] [GameWebView] 复用现有WebView")
        } else {
            webView = context.coordinator.makeWebView()
            GameWebView.webView = webView
            print("[H5] [GameWebView] 创建新WebView")
        }
        
        context.coordinator.webView = webView
        
        let container = UIViewController()
        container.view.addSubview(webView)
        webView.pin(to: container.view)
        
        if let url = url, webView.url != url {
            DispatchQueue.mainAsyncAfter(1) {
                print("[H5] [GameWebView] 加载URL：\(url)")
                let request = URLRequest(url: url)
                webView.load(request)
            }
        }
        return container
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if let webView = context.coordinator.webView, webView.superview == nil {
            uiViewController.view.addSubview(webView)
            webView.pin(to: uiViewController.view)
            print("[H5] [GameWebView] 重新添加WebView到视图层次")
        }
    }
    
    internal static func cleanupSharedResources() {
        print("[H5] [GameWebView] 清理共享资源")
        coordinator = nil
        webView = nil
    }
    
}

// MARK: -
internal extension GameWebView {
    
    @discardableResult
    func onReceiveMessage(_ didReceive: @escaping ((WebViewCoordinator.Message) -> Void)) -> GameWebView {
        var view = self
        view.onDidReceive = didReceive
        return view
    }
    
    @discardableResult
    func onLoadIframe(_ loadIframe: @escaping ((WebViewCoordinator) -> Void)) -> GameWebView {
        var view = self
        view.onLoadIframe = loadIframe
        return view
    }
    
    @discardableResult
    func onLoadFinish(_ didFinish: @escaping ((WebViewCoordinator) -> Void)) -> GameWebView {
        var view = self
        view.onDidFinish = didFinish
        return view
    }
    
    @discardableResult
    func onLoadFail(_ didFail: @escaping ((Error) -> Void)) -> GameWebView {
        var view = self
        view.onDidFail = didFail
        return view
    }
    
}
