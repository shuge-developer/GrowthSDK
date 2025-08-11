//
//  IframeAdClickHandler.swift
//  GrowthSDK
//
//  Created by arvin on 2025/1/30.
//

import Foundation
import WebKit

/// iframe广告点击处理器
class IframeAdClickHandler {
    
    // MARK: - 属性
    private weak var webViewCoordinator: WebViewCoordinator?
    private let adServerHosts = [
        "googleads.g.doubleclick.net",
        "pagead2.googlesyndication.com",
        "securepubads.g.doubleclick.net",
        "ads.google.com",
        "googlesyndication.com",
        "doubleclick.net",
        "adservice.google.com"
    ]
    
    private let adKeywords = ["ads", "ad", "pagead", "adk", "adf", "slotname"]
    private let landingPageParams = ["url", "target", "dest", "landing", "click", "redirect", "u"]
    
    // MARK: - 初始化
    init(webViewCoordinator: WebViewCoordinator?) {
        self.webViewCoordinator = webViewCoordinator
    }
    
    // MARK: - 公共方法
    
    /// 处理iframe广告点击
    /// - Parameters:
    ///   - ad: 广告元素
    ///   - clickPoint: 点击位置
    ///   - jsConfig: JS配置
    ///   - completion: 完成回调
    func handleIframeAdClick(ad: AdElement, clickPoint: CGPoint, jsConfig: JSConfig?, completion: @escaping (IframeClickResult) -> Void) {
        print("[H5] [IframeHandler] 开始处理iframe广告点击")
        
        guard let iframeJs = jsConfig?.iframeJs, !iframeJs.isEmpty else {
            print("[H5] [IframeHandler] ⚠️ iframeJs配置为空")
            completion(.failure(.invalidConfig))
            return
        }
        
        let formattedScript = String(format: iframeJs, clickPoint.x, clickPoint.y)
        print("[H5] [IframeHandler] 执行iframe检测脚本")
        
        webViewCoordinator?.runJavaScript(formattedScript) { [weak self] result in
            guard let self = self else {
                completion(.failure(.webViewReleased))
                return
            }
            
            switch result {
            case .success(let string):
                let iframeResult = IframeResult.result(from: string)
                print("[H5] [IframeHandler] iframe检测结果: \(string)")
                
                if iframeResult.found, let url = iframeResult.url {
                    self.handleIframeURL(url, ad: ad, completion: completion)
                } else {
                    print("[H5] [IframeHandler] 未找到iframe")
                    completion(.failure(.noIframeFound))
                }
                
            case .failure(let error):
                print("[H5] [IframeHandler] iframe检测失败: \(error)")
                completion(.failure(.scriptExecutionFailed(error)))
            }
        }
    }
    
    // MARK: - 私有方法
    
    /// 处理iframe URL
    private func handleIframeURL(_ url: URL, ad: AdElement, completion: @escaping (IframeClickResult) -> Void) {
        print("[H5] [IframeHandler] 处理iframe URL: \(url)")
        
        // 检查是否是广告服务器URL
        if isAdServerURL(url) {
            print("[H5] [IframeHandler] 检测到广告服务器URL，尝试获取真正的广告落地页")
            handleAdServerURL(url, ad: ad, completion: completion)
        } else {
            print("[H5] [IframeHandler] 直接加载非广告服务器URL")
            completion(.success(.directLoad(url)))
        }
    }
    
