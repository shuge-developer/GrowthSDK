//
//  WebViewCoordinator.swift
// GameWrapper
//
//  Created by arvin on 2025/5/28.
//

@preconcurrency import WebKit

// MARK: -
internal class SGWebView: WKWebView {
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        //print("[H5] [web] \(#function), \(point), \(event?.type.rawValue)")
        return super.hitTest(point, with: event)
    }
    
    override var scrollView: UIScrollView {
        let scrollView = super.scrollView
        //print("[H5] [SGWebView] 访问 scrollView: contentSize=\(scrollView.contentSize), frame=\(scrollView.frame), isScrollEnabled=\(scrollView.isScrollEnabled)")
        return scrollView
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        //print("[H5] [SGWebView] layoutSubviews: frame=\(frame), scrollView.contentSize=\(scrollView.contentSize)")
    }
}

// MARK: -
internal class WebViewCoordinator: NSObject {
    
    internal struct Message {
        var name: String
        var body: Any
    }
    
    // 通知名称
    static let coordinatorDidInitialize = Notification.Name("WebViewCoordinatorDidInitialize")
    static let coordinatorWillDeinitialize = Notification.Name("WebViewCoordinatorWillDeinitialize")
    
    weak var webView: SGWebView?
    var onDidReceive: ((WebViewCoordinator.Message) -> Void)?
    var onLoadIframe: ((WebViewCoordinator) -> Void)?
    var onDidFinish: ((WebViewCoordinator) -> Void)?
    var onDidFail: ((Error) -> Void)?
    
    // 导航状态追踪
    private var hasTriggeredIframeCallback: Bool = false
    // 唯一标识符，用于在通知中识别协调器
    private let id = UUID()
    
    // MARK: -
    override init() {
        super.init()
        print("[H5] [WebCoordinator] 初始化协调器: \(id)")
        // 发送初始化通知
        NotificationCenter.default.post(
            name: WebViewCoordinator.coordinatorDidInitialize,
            object: self,
            userInfo: ["id": id]
        )
    }
    
    deinit {
        print("[H5] [WebCoordinator] 释放协调器: \(id)")
        // 发送销毁通知
        NotificationCenter.default.post(
            name: WebViewCoordinator.coordinatorWillDeinitialize,
            object: self,
            userInfo: ["id": id]
        )
    }
    
    func makeWebView() -> SGWebView {
        print("[H5] [WebCoordinator] 创建 WebView")
        let configuration = WKWebViewConfiguration()
        let userController = WKUserContentController()
        
        //userController.add(self, name: "handlerName")
        configuration.userContentController = userController
        
        let webView = SGWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.alwaysBounceVertical = true
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.bounces = true
        webView.backgroundColor = .white
        
        // 确保 scrollView 设置正确
        print("[H5] [WebCoordinator] WebView 创建完成: scrollView.isScrollEnabled=\(webView.scrollView.isScrollEnabled)")
        print("[H5] [WebCoordinator] WebView scrollView 属性: bounces=\(webView.scrollView.bounces), alwaysBounceVertical=\(webView.scrollView.alwaysBounceVertical)")
        
        self.webView = webView
        return webView
    }
    
}

// MARK: - WKScriptMessageHandler
extension WebViewCoordinator: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("[H5] [web] \(#function), message.name: \(message.name), message.body: \(message.body)")
        onDidReceive?(Message(name: message.name, body: message.body))
    }
}

