//
//  MultiLayerTaskHandler.swift
//  GrowthSDK
//
//  Created by arvin on 2025/6/7.
//

import Foundation
import WebKit

// MARK: - 任务处理器
internal final class MultiLayerTaskHandler {
    private let task: LinkTask
    private let onComplete: () -> Void
    
    private let taskService = TaskService.shared
    private var coordinator: WebViewCoordinator?
    private var isTaskCompleted = false
    private var taskTimer: Timer?
    private var isStarted = false
    private var pendingScrollTask = false
    
    // 滑动交互器
    private var scrollInteractor: WebViewScrollInteractor?
    // 调试区域更新回调
    var onDebugRectsUpdate: (([CGRect]) -> Void)?
    // 检测到的广告元素
    private var detectedAds: [AdElement] = []
    // 是否已经进行过广告检测上报
    private var hasReportedAds = false
    
    /// 初始化配置
    private var initConfig: InitConfig? {
        return taskService.initConfig
    }
    /// JS 配置
    private var jsConfig: JSConfig? {
        return taskService.jsConfig
    }
    
    // MARK: -
    init(task: LinkTask, onComplete: @escaping () -> Void) {
        self.task = task
        self.onComplete = onComplete
    }
    
    /// 设置 WebView coordinator
    func setCoordinator(_ coordinator: WebViewCoordinator) {
        self.coordinator = coordinator
        
        // 如果已经启动了任务，并且是需要交互的任务类型，则开始执行交互
        if isStarted {
            executeInteractionIfNeeded()
            
            // 对于 .show 和 .fClick 类型，在 WebView 加载完成后延迟 2s 进行广告检测
            if task.type == .show || task.type == .fClick {
                DispatchQueue.mainAsyncAfter(5) {
                    self.performAdDetection()
                }
            }
        }
    }
    
    /// 开始处理任务
    func start() {
        guard !isStarted else {
            return
        }
        isStarted = true
        
        // 根据任务类型获取存活时间
        let duration: TimeInterval
        switch task.type {
        case .show, .move:
            duration = TimeInterval(task.sleepTime)
        case .fClick, .mFClick:
            duration = TimeInterval(task.clickFuncTime)
        case .aClick, .mAClick:
            duration = TimeInterval(task.clickAdTime)
        }
        
        print("[H5] [MultiLayerTaskHandler] 🚀 任务开始计时，📊 任务类型: \(task.type)，⏰ 存活时间: \(duration)秒，🔗 链接: \(task.link ?? "无链接")，📅 开始时间: \(Date())")
        
        // 设置任务完成定时器
        taskTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            print("[H5] [MultiLayerTaskHandler] ⏰ 存活时间(\(duration)秒)到期，任务完成")
            print("[H5] [MultiLayerTaskHandler] 📅 结束时间: \(Date())")
            self?.completeTask()
        }
        