    /// 检查URL是否是广告服务器URL
    private func isAdServerURL(_ url: URL) -> Bool {
        let host = url.host?.lowercased() ?? ""
        let path = url.path.lowercased()
        let urlString = url.absoluteString.lowercased()
        
        // 检查是否是广告服务器域名
        if adServerHosts.contains(where: { host.contains($0) }) {
            print("[H5] [IframeHandler] 检测到广告服务器域名: \(host)")
            return true
        }
        
        // 检查URL路径是否包含广告相关关键词
        if adKeywords.contains(where: { path.contains($0) || urlString.contains($0) }) {
            print("[H5] [IframeHandler] 检测到广告关键词: \(path)")
            return true
        }
        
        // 检查URL参数中的广告标识
        let adParamKeywords = ["ads", "ad", "advert", "banner", "sponsor", "tracking", "pixel", "beacon"]
        if let query = url.query?.lowercased() {
            if adParamKeywords.contains(where: { query.contains($0) }) {
                print("[H5] [IframeHandler] 检测到广告参数: \(query)")
                return true
            }
        }
        
        // 检查URL片段中的广告标识
        if let fragment = url.fragment?.lowercased() {
            if adParamKeywords.contains(where: { fragment.contains($0) }) {
                print("[H5] [IframeHandler] 检测到广告片段: \(fragment)")
                return true
            }
        }
        
        return false
    }
    
    /// 处理广告服务器URL
    private func handleAdServerURL(_ adServerURL: URL, ad: AdElement, completion: @escaping (IframeClickResult) -> Void) {
        print("[H5] [IframeHandler] 处理广告服务器URL: \(adServerURL)")
        
        // 方法1: 尝试从URL参数中提取广告落地页
        if let landingPageURL = extractLandingPageFromURL(adServerURL) {
            print("[H5] [IframeHandler] 从URL参数中提取到落地页: \(landingPageURL)")
            completion(.success(.directLoad(landingPageURL)))
            return
        }
        
        // 方法2: 模拟真实点击行为
        print("[H5] [IframeHandler] 无法从URL参数提取落地页，开始模拟真实点击")
        simulateRealClick(ad: ad, completion: completion)
    }
    
    /// 从广告服务器URL中提取落地页URL
    private func extractLandingPageFromURL(_ url: URL) -> URL? {
        let urlString = url.absoluteString
        print("[H5] [IframeHandler] 尝试从URL提取落地页: \(urlString)")
        
        // 获取当前页面的URL，用于过滤
        let currentPageURL = webViewCoordinator?.webView?.url?.absoluteString ?? ""
        print("[H5] [IframeHandler] 当前页面URL: \(currentPageURL)")
        
        // 尝试从URL参数中提取落地页
        let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = urlComponents?.queryItems ?? []
        
        // 按优先级排序的参数名
        let priorityParams = ["url", "target", "dest", "landing", "click", "redirect", "u", "link", "href"]
        
        for param in priorityParams {
            if let value = queryItems.first(where: { $0.name.lowercased() == param })?.value {
                print("[H5] [IframeHandler] 找到参数 \(param): \(value)")
                
                // 尝试多种解码方式
                var decodedValue = value
                
                // 1. 直接URL解码
                if let urlDecoded = value.removingPercentEncoding {
                    decodedValue = urlDecoded
                }
                
                // 2. 双重编码解码
                if let doubleDecoded = decodedValue.removingPercentEncoding {
                    decodedValue = doubleDecoded
                }
                
                // 3. Base64解码（某些广告服务器使用Base64编码）
                if decodedValue.hasPrefix("data:") || decodedValue.contains("base64") {
                    if let base64Data = Data(base64Encoded: decodedValue),
                       let base64String = String(data: base64Data, encoding: .utf8) {
                        decodedValue = base64String
                    }
                }
                
                // 检查是否是有效的HTTP URL
                if decodedValue.hasPrefix("http") {
                    // 检查提取的URL是否是当前页面URL
                    if decodedValue == currentPageURL {
                        print("[H5] [IframeHandler] 提取的URL是当前页面URL，跳过: \(decodedValue)")
                        continue
                    }
                    
                    // 检查是否是广告服务器URL
                    if let extractedURL = URL(string: decodedValue) {
                        if isAdServerURL(extractedURL) {
                            print("[H5] [IframeHandler] 提取的URL是广告服务器URL，跳过: \(decodedValue)")
                            continue
                        }
                        
                        // 检查是否是无效的URL（如javascript:、data:等）
                        if extractedURL.scheme?.lowercased() == "javascript" ||
                            extractedURL.scheme?.lowercased() == "data" ||
                            extractedURL.scheme?.lowercased() == "about" {
                            print("[H5] [IframeHandler] 提取的URL是无效协议，跳过: \(decodedValue)")
                            continue
                        }
                        
                        print("[H5] [IframeHandler] 成功提取落地页: \(decodedValue)")
                        return extractedURL
                    }
                }
            }
        }
        
        // 尝试从URL中直接查找http链接（更精确的正则表达式）
        let patterns = [
            "https?://[^&\\s\"']+",           // 标准HTTP链接
            "https?://[^&\\s\"']*[^&\\s\"']", // 避免截断的链接
            "https?://[a-zA-Z0-9.-]+[^&\\s]*" // 更宽松的匹配
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: urlString, options: [], range: NSRange(location: 0, length: urlString.count)) {
                let matchRange = Range(match.range, in: urlString)!
                let extractedURL = String(urlString[matchRange])
                
                // 清理URL末尾的无效字符
                var cleanURL = extractedURL
                while cleanURL.hasSuffix("&") || cleanURL.hasSuffix("?") || cleanURL.hasSuffix(",") {
                    cleanURL = String(cleanURL.dropLast())
                }
                
                if let decodedURL = cleanURL.removingPercentEncoding,
                   let landingURL = URL(string: decodedURL),
                   !isAdServerURL(landingURL), // 确保提取的不是另一个广告服务器URL
                   decodedURL != currentPageURL, // 确保不是当前页面URL
                   landingURL.scheme?.lowercased() != "javascript", // 排除javascript协议
                   landingURL.scheme?.lowercased() != "data" { // 排除data协议
                    print("[H5] [IframeHandler] 通过正则提取落地页: \(decodedURL)")
                    return landingURL
                }
            }
        }
        