// MARK: - WKNavigationDelegate
extension WebViewCoordinator: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        print("[H5] [web] \(#function), navigationAction.targetFrame: \(String(describing: navigationAction.targetFrame)) 🌹🌹🌹🌹🌹🌹🌹🌹🌹🌹🌹🌹🌹🌹🌹")
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
            
            if !hasTriggeredIframeCallback {
                print("[H5] [web] 📱 检测到用户点击链接导航，首次触发广告点击回调 2")
                hasTriggeredIframeCallback = true
                DispatchQueue.main.async {
                    self.onLoadIframe?(self)
                }
            }
        }
        return nil
    }
    
    func webView(_ webView: WKWebView, authenticationChallenge challenge: URLAuthenticationChallenge, shouldAllowDeprecatedTLS decisionHandler: @escaping @MainActor (Bool) -> Void) {
        print("[H5] [web] \(#function)")
        decisionHandler(true)
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("[H5] [web] \(#function)")
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        print("[H5] [web] \(#function)")
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: any Error) {
        print("[H5] [web] \(#function)")
    }
    
    @available(iOS 14.5, *)
    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        print("[H5] [web] \(#function)")
    }
    
    @available(iOS 14.5, *)
    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        print("[H5] [web] \(#function)")
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping @MainActor (WKNavigationResponsePolicy) -> Void) {
        print("[H5] [web] \(#function)")
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void) {
        //print("[H5] [web] \(#function), 📱 导航类型: \(navigationAction.navigationType.rawValue), url: \(navigationAction.request.url?.absoluteString.prefix(50))")
        if navigationAction.navigationType == .linkActivated && !hasTriggeredIframeCallback {
            print("[H5] [web] 📱 检测到用户点击链接导航，首次触发广告点击回调 1")
            hasTriggeredIframeCallback = true
            DispatchQueue.main.async {
                self.onLoadIframe?(self)
            }
        } else if navigationAction.navigationType == .linkActivated && hasTriggeredIframeCallback {
            print("[H5] [web] 📱 检测到用户点击链接导航，但已触发过回调，跳过")
        }
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) {
        print("[H5] [web] \(#function)，error：\(error.localizedDescription)")
        onDidFail?(error)
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        print("[H5] [web] \(#function)")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("[H5] [web] \(#function)")
        DispatchQueue.main.async {
            self.onDidFinish?(self)
        }
    }
    
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        print("[H5] [web] \(#function)")
    }
    
    func webViewDidClose(_ webView: WKWebView) {
        print("[H5] [web] \(#function)")
    }
    
}

// MARK: - WKUIDelegate
extension WebViewCoordinator: WKUIDelegate {
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping @MainActor () -> Void) {
        print("[H5] [web] \(#function)，message：\(message)")
        completionHandler()
    }
}

// MARK: -
internal extension WebViewCoordinator {
    
    /// 执行JavaScript
    /// - Parameters:
    ///   - script: JavaScript代码
    ///   - completion: 完成回调
    func runJavaScript(_ script: String?, completion: ((Result<Any, Error>) -> Void)? = nil) {
        guard let webView, let script else {
            print("[H5] [web] 执行 JS 失败: webView 或 script 为 nil")
            completion?(.failure(NSError(domain: "WebViewCoordinator", code: 404, userInfo: [NSLocalizedDescriptionKey: "WebView 或 script 为 nil"])))
            return
        }
        // 检查WebView是否有效
        if webView.superview == nil && webView.window == nil {
            print("[H5] [web] ⚠️ WebView 可能已被销毁，无 superview 和 window")
            completion?(.failure(NSError(domain: "WebViewCoordinator", code: 500, userInfo: [NSLocalizedDescriptionKey: "WebView 可能已被销毁"])))
            return
        }
        // 检查WebView是否正在加载
        if webView.isLoading {
            print("[H5] [web] ⚠️ WebView 正在加载中，可能影响 JS 执行")
        }
        let urlString = webView.url?.absoluteString
        print("[H5] [web] ⚠️ 开始执行 JS: \(script.prefix(50))")
        webView.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("[H5] [web] JS 执行错误: \(error.localizedDescription), urlString: \(urlString)")
                completion?(.failure(error))
            } else {
                print("[H5] [web] JS 执行成功: \(String(describing: result)), urlString: \(urlString)")
                completion?(.success(result ?? ""))
            }
        }
    }
    
    func hookJsConsole() {
        let log = """
            window.console.log = function(message) {
                window.webkit.messageHandlers.messageHandler.postMessage('Console: ' + message);
                return true;
            };
        """
        runJavaScript(log)
    }
    
}

// MARK: -
internal extension WebViewCoordinator {
    
    /// 重置导航状态（用于新任务）
    func resetNavigationState() {
        hasTriggeredIframeCallback = false
        print("[H5] [web] 📱 重置导航状态")
    }
    
}