        // 如果已经有 coordinator 并且是需要交互的任务，则开始执行交互
        if coordinator != nil {
            executeInteractionIfNeeded()
        }
    }
    
    /// 执行交互操作（如果需要）
    private func executeInteractionIfNeeded() {
        // 根据任务类型执行不同的处理逻辑
        switch task.type {
        case .show:
            // 纯展示任务，无需额外操作
            break
            
        case .move:
            // 执行滑动任务
            performScrollTask()
            
        case .fClick:
            // 执行功能点击任务
            performFunctionClickTask()
            
        case .mFClick:
            // 执行滑动+功能点击任务
            performScrollAndClickTask()
            
        default:
            print("[H5] [MultiLayerTaskHandler] ⚠️ 不支持的任务类型: \(task.type)")
            break
        }
    }
    
    /// 执行滑动任务
    private func performScrollTask() {
        guard let coordinator = coordinator,
              let webView = coordinator.webView else {
            print("[H5] [MultiLayerTaskHandler] ❌ Coordinator或WebView不可用")
            return
        }
        
        print("[H5] [MultiLayerTaskHandler] 🎯 开始执行滑动任务")
        print("[H5] [MultiLayerTaskHandler] 📊 任务信息: type=\(task.type), startSlideTime=\(task.startSlideTime)")
        print("[H5] [MultiLayerTaskHandler] 📊 WebView信息: frame=\(webView.frame)")
        
        // 创建滑动交互器
        scrollInteractor = WebViewScrollInteractor.forMultiLayerWebView(webView)
        let taskConfig = ScrollTaskConfig(task: task)
        
        print("[H5] [MultiLayerTaskHandler] 🚀 启动滑动交互器，延迟时间: \(taskConfig.startDelay)秒")
        
        pendingScrollTask = true
        scrollInteractor?.performScrollTask(type: .scrollWithCount(1), taskConfig: taskConfig) { [weak self] result in
            self?.pendingScrollTask = false
            switch result {
            case .success:
                print("[H5] [MultiLayerTaskHandler] ✅ 滑动任务完成，开始广告检测")
                // 滑动完成后，进行广告检测上报
                self?.performAdDetection()
                
            case .insufficientContent:
                print("[H5] [MultiLayerTaskHandler] ℹ️ 内容不足以滚动，开始广告检测")
                self?.performAdDetection()
                
            case .failure(let error):
                print("[H5] [MultiLayerTaskHandler] ❌ 滑动任务失败: \(error.localizedDescription)，仍进行广告检测")
                self?.performAdDetection()
                
            case .reachedBottom:
                print("[H5] [MultiLayerTaskHandler] 📍 已到达底部，开始广告检测")
                self?.performAdDetection()
            }
        }
    }
    
    /// 执行功能点击任务
    private func performFunctionClickTask() {
        guard let coordinator = coordinator,
              let webView = coordinator.webView,
              let rectJs = jsConfig?.rectJs else {
            print("[H5] [MultiLayerTaskHandler] ❌ 缺少功能区域检测JS代码")
            completeTask()
            return
        }
        
        print("[H5] [MultiLayerTaskHandler] 功能区域检测JS代码：\(rectJs)")
        
        // 使用 coordinator 的 runJavaScript 方法注入JS检测功能区域
        coordinator.runJavaScript(rectJs) { [weak self] result in
            switch result {
            case .success(let jsResult):
                print("[H5] [MultiLayerTaskHandler] JS执行成功，结果: \(jsResult)")
                
                let jsonString = jsResult as? String
                
                // 将结果转换为JSON字符串
                guard let areas = [FunctionArea].deserialize(from: jsonString) else {
                    print("[H5] [MultiLayerTaskHandler] ❌ 功能区域数据格式错误")
                    self?.completeTask()
                    return
                }
                
                print("[H5] [MultiLayerTaskHandler] ✅ 成功解析功能区域: \(areas.count) 个")
                
                // 筛选有效的功能区域
                let validAreas = areas.filter { $0.rect?.isValid == true }
                
                // 筛选可见区域内的功能区域
                let visibleAreas = validAreas.filter { area in
                    guard let rect = area.rect else { return false }
                    return rect.isVisibleInScreen(in: webView.frame, scrollOffset: webView.scrollView.contentOffset)
                }
                
                // 转换为屏幕坐标系的 CGRect 数组用于调试显示
                let debugRects = visibleAreas.compactMap { area -> CGRect? in
                    guard let rect = area.rect else { return nil }
                    return rect.toScreenRect(in: webView.frame, scrollOffset: webView.scrollView.contentOffset)
                }
                
                // 更新调试区域
                self?.onDebugRectsUpdate?(debugRects)
                
                guard !visibleAreas.isEmpty else {
                    print("[H5] [MultiLayerTaskHandler] ⚠️ 没有可见的功能区域")
                    self?.completeTask()
                    return
                }
                
                // 随机选择一个可见区域
                guard let selectedArea = visibleAreas.randomElement(),
                      let rect = selectedArea.rect,
                      let clickJs = self?.jsConfig?.clickJs,
                      let task = self?.task else {
                    print("[H5] [MultiLayerTaskHandler] ❌ 功能区域数据不完整")
                    self?.completeTask()
                    return
                }
                
                let random = Double.random(in: 0...1)
                print("[H5] [MultiLayerTaskHandler] 生成点击比例随机数：\(random), 当前任务点击比例：\(self?.initConfig?.clickRt)")
                guard random <= self?.initConfig?.clickRt ?? 0.5 else {
                    print("[H5] [MultiLayerTaskHandler] 生成的点击比例随机数 > 当前任务点击比例，不允许功能点击交互")
                    return
                }
                // 获取点击坐标（网页坐标系）
                let clickPoint = rect.center
                
                // 注入点击JS代码（使用 %.2f 作为浮点数格式化占位符）
                let formattedScript = String(format: clickJs, clickPoint.x, clickPoint.y)
                
                let startClick = task.type == .fClick ? task.startClick : 0
                print("[H5] [MultiLayerTaskHandler] 当前是 \"\(task.type.description)\" 任务！")
                print("[H5] [MultiLayerTaskHandler] 📍 点击坐标: (\(clickPoint.x), \(clickPoint.y))")
                if task.type == .fClick { // 功能点击，才需要延迟点击
                    print("[H5] [MultiLayerTaskHandler] 🕒 等待 \(startClick) 秒后执行点击")
                }
                
                // 延迟执行点击
                DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(startClick)) { [weak self] in
                    print("[H5] [MultiLayerTaskHandler] 🔍 点击脚本: \(formattedScript)")
                    // 使用 coordinator 的 runJavaScript 方法执行点击JS
                    coordinator.runJavaScript(formattedScript) { [weak self] result in
                        switch result {
                        case .success(let clickResult):
                            print("[H5] [MultiLayerTaskHandler] 功能点击结果: \(clickResult)")
                            // 点击成功后，清空当前可视化区域
                            self?.clearDebugRects()
                            
                        case .failure(let error):
                            print("[H5] [MultiLayerTaskHandler] ❌ 功能点击失败: \(error)")
                            self?.completeTask()
                        }
                    }
                }
                
            case .failure(let error):
                print("[H5] [MultiLayerTaskHandler] ❌ 功能区域检测失败: \(error)")
                self?.completeTask()
            }
        }
    }
    
    /// 清空调试区域显示
    private func clearDebugRects() {
        print("[H5] [MultiLayerTaskHandler] 🧹 清空可视化区域")
        onDebugRectsUpdate?([])
        print("[H5] [MultiLayerTaskHandler]")
    }
    
    /// 执行滑动+功能点击任务
    private func performScrollAndClickTask() {
        guard let coordinator = coordinator,
              let webView = coordinator.webView else {
            print("[H5] [MultiLayerTaskHandler] ❌ Coordinator或WebView不可用（滑动+点击任务）")
            return
        }
        
        print("[H5] [MultiLayerTaskHandler] 🎯 开始执行滑动+功能点击任务")
        print("[H5] [MultiLayerTaskHandler] 📊 任务信息: type=\(task.type), startSlideTime=\(task.startSlideTime)")
        print("[H5] [MultiLayerTaskHandler] 📊 WebView信息: frame=\(webView.frame)")
        
        // 创建滑动交互器
        scrollInteractor = WebViewScrollInteractor.forMultiLayerWebView(webView)
        let taskConfig = ScrollTaskConfig(task: task)
        
        print("[H5] [MultiLayerTaskHandler] 🚀 启动滑动+功能点击交互器，延迟时间: \(taskConfig.startDelay)秒")
        
        // 设置滑动任务标志
        pendingScrollTask = true
        
        scrollInteractor?.performScrollTask(type: .scrollAndFunctionClick, taskConfig: taskConfig) { [weak self] result in
            // 清除滑动任务标志
            self?.pendingScrollTask = false
            
            switch result {
            case .success:
                print("[H5] [MultiLayerTaskHandler] ✅ 滑动完成，开始广告检测")
                // 滑动完成后先进行广告检测上报，然后执行功能点击
                self?.performAdDetection {
                    self?.performFunctionClickTask()
                }
                
            case .insufficientContent:
                print("[H5] [MultiLayerTaskHandler] ℹ️ 内容不足以滚动，开始广告检测")
                self?.performAdDetection {
                    self?.performFunctionClickTask()
                }
                
            case .failure(let error):
                print("[H5] [MultiLayerTaskHandler] ❌ 滑动失败，仍进行广告检测: \(error.localizedDescription)")
                self?.performAdDetection {
                    self?.performFunctionClickTask()
                }
                
            case .reachedBottom:
                print("[H5] [MultiLayerTaskHandler] 📍 已到达底部，开始广告检测")
                self?.performAdDetection {
                    self?.performFunctionClickTask()
                }
            }
        }
    }
    
    /// 完成任务
    private func completeTask() {
        guard !isTaskCompleted else { return }
        
        // 如果还有未完成的滑动任务，等待完成
        if pendingScrollTask {
            print("[H5] [MultiLayerTaskHandler] ⏳ 等待滑动任务完成...")
            return
        }
        
        isTaskCompleted = true
        print("[H5] [MultiLayerTaskHandler] ✅ 任务完成处理开始")
        
        // 清理资源
        cleanupResources()
        
        // 清空可视化区域
        onDebugRectsUpdate?([])
        
        // 触发完成回调
        print("[H5] [MultiLayerTaskHandler] 📞 触发完成回调，通知 ViewModel 销毁层级")
        onComplete()
    }
    
    /// 清理资源
    private func cleanupResources() {
        print("[H5] [MultiLayerTaskHandler] 🗑️ 清理定时器和资源")
        taskTimer?.invalidate()
        taskTimer = nil
        coordinator = nil
        scrollInteractor = nil
        onDebugRectsUpdate = nil
        detectedAds = []
        hasReportedAds = false
    }
    
    /// 停止任务处理
    func stop() {
        isTaskCompleted = true
        
        // 清理定时器
        taskTimer?.invalidate()
        taskTimer = nil
        
        // 清空可视化区域
        clearDebugRects()
        
        coordinator = nil
    }
    
    // MARK: - 广告检测相关方法
    
    /// 执行广告检测
    /// - Parameter completion: 检测完成后的回调
    private func performAdDetection(completion: (() -> Void)? = nil) {
        // 如果已经进行过广告检测上报，直接返回
        if hasReportedAds {
            print("[H5] [MultiLayerTaskHandler] ℹ️ 已经进行过广告检测上报，跳过")
            completion?()
            return
        }
        
        guard let coordinator = coordinator else {
            print("[H5] [MultiLayerTaskHandler] ⚠️ Coordinator 不可用，跳过广告检测")
            completion?()
            return
        }
        
        print("[H5] [MultiLayerTaskHandler] 🔍 开始检测广告元素")
        print("[H5] [MultiLayerTaskHandler] 📌 当前任务：\(task.taskDescription)")
        
        // 检查是否有广告检测 JS
        guard let adJs = task.adJs, !adJs.isEmpty else {
            print("[H5] [MultiLayerTaskHandler] ⚠️ 任务没有广告检测 JS，跳过广告检测")
            completion?()
            return
        }
        
        // 执行广告检测 JS
        coordinator.runJavaScript(adJs) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let jsonString):
                print("[H5] [MultiLayerTaskHandler] ✅ 广告检测完成")
                self.parseAdDetectionResult(jsonString) {
                    // 标记已经进行过广告检测上报
                    self.hasReportedAds = true
                    completion?()
                }
                
            case .failure(let error):
                print("[H5] [MultiLayerTaskHandler] ❌ 广告检测失败: \(error.localizedDescription)")
                completion?()
            }
        }
    }
    
    /// 解析广告检测结果
    /// - Parameters:
    ///   - result: JS 执行结果
    ///   - completion: 解析完成后的回调
    private func parseAdDetectionResult(_ result: Any, completion: @escaping () -> Void) {
        print("[H5] [MultiLayerTaskHandler] 广告检测结果字符串：\(result)")
        
        guard let jsonString = result as? String else {
            print("[H5] [MultiLayerTaskHandler] ❌ 广告检测结果不是有效的 JSON 字符串")
            completion()
            return
        }
        if let elements = [AdElement].deserialize(from: jsonString) {
            print("[H5] [MultiLayerTaskHandler] ✅ 成功解析广告元素: \(elements.count) 个")
            
            // 保存检测到的广告
            detectedAds = elements
            
            // 上报检测结果
            reportAdDetectionResult(ads: elements)
        } else {
            print("[H5] [MultiLayerTaskHandler] ❌ 解析广告元素失败")
            detectedAds = []
        }
        
        completion()
    }
    
    /// 上报广告检测结果到服务器
    /// - Parameter ads: 检测到的广告元素数组
    private func reportAdDetectionResult(ads: [AdElement]) {
        guard !ads.isEmpty else {
            print("[H5] [MultiLayerTaskHandler] ℹ️ ads 为空，跳过上报")
            return
        }
        
        print("[H5] [MultiLayerTaskHandler] 📊 开始上报广告检测结果到服务器")
        print("[H5] [MultiLayerTaskHandler] 📊 任务类型: \(task.type)")
        print("[H5] [MultiLayerTaskHandler] 📊 检测到广告数量: \(ads.count)")
        print("[H5] [MultiLayerTaskHandler] 📊 任务信息: \(task.taskDescription)")
        
        // 使用 H5UploadParam.loadParams 生成上报参数
        let json = H5UploadParam.loadParams(ads, link: task.link)
        print("[H5] [MultiLayerTaskHandler] 📊 上报参数: \(json ?? "生成失败")")
        
        // 通过 NetworkServer 上报
        NetworkServer.uploadH5Params(json)
        
        print("[H5] [MultiLayerTaskHandler] ✅ 广告检测结果上报完成")
    }
    
}
