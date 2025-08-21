//
//  WebViewScrollInteractor.swift
//  GrowthSDK
//
//  Created by arvin on 2025/6/7.
//

import UIKit
import WebKit
import Foundation

// MARK: - 滑动交互配置
/// 滑动交互的配置参数
internal struct ScrollInteractionConfig {
    /// 短页面的高度阈值倍数（相对于屏幕高度）
    let shortPageThreshold: CGFloat
    /// 滑动距离范围
    let scrollDistanceRange: (min: CGFloat, max: CGFloat)
    /// 短页面滑动距离范围
    let shortPageScrollRange: (min: CGFloat, max: CGFloat)
    /// 滑动持续时间范围
    let durationRange: (min: TimeInterval, max: TimeInterval)
    /// 滑动间隔时间范围
    let pauseRange: (min: TimeInterval, max: TimeInterval)
    /// 最大重试次数
    let maxRetryCount: Int
    /// 智能浏览的最大滑动次数
    let maxSmartScrolls: Int
    
    /// 默认配置
    static let `default` = ScrollInteractionConfig(
        shortPageThreshold: 1.5,
        scrollDistanceRange: (min: 150, max: 300),
        shortPageScrollRange: (min: 50, max: 100),
        durationRange: (min: 1.5, max: 2.5),
        pauseRange: (min: 0.5, max: 2.0),
        maxRetryCount: 5,
        maxSmartScrolls: 5
    )
    
    /// 多层WebView配置
    static let multiLayer = ScrollInteractionConfig(
        shortPageThreshold: 1.5,
        scrollDistanceRange: (min: 150, max: 300),
        shortPageScrollRange: (min: 50, max: 100),
        durationRange: (min: 1.5, max: 2.5),
        pauseRange: (min: 0.5, max: 1.5),
        maxRetryCount: 3,
        maxSmartScrolls: 3
    )
    
    /// 单层WebView配置
    static let singleLayer = ScrollInteractionConfig(
        shortPageThreshold: 1.5,
        scrollDistanceRange: (min: 150, max: 400),
        shortPageScrollRange: (min: 50, max: 150),
        durationRange: (min: 1.0, max: 3.0),
        pauseRange: (min: 0.5, max: 2.0),
        maxRetryCount: 5,
        maxSmartScrolls: 5
    )
}

// MARK: - 滑动交互类型
/// 滑动交互的类型
internal enum ScrollInteractionType {
    /// 初始浏览滑动
    case initialBrowsing
    /// 重试滑动寻找广告
    case retryForAd
    /// 滑动到指定广告位置
    case scrollToAd(AdElement)
    /// 二级页面交互滑动
    case secondaryPageInteraction
    /// 指定次数的滑动（通用滑动，可用于单层/多层）
    case scrollWithCount(Int)
    /// 滑动+功能点击的混合操作
    case scrollAndFunctionClick
    
    /// 获取类型描述
    var description: String {
        switch self {
        case .initialBrowsing:
            return "初始浏览"
        case .retryForAd:
            return "重试寻找广告"
        case .scrollToAd(let ad):
            return "滑动到广告(\(ad.type.rawValue))"
        case .secondaryPageInteraction:
            return "二级页面交互"
        case .scrollWithCount(let count):
            return "指定次数滑动(\(count)次)"
        case .scrollAndFunctionClick:
            return "滑动+功能点击"
        }
    }
}

// MARK: - 滑动结果
/// 滑动操作的结果
internal enum ScrollInteractionResult {
    /// 滑动成功完成
    case success
    /// 滑动失败
    case failure(Error)
    /// 内容不足以滑动
    case insufficientContent
    /// 已到达底部，建议重置位置
    case reachedBottom
    
    /// 是否成功
    var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }
}

// MARK: - 滑动任务配置
/// 滑动任务的配置信息
internal struct ScrollTaskConfig {
    /// 开始滑动前的延迟时间（秒）
    let startDelay: TimeInterval
    /// 任务配置（可选，用于获取任务相关配置）
    let taskConfig: LinkTask?
    
    /// 创建滑动任务配置
    /// - Parameters:
    ///   - task: 任务配置对象
    ///   - minimumDelay: 最小延迟时间，默认为2秒
    init(task: LinkTask?, minimumDelay: TimeInterval = 2.0) {
        self.taskConfig = task
        if let task = task {
            self.startDelay = max(TimeInterval(task.startSlideTime), minimumDelay)
        } else {
            self.startDelay = minimumDelay
        }
    }
    