        print("[H5] [IframeHandler] 无法从URL提取有效的落地页")
        return nil
    }
    
    /// 模拟真实点击行为
    private func simulateRealClick(ad: AdElement, completion: @escaping (IframeClickResult) -> Void) {
        print("[H5] [IframeHandler] 开始模拟真实点击行为")
        
        let clickPoint = ad.area?.randomPoint ?? .zero
        let enhancedClickScript = createEnhancedClickScript()
        let formattedScript = String(format: enhancedClickScript, clickPoint.x, clickPoint.y)
        
        print("[H5] [IframeHandler] 执行增强点击脚本")
        webViewCoordinator?.runJavaScript(formattedScript) { [weak self] result in
            guard let self = self else {
                completion(.failure(.webViewReleased))
                return
            }
            
            switch result {
            case .success(let string):
                let iframeResult = IframeResult.result(from: string)
                print("[H5] [IframeHandler] 增强点击结果: \(string)")
                
                if iframeResult.found {
                    // 等待一段时间后检查iframe是否有新的src
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.checkIframeURLChange(ad: ad, completion: completion)
                    }
                } else {
                    print("[H5] [IframeHandler] 增强点击未找到iframe")
                    completion(.failure(.noIframeFound))
                }
                
            case .failure(let error):
                print("[H5] [IframeHandler] 增强点击失败: \(error)")
                completion(.failure(.scriptExecutionFailed(error)))
            }
        }
    }
    
    /// 创建增强点击脚本
    private func createEnhancedClickScript() -> String {
        return """
        (function(x, y) {
            try {
                // 输入参数验证
                if (typeof x !== 'number' || typeof y !== 'number' || isNaN(x) || isNaN(y)) {
                    console.warn('Invalid click coordinates:', x, y);
                    return {found: false, error: 'Invalid coordinates'};
                }
                
                var iframes = document.querySelectorAll('iframe');
                if (iframes.length === 0) {
                    console.log('No iframes found on page');
                    return {found: false, error: 'No iframes found'};
                }
                
                var clickX = Math.round(x);
                var clickY = Math.round(y);
                var clickedIframe = null;
                var rect = null;
                
                // 找到点击位置的iframe，增加容错范围
                for (var i = 0; i < iframes.length; i++) {
                    var iframe = iframes[i];
                    
                    // 检查iframe是否可见
                    var iframeStyle = window.getComputedStyle(iframe);
                    if (iframeStyle.display === 'none' || iframeStyle.visibility === 'hidden' || iframeStyle.opacity === '0') {
                        continue;
                    }
                    
                    rect = iframe.getBoundingClientRect();
                    
                    // 增加1px的容错范围，避免边界点击失败
                    if (clickX >= rect.left - 1 && clickX <= rect.right + 1 && 
                        clickY >= rect.top - 1 && clickY <= rect.bottom + 1) {
                        clickedIframe = iframe;
                        break;
                    }
                }
                
                if (!clickedIframe) {
                    console.log('No iframe found at click position:', clickX, clickY);
                    return {found: false, error: 'No iframe at position'};
                }
                
                // 获取iframe信息
                var iframeInfo = {
                    found: true,
                    id: clickedIframe.id || '',
                    className: clickedIframe.className || '',
                    src: clickedIframe.src || '',
                    x: Math.round(rect.left),
                    y: Math.round(rect.top),
                    width: Math.round(rect.width),
                    height: Math.round(rect.height),
                    relativeX: Math.round(clickX - rect.left),
                    relativeY: Math.round(clickY - rect.top),
                    iframeClicked: false,
                    crossOriginError: false,
                    error: null
                };
                
                // 尝试在iframe内部执行点击
                try {
                    // 检查iframe是否已加载
                    if (clickedIframe.contentDocument && clickedIframe.contentDocument.readyState === 'complete') {
                        var iframeDoc = clickedIframe.contentDocument;
                        
                        // 在iframe内部查找可点击元素，按优先级排序
                        var clickableSelectors = [
                            'a[href]:not([href=""])',           // 有href的链接
                            'button:not([disabled])',           // 未禁用的按钮
                            '[onclick]',                        // 有onclick的元素
                            '[role="button"]',                  // 按钮角色
                            '[data-ad]',                        // 广告数据属性
                            '[data-ad-client]',                 // Google AdSense
                            '.ad-click',                        // 广告点击类
                            '.clickable',                       // 可点击类
                            '[tabindex]:not([tabindex="-1"])'   // 可聚焦元素
                        ];
                        
                        var clickableElements = [];
                        for (var j = 0; j < clickableSelectors.length; j++) {
                            var elements = iframeDoc.querySelectorAll(clickableSelectors[j]);
                            if (elements.length > 0) {
                                clickableElements = Array.from(elements);
                                break;
                            }
                        }
                        
                        if (clickableElements.length > 0) {
                            // 选择最合适的元素进行点击
                            var targetElement = clickableElements[0];
                            
                            // 如果有多个元素，优先选择在点击位置附近的
                            if (clickableElements.length > 1) {
                                var minDistance = Infinity;
                                for (var k = 0; k < clickableElements.length; k++) {
                                    var element = clickableElements[k];
                                    var elementRect = element.getBoundingClientRect();
                                    var elementCenterX = elementRect.left + elementRect.width / 2;
                                    var elementCenterY = elementRect.top + elementRect.height / 2;
                                    var distance = Math.sqrt(Math.pow(clickX - elementCenterX, 2) + Math.pow(clickY - elementCenterY, 2));
                                    if (distance < minDistance) {
                                        minDistance = distance;
                                        targetElement = element;
                                    }
                                }
                            }
                            
                            // 执行点击
                            targetElement.click();
                            iframeInfo.iframeClicked = true;
                            console.log('Clicked iframe element:', targetElement.tagName, targetElement.className);
                        } else {
                            // 如果没有找到可点击元素，尝试在iframe内部模拟点击
                            var event = new MouseEvent('click', {
                                bubbles: true,
                                cancelable: true,
                                view: window,
                                detail: 1,
                                clientX: clickX,
                                clientY: clickY,
                                screenX: clickX,
                                screenY: clickY
                            });
                            
                            var elementAtPoint = iframeDoc.elementFromPoint(clickX - rect.left, clickY - rect.top);
                            if (elementAtPoint) {
                                elementAtPoint.dispatchEvent(event);
                                iframeInfo.iframeClicked = true;
                                console.log('Clicked element at point:', elementAtPoint.tagName, elementAtPoint.className);
                            } else {
                                // 如果elementFromPoint失败，尝试在document上触发点击
                                iframeDoc.dispatchEvent(event);
                                iframeInfo.iframeClicked = true;
                                console.log('Clicked on iframe document');
                            }
                        }
                    } else {
                        console.log('Iframe not fully loaded, waiting...');
                        iframeInfo.error = 'Iframe not loaded';
                    }
                } catch (e) {
                    // 跨域限制，无法访问iframe内容
                    iframeInfo.crossOriginError = true;
                    iframeInfo.error = e.message;
                    console.log('Cross-origin error:', e.message);
                }
                
                // 监听iframe的src变化，增加超时和清理机制
                var originalSrc = clickedIframe.src;
                var checkInterval = null;
                var timeoutId = null;
                
                checkInterval = setInterval(function() {
                    try {
                        if (clickedIframe.src !== originalSrc) {
                            iframeInfo.newSrc = clickedIframe.src;
                            clearInterval(checkInterval);
                            clearTimeout(timeoutId);
                            console.log('Iframe src changed to:', clickedIframe.src);
                        }
                    } catch (e) {
                        console.log('Error checking iframe src:', e.message);
                        clearInterval(checkInterval);
                        clearTimeout(timeoutId);
                    }
                }, 100);
                
                // 5秒后停止监听
                timeoutId = setTimeout(function() {
                    if (checkInterval) {
                        clearInterval(checkInterval);
                        console.log('Iframe src monitoring timeout');
                    }
                }, 5000);
                
                return iframeInfo;
                
            } catch (e) {
                console.error('Error in enhanced click script:', e.message);
                return {found: false, error: e.message};
            }
        })(%f, %f)
        """
    }
    
    /// 检查iframe URL变化
    private func checkIframeURLChange(ad: AdElement, completion: @escaping (IframeClickResult) -> Void) {
        let checkScript = """
        (function() {
            try {
                var iframes = document.querySelectorAll('iframe');
                var results = [];
                
                for (var i = 0; i < iframes.length; i++) {
                    var iframe = iframes[i];
                    var iframeInfo = {
                        id: iframe.id || '',
                        className: iframe.className || '',
                        src: iframe.src || '',
                        currentSrc: '',
                        crossOriginError: false,
                        error: null,
                        visible: true,
                        loaded: false
                    };
                    
                    // 检查iframe是否可见
                    try {
                        var iframeStyle = window.getComputedStyle(iframe);
                        iframeInfo.visible = !(iframeStyle.display === 'none' || iframeStyle.visibility === 'hidden' || iframeStyle.opacity === '0');
                    } catch (e) {
                        iframeInfo.visible = false;
                        iframeInfo.error = 'Style check failed: ' + e.message;
                    }
                    
                    // 检查iframe是否已加载
                    try {
                        if (iframe.contentDocument) {
                            iframeInfo.loaded = iframe.contentDocument.readyState === 'complete';
                        }
                    } catch (e) {
                        iframeInfo.loaded = false;
                    }
                    
                    // 尝试安全地获取iframe的当前URL
                    try {
                        if (iframe.contentWindow && iframe.contentWindow.location) {
                            iframeInfo.currentSrc = iframe.contentWindow.location.href || '';
                        }
                    } catch (e) {
                        // 跨域限制，无法访问iframe内容
                        iframeInfo.crossOriginError = true;
                        iframeInfo.error = 'Cross-origin access denied: ' + e.message;
                    }
                    
                    results.push(iframeInfo);
                }
                
                return JSON.stringify(results);
                
            } catch (e) {
                console.error('Error in iframe URL check script:', e.message);
                return JSON.stringify([{
                    error: 'Script execution failed: ' + e.message,
                    crossOriginError: false
                }]);
            }
        })()
        """
        
        webViewCoordinator?.runJavaScript(checkScript) { [weak self] result in
            guard let self = self else {
                completion(.failure(.webViewReleased))
                return
            }
            
            switch result {
            case .success(let string):
                print("[H5] [IframeHandler] iframe检查结果: \(string)")
                
                // 解析结果并尝试加载新的URL
                if let jsonString = string as? String,
                   let data = jsonString.data(using: .utf8),
                   let iframeResults = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    
                    var hasCrossOriginError = false
                    var hasVisibleIframe = false
                    var hasLoadedIframe = false
                    
                    for iframeResult in iframeResults {
                        // 记录详细的iframe信息
                        let iframeId = iframeResult["id"] as? String ?? "unknown"
                        let iframeClass = iframeResult["className"] as? String ?? ""
                        let isVisible = iframeResult["visible"] as? Bool ?? false
                        let isLoaded = iframeResult["loaded"] as? Bool ?? false
                        let error = iframeResult["error"] as? String
                        
                        print("[H5] [IframeHandler] iframe[\(iframeId)] 可见:\(isVisible) 已加载:\(isLoaded) 错误:\(error ?? "无")")
                        
                        if isVisible {
                            hasVisibleIframe = true
                        }
                        
                        if isLoaded {
                            hasLoadedIframe = true
                        }
                        
                        // 检查是否有跨域错误
                        if let crossOriginError = iframeResult["crossOriginError"] as? Bool, crossOriginError {
                            hasCrossOriginError = true
                            print("[H5] [IframeHandler] iframe[\(iframeId)] 跨域限制")
                            continue
                        }
                        
                        // 检查是否有脚本执行错误
                        if let error = error, error.contains("Script execution failed") {
                            print("[H5] [IframeHandler] iframe[\(iframeId)] 脚本执行错误: \(error)")
                            continue
                        }
                        
                        // 尝试获取当前URL
                        if let currentSrc = iframeResult["currentSrc"] as? String,
                           !currentSrc.isEmpty {
                            print("[H5] [IframeHandler] iframe[\(iframeId)] 当前URL: \(currentSrc)")
                            
                            if let url = URL(string: currentSrc) {
                                if self.isAdServerURL(url) {
                                    print("[H5] [IframeHandler] iframe[\(iframeId)] URL是广告服务器，跳过")
                                    continue
                                } else {
                                    print("[H5] [IframeHandler] 找到有效的iframe URL: \(currentSrc)")
                                    completion(.success(.directLoad(url)))
                                    return
                                }
                            } else {
                                print("[H5] [IframeHandler] iframe[\(iframeId)] URL格式无效: \(currentSrc)")
                            }
                        }
                    }
                    
                    // 根据检查结果决定处理策略
                    if hasCrossOriginError {
                        print("[H5] [IframeHandler] 检测到跨域限制，使用原生弹窗")
                        completion(.success(.useNativePopup))
                        return
                    }
                    
                    if !hasVisibleIframe {
                        print("[H5] [IframeHandler] 没有可见的iframe，使用原生弹窗")
                        completion(.success(.useNativePopup))
                        return
                    }
                    
                    if !hasLoadedIframe {
                        print("[H5] [IframeHandler] iframe未完全加载，等待后重试")
                        // 等待iframe加载完成后重试
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.checkIframeURLChange(ad: ad, completion: completion)
                        }
                        return
                    }
                }
                
                // 如果没有找到新的URL，使用原始逻辑
                print("[H5] [IframeHandler] 未找到有效的iframe URL，使用原生弹窗")
                completion(.success(.useNativePopup))
                
            case .failure(let error):
                print("[H5] [IframeHandler] iframe检查失败: \(error)")
                completion(.success(.useNativePopup))
            }
        }
    }
}

// MARK: - 结果枚举

/// iframe点击结果
enum IframeClickResult {
    case success(IframeClickSuccess)
    case failure(IframeClickError)
}

/// iframe点击成功类型
enum IframeClickSuccess {
    case directLoad(URL)      // 直接加载URL
    case useNativePopup       // 使用原生弹窗
}

/// iframe点击错误类型
enum IframeClickError: Error {
    case invalidConfig        // 配置无效
    case webViewReleased      // WebView已释放
    case noIframeFound        // 未找到iframe
    case scriptExecutionFailed(Error) // 脚本执行失败
}
