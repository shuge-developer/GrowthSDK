//
//  TaskLauncher.swift
//  GrowthSDK
//
//  Created by Assistant on 2025/6/7.
//

import SwiftUI
import Combine

/// 任务启动器
/// 负责管理WebView的启动时机，确保在配置和任务数据都准备好后才启动
internal final class TaskLauncher: ObservableObject {
    
    internal static let shared = TaskLauncher()
    
    /// 多层WebView容器是否应该显示（层级0）
    @Published var shouldShowMultiLayerWebView: Bool = false
    
    /// 单层广告点击WebView是否应该显示（层级1）
    @Published var shouldShowAdClickWebView: Bool = false
    
    /// 多层WebView透明度
    @Published var multiLayerOpacity: Double = 1.0
    
    /// 单层WebView透明度
    @Published var singleLayerOpacity: Double = 1.0
    
    /// Unity截图透明度
    @Published var screenshotOpacity: Double = 0.5
    
    /// 多层WebView独立层级透明度
    @Published var layerOpacities: [String: Double] = [:]
    
    private var cancellables = Set<AnyCancellable>()
    
    let taskService = TaskService.shared
    
    private init() {
        setupDataObservers()
    }
    
    // MARK: -
    /// 获取指定层级的透明度
    func getLayerOpacity(_ layerId: String) -> Double {
        return layerOpacities[layerId] ?? 1.0
    }
    
    /// 设置指定层级的透明度
    func setLayerOpacity(_ opacity: Double, for layerId: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            layerOpacities[layerId] = opacity
        }
    }
    
    /// 设置数据观察者
    private func setupDataObservers() {
        // 只监听任务和配置
        Publishers.CombineLatest3(
            taskService.$multiLayerTasks,
            taskService.$adClickTasks,
            taskService.$initConfig
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] (multiLayerTasks, adClickTasks, initConfig) in
            self?.handleDataChange(
                multiLayerTasks: multiLayerTasks,
                adClickTasks: adClickTasks,
                initConfig: initConfig
            )
        }
        .store(in: &cancellables)
    }
    
    /// 处理数据变化
    private func handleDataChange(multiLayerTasks: [LinkTask], adClickTasks: [LinkTask], initConfig: InitConfig?) {
        let hasValidMultiLayerTasks = !multiLayerTasks.isEmpty
        let hasValidAdClickTasks = !adClickTasks.isEmpty
        let hasInitConfig = initConfig != nil
        
        // 多层WebView容器显示条件
        let newShouldShowMultiLayer = hasValidMultiLayerTasks && hasInitConfig
        // 单层广告点击WebView显示条件
        let newShouldShowAdClick = hasValidAdClickTasks && hasInitConfig
        
        // 更新多层WebView容器状态
        if newShouldShowMultiLayer != shouldShowMultiLayerWebView {
            shouldShowMultiLayerWebView = newShouldShowMultiLayer
            print("[H5] [TaskLauncher] 🚀 多层WebView显示状态变更: \(newShouldShowMultiLayer)")
            if newShouldShowMultiLayer {
                print("[H5] [TaskLauncher] ✅ 多层WebView条件满足，开始显示")
            }
        }
        // 更新单层广告点击WebView状态
        if newShouldShowAdClick != shouldShowAdClickWebView {
            shouldShowAdClickWebView = newShouldShowAdClick
            print("[H5] [TaskLauncher] 🚀 广告点击WebView显示状态变更: \(newShouldShowAdClick)")
            if newShouldShowAdClick {
                print("[H5] [TaskLauncher] ✅ 广告点击WebView条件满足，可以使用")
            }
        }
        // 如果任一WebView类型满足显示条件，记录状态详情
        if newShouldShowMultiLayer || newShouldShowAdClick {
            // logCurrentStatus()
        }
    }
    
    /// 手动检查是否应该显示WebView
    func checkShouldShowWebViews() {
        handleDataChange(
            multiLayerTasks: taskService.multiLayerTasks,
            adClickTasks: taskService.adClickTasks,
            initConfig: taskService.initConfig
        )
    }
    
    /// 打印当前状态详情
    private func logCurrentStatus() {
        let taskStats = taskService.getTaskStatistics()
        print("[H5] [TaskLauncher] 📈 当前状态详情:")
        print("[H5] [TaskLauncher] - 总任务数: \(taskStats.total)")
        print("[H5] [TaskLauncher] - 有效任务: \(taskStats.valid)")
        print("[H5] [TaskLauncher] - 多层WebView任务: \(taskStats.multiLayer)")
        print("[H5] [TaskLauncher] - 广告点击任务: \(taskStats.adClick)")
        if let initConfig = taskService.initConfig {
            print("[H5] [TaskLauncher] - 最大层级: \(initConfig.levelMax)")
            print("[H5] [TaskLauncher] - 层级间隔: \(initConfig.levelGapTime)秒")
        }
    }
    
    /// 重置状态（用于测试）
    func resetState() {
        shouldShowMultiLayerWebView = false
        shouldShowAdClickWebView = false
        print("[H5] [TaskLauncher] 🔄 状态已重置")
    }
    
    /// 是否应该显示任何WebView
    var shouldShowWebView: Bool {
        return shouldShowMultiLayerWebView || shouldShowAdClickWebView
    }
}