    /// 创建滑动任务配置
    /// - Parameter delay: 指定的延迟时间
    init(startDelay: TimeInterval) {
        self.startDelay = startDelay
        self.taskConfig = nil
    }
}

// MARK: - WebView滑动交互器
/// 统一的WebView滑动交互工具类
/// 封装所有WebView滑动相关的功能，提供统一的接口
internal final class WebViewScrollInteractor {
    
    // MARK: - 属性
    private let config: ScrollInteractionConfig
    private weak var webView: WKWebView?
    private var retryCount: Int = 0
    private var isExecuting: Bool = false
    
    // MARK: - 初始化
    /// 初始化滑动交互器
    /// - Parameters:
    ///   - webView: 目标WebView
    ///   - config: 滑动配置，默认使用标准配置
    init(webView: WKWebView, config: ScrollInteractionConfig = .default) {
        self.webView = webView
        self.config = config
    }
    
    // MARK: - 公共接口
    
    /// 执行滑动任务（带延迟控制）
    /// - Parameters:
    ///   - type: 滑动类型
    ///   - taskConfig: 滑动任务配置
    ///   - completion: 完成回调，返回滑动结果
    func performScrollTask(
        type: ScrollInteractionType,
        taskConfig: ScrollTaskConfig,
        completion: @escaping (ScrollInteractionResult) -> Void
    ) {
        guard !isExecuting else {
            completion(.failure(ScrollInteractionError.taskInProgress))
            return
        }
        guard let webView = webView else {
            completion(.failure(ScrollInteractionError.webViewUnavailable))
            return
        }
        isExecuting = true
        DispatchQueue.main.asyncAfter(deadline: .now() + taskConfig.startDelay) { [weak self] in
            guard let self = self else {
                completion(.failure(ScrollInteractionError.interactorReleased))
                return
            }
            guard let webView = self.webView else {
                self.isExecuting = false
                completion(.failure(ScrollInteractionError.webViewUnavailable))
                return
            }
            // 执行实际的滑动交互
            self.performScrollInteraction(type: type) { result in
                self.isExecuting = false
                completion(result)
            }
        }
    }
    
    /// 执行滑动交互（立即执行）
    /// - Parameters:
    ///   - type: 滑动类型
    ///   - completion: 完成回调，返回滑动结果
    func performScrollInteraction(
        type: ScrollInteractionType,
        completion: @escaping (ScrollInteractionResult) -> Void
    ) {
        guard let webView = webView else {
            completion(.failure(ScrollInteractionError.webViewUnavailable))
            return
        }
        let scrollView = webView.scrollView
        let maxScrollOffset = max(0, scrollView.contentSize.height - scrollView.frame.height)
        if maxScrollOffset <= 0 {
            completion(.insufficientContent)
            return
        }
        switch type {
        case .initialBrowsing:
            performInitialBrowsingScroll(scrollView: scrollView, completion: completion)
            
        case .retryForAd:
            performRetryScroll(scrollView: scrollView, completion: completion)
            
        case .scrollToAd(let ad):
            performScrollToAd(ad, scrollView: scrollView, completion: completion)
            
        case .secondaryPageInteraction:
            performSecondaryPageScroll(scrollView: scrollView, completion: completion)
            
        case .scrollWithCount(let count):
            performScrollWithCount(count, scrollView: scrollView, completion: completion)
            
        case .scrollAndFunctionClick:
            performScrollAndFunctionClick(scrollView: scrollView, completion: completion)
        }
    }
    
    /// 重置重试计数
    func resetRetryCount() {
        retryCount = 0
    }
    
    /// 获取当前重试次数
    var currentRetryCount: Int {
        return retryCount
    }
    
    /// 是否达到最大重试次数
    var hasReachedMaxRetry: Bool {
        return retryCount >= config.maxRetryCount
    }
    
    /// 是否正在执行滑动任务
    var isTaskExecuting: Bool {
        return isExecuting
    }
    
    // MARK: - 私有方法
    
    /// 执行初始浏览滑动
    private func performInitialBrowsingScroll(
        scrollView: UIScrollView,
        completion: @escaping (ScrollInteractionResult) -> Void
    ) {
        // 使用智能浏览功能，模拟真实用户行为
        scrollView.simulateSmartBrowsing(maxScrolls: config.maxSmartScrolls) { [weak self] in
            guard let self = self else {
                completion(.failure(ScrollInteractionError.interactorReleased))
                return
            }
            completion(.success)
        }
    }
    
    /// 执行重试滑动
    private func performRetryScroll(
        scrollView: UIScrollView,
        completion: @escaping (ScrollInteractionResult) -> Void
    ) {
        retryCount += 1
        let currentOffset = scrollView.contentOffset.y
        let maxScrollOffset = max(0, scrollView.contentSize.height - scrollView.frame.height)
        // 检查是否已到达底部
        if currentOffset >= maxScrollOffset - 100 {
            // 根据重试次数决定重置位置
            let targetOffset: CGFloat = retryCount % 2 == 0 ? 0 : maxScrollOffset * 0.3
            scrollView.setContentOffset(CGPoint(x: 0, y: targetOffset), animated: false)
            // 等待一段时间后完成
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                completion(.reachedBottom)
            }
            return
        }
        // 计算重试滑动距离
        let scrollDistance = calculateRetryScrollDistance(
            scrollView: scrollView,
            retryCount: retryCount
        )
        let duration = TimeInterval.random(in: config.durationRange.min...config.durationRange.max)
        scrollView.simulateHumanScroll(distance: scrollDistance, duration: duration) { [weak self] in
            guard let self = self else {
                completion(.failure(ScrollInteractionError.interactorReleased))
                return
            }
            completion(.success)
        }
    }
    
    /// 执行滑动到指定广告
    private func performScrollToAd(
        _ ad: AdElement,
        scrollView: UIScrollView,
        completion: @escaping (ScrollInteractionResult) -> Void
    ) {
        guard let area = ad.area else {
            completion(.failure(ScrollInteractionError.invalidAdArea))
            return
        }
        guard let targetOffset = calculateScrollPositionForAd(ad, scrollView: scrollView) else {
            completion(.failure(ScrollInteractionError.cannotCalculatePosition))
            return
        }
        let currentOffset = scrollView.contentOffset.y
        let scrollDistance = targetOffset - currentOffset
        if abs(scrollDistance) <= 1.0 {
            completion(.success)
            return
        }
        let duration = TimeInterval.random(in: 1.0...1.5)
        scrollView.simulateHumanScroll(distance: scrollDistance, duration: duration) { [weak self] in
            guard let self = self else {
                completion(.failure(ScrollInteractionError.interactorReleased))
                return
            }
            completion(.success)
        }
    }
    
    /// 执行二级页面滑动
    private func performSecondaryPageScroll(
        scrollView: UIScrollView,
        completion: @escaping (ScrollInteractionResult) -> Void
    ) {
        // 二级页面使用较温和的滑动策略
        let maxScrolls = min(3, config.maxSmartScrolls) // 减少滑动次数
        scrollView.simulateSmartBrowsing(maxScrolls: maxScrolls) { [weak self] in
            guard let self = self else {
                completion(.failure(ScrollInteractionError.interactorReleased))
                return
            }
            completion(.success)
        }
    }
    
    /// 执行指定次数的滑动
    private func performScrollWithCount(
        _ count: Int,
        scrollView: UIScrollView,
        completion: @escaping (ScrollInteractionResult) -> Void
    ) {
        guard count > 0 else {
            completion(.success)
            return
        }
        // 执行多次滑动
        performScrollSequence(scrollView: scrollView, remainingCount: count, completion: completion)
    }
    
    /// 执行滑动序列
    private func performScrollSequence(
        scrollView: UIScrollView,
        remainingCount: Int,
        completion: @escaping (ScrollInteractionResult) -> Void
    ) {
        guard remainingCount > 0 else {
            completion(.success)
            return
        }
        // 计算单次滑动距离
        let scrollDistance = calculateSingleScrollDistance(scrollView: scrollView)
        if scrollDistance == 0 {
            completion(.insufficientContent)
            return
        }
        let duration = TimeInterval.random(in: config.durationRange.min...config.durationRange.max)
        scrollView.simulateHumanScroll(distance: scrollDistance, duration: duration) { [weak self] in
            guard let self = self else {
                completion(.failure(ScrollInteractionError.interactorReleased))
                return
            }
            // 滑动间隔
            let pauseTime = TimeInterval.random(in: self.config.pauseRange.min...self.config.pauseRange.max)
            DispatchQueue.main.asyncAfter(deadline: .now() + pauseTime) {
                // 递归执行下一次滑动
                self.performScrollSequence(
                    scrollView: scrollView,
                    remainingCount: remainingCount - 1,
                    completion: completion
                )
            }
        }
    }
    
    /// 执行滑动+功能点击
    private func performScrollAndFunctionClick(
        scrollView: UIScrollView,
        completion: @escaping (ScrollInteractionResult) -> Void
    ) {
        // 先执行单次滑动
        performScrollWithCount(1, scrollView: scrollView) { [weak self] result in
            guard let self = self else {
                completion(.failure(ScrollInteractionError.interactorReleased))
                return
            }
            
            switch result {
            case .success:
                // 滑动完成后，随机停顿一段时间
                let delay = TimeInterval.random(in: self.config.pauseRange.min...self.config.pauseRange.max)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    // 这里只是完成滑动部分，功能点击需要在外部处
                    completion(.success)
                }
                
            default:
                // 滑动失败，直接返回结果
                completion(result)
            }
        }
    }
    
    // MARK: - 计算方法
    
    /// 计算单次滑动距离
    private func calculateSingleScrollDistance(scrollView: UIScrollView) -> CGFloat {
        let maxScrollOffset = max(0, scrollView.contentSize.height - scrollView.frame.height)
        let currentOffset = scrollView.contentOffset.y
        // 如果内容不足以滚动，返回0
        if maxScrollOffset <= 0 {
            return 0
        }
        // 判断是否为短页面
        let isShortPage = scrollView.contentSize.height < scrollView.frame.height * config.shortPageThreshold
        // 计算剩余可滚动距离
        let remainingDistance = maxScrollOffset - currentOffset
        // 根据页面类型决定滑动距离
        let range = isShortPage ? config.shortPageScrollRange : config.scrollDistanceRange
        let randomDistance = CGFloat.random(in: range.min...range.max)
        let distance = min(remainingDistance, randomDistance)
        return distance
    }
    
    /// 计算重试滑动距离
    private func calculateRetryScrollDistance(
        scrollView: UIScrollView,
        retryCount: Int
    ) -> CGFloat {
        let screenHeight = scrollView.frame.height
        let currentOffset = scrollView.contentOffset.y
        let maxScrollOffset = max(0, scrollView.contentSize.height - scrollView.frame.height)
        
        // 根据重试次数调整滑动策略
        let baseDistance = screenHeight * (retryCount % 2 == 0 ? 0.5 : 0.8)
        let randomFactor = CGFloat.random(in: 0.8...1.2)
        let scrollDistance = baseDistance * randomFactor
        
        // 确保不超出可滚动范围
        let actualDistance = min(scrollDistance, maxScrollOffset - currentOffset)
        
        return max(0, actualDistance)
    }
    
    /// 计算需要滚动到的位置，使广告可见
    private func calculateScrollPositionForAd(
        _ ad: AdElement,
        scrollView: UIScrollView
    ) -> CGFloat? {
        guard let area = ad.area else {
            return nil
        }
        
        // 获取当前滚动位置和屏幕高度
        let currentOffset = scrollView.contentOffset.y
        let screenHeight = scrollView.frame.height
        
        // 计算广告在内容中的实际位置
        let adTopPosition: CGFloat
        
        if area.top < 0 {
            // 广告在当前视图上方
            adTopPosition = currentOffset + area.top
        } else {
            // 广告在当前视图下方或可见区域内
            adTopPosition = area.top
        }
        
        // 计算滚动位置，使广告显示在屏幕中部偏上的位置
        let targetOffset = max(0, adTopPosition - (screenHeight / 4))
        return targetOffset
    }
}

// MARK: - 错误定义
/// 滑动交互错误类型
internal enum ScrollInteractionError: Error, LocalizedError {
    case webViewUnavailable
    case interactorReleased
    case invalidAdArea
    case cannotCalculatePosition
    case scrollFailed
    case taskInProgress
    
    var errorDescription: String? {
        switch self {
        case .webViewUnavailable:
            return "WebView不可用"
        case .interactorReleased:
            return "滑动交互器已被释放"
        case .invalidAdArea:
            return "广告区域无效"
        case .cannotCalculatePosition:
            return "无法计算滑动位置"
        case .scrollFailed:
            return "滑动执行失败"
        case .taskInProgress:
            return "滑动任务正在进行中"
        }
    }
}

// MARK: - 扩展方法
internal extension WebViewScrollInteractor {
    
    /// 创建多层WebView的滑动交互器
    /// - Parameter webView: 目标WebView
    /// - Returns: 配置适合多层WebView的滑动交互器
    static func forMultiLayerWebView(_ webView: WKWebView) -> WebViewScrollInteractor {
        return WebViewScrollInteractor(webView: webView, config: .multiLayer)
    }
    
    /// 创建单层WebView的滑动交互器
    /// - Parameter webView: 目标WebView
    /// - Returns: 配置适合单层WebView的滑动交互器
    static func forSingleLayerWebView(_ webView: WKWebView) -> WebViewScrollInteractor {
        return WebViewScrollInteractor(webView: webView, config: .singleLayer)
    }
}
