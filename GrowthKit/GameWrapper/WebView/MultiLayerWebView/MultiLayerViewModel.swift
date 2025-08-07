//
//  MultiLayerViewModel.swift
//  GrowthKit
//
//  Created by arvin on 2025/6/7.
//

import Foundation
import SwiftUI
import Combine
import WebKit

// MARK: - WebView层级管理器
/// 负责管理多层GameWebView的展示逻辑
///
/// 功能包括：
/// 1. 根据 levelMax 控制最大层级数
/// 2. 根据 levelGapTime 控制层级间隔时间
/// 3. 每层WebView展示60秒后自动销毁
/// 4. 自动从数据库删除已完成的任务
/// 5. 继续调度下一个任务直到队列清空
internal final class MultiLayerViewModel: ObservableObject {
    
    // MARK: - 共享实例
    /// 共享实例，用于在不同视图之间共享状态
    static let shared = MultiLayerViewModel()
    
    // MARK: - 发布属性
    @Published var activeLayers: [WebViewLayer] = []
    @Published var isAllTasksCompleted: Bool = false
    
    // MARK: - 私有属性
    // 存储每个层级的任务处理器
    private var taskHandlers: [String: MultiLayerTaskHandler] = [:]
    private let taskService = TaskService.shared
    private var cancellables = Set<AnyCancellable>()
    private var layerTimers: [String: Timer] = [:]
    private var gapTimer: Timer?
    
    // MARK: - 初始化
    init() {
        setupTaskObserver()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - 公开方法
    
    /// 开始WebView层级展示
    func startLayeredDisplay() {
        guard let initConfig = taskService.initConfig else {
            print("[H5] [MultiLayerVM] ❌ 缺少初始化配置")
            return
        }
        
        guard !taskService.multiLayerTasks.isEmpty else {
            print("[H5] [MultiLayerVM] ⚠️ 任务队列为空")
            isAllTasksCompleted = true
            return
        }
        
        print("[H5] [MultiLayerVM] 🚀 开始多层WebView展示")
        print("[H5] [MultiLayerVM] 📊 配置信息: levelMax=\(initConfig.levelMax)")
        print("[H5] [MultiLayerVM] 📋 待处理任务数: \(taskService.multiLayerTasks.count)")
        
        // 显示任务详情
        for (index, task) in taskService.multiLayerTasks.enumerated() {
            print("[H5] [MultiLayerVM] 任务\(index): 类型：\(task.type) - \(task.name ?? "未知") - \(task.link ?? "无链接")")
        }
        
        scheduleNextLayer()
    }
    
    /// 停止所有WebView展示
    func stopAllDisplays() {
        print("[H5] [MultiLayerVM] 🛑 停止所有WebView展示")
        cleanup()
        activeLayers.removeAll()
        isAllTasksCompleted = false
    }
    
    // MARK: - 私有方法
    
    /// 设置任务观察器
    private func setupTaskObserver() {
        taskService.$multiLayerTasks
            .receive(on: DispatchQueue.main)
            .removeDuplicates { oldTasks, newTasks in
                // 只有当任务数量变化时才触发
                oldTasks.count == newTasks.count
            }
            .sink { [weak self] tasks in
                guard let self = self else { return }
                print("[H5] [MultiLayerVM] 📊 任务队列更新: \(tasks.count) 个任务")
                
                // 清理无效的活跃层级（对应的任务已被删除）
                self.cleanupInvalidLayers(currentTasks: tasks)
                
                // 检查完成状态
                if tasks.isEmpty {
                    self.checkCompletionStatus()
                }
            }
            .store(in: &cancellables)
    }
    
    /// 清理无效的活跃层级
    private func cleanupInvalidLayers(currentTasks: [LinkTask]) {
        // 使用链接来比较，因为id可能为nil
        let currentTaskLinks = Set(currentTasks.compactMap { $0.link })
        let invalidLayers = activeLayers.filter { layer in
            guard let layerTaskLink = layer.task.link else { return true }
            return !currentTaskLinks.contains(layerTaskLink)
        }
        
        if !invalidLayers.isEmpty {
            print("[H5] [MultiLayerVM] 🧹 清理 \(invalidLayers.count) 个无效层级")
            for invalidLayer in invalidLayers {
                if let index = activeLayers.firstIndex(where: { $0.id == invalidLayer.id }) {
                    // 清理对应的定时器
                    layerTimers[invalidLayer.id]?.invalidate()
                    layerTimers.removeValue(forKey: invalidLayer.id)
                    
                    // 从活跃层级中移除
                    _ = withAnimation(.easeOut(duration: 0.3)) {
                        activeLayers.remove(at: index)
                    }
                }
            }
        }
    }
    
    /// 调度下一个层级（仅用于初始启动阶段）
    private func scheduleNextLayer() {
        guard let initConfig = taskService.initConfig else {
            print("[H5] [MultiLayerVM] ❌ 缺少初始化配置，无法调度")
            return
        }
        
        print("[H5] [MultiLayerVM] 🔄 开始初始调度检查 - 当前层级: \(activeLayers.count)/\(initConfig.levelMax)")
        
        // 检查是否达到最大层级数
        if activeLayers.count >= initConfig.levelMax {
            print("[H5] [MultiLayerVM] ⚠️ 已达到最大层级数: \(initConfig.levelMax)")
            return
        }
        
        // 检查是否还有待处理任务
        guard let nextTask = taskService.getNextAvailableMultiLayerTask() else {
            print("[H5] [MultiLayerVM] ⚠️ 没有更多可用任务")
            checkCompletionStatus()
            return
        }
        
        // 如果这是第一层，立即显示；否则按配置间隔时间显示
        if activeLayers.isEmpty {
            print("[H5] [MultiLayerVM] 🚀 立即显示第一层")
            createAndDisplayLayer(for: nextTask)
        } else {
            let delay = TimeInterval(nextTask.levelGapTime)
            print("[H5] [MultiLayerVM] ⏰ \(delay)秒后显示下一层 (当前层级: \(activeLayers.count))")
            gapTimer?.invalidate() // 取消之前的定时器
            gapTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
                self?.createAndDisplayLayer(for: nextTask)
            }
        }
    }
    
    /// 创建并显示层级
    private func createAndDisplayLayer(for task: LinkTask) {
        // 再次检查任务是否仍然有效和可用
        guard let link = task.link, !link.isEmpty else {
            print("[H5] [MultiLayerVM] ❌ 任务链接无效: \(task.taskDescription)")
            taskService.deleteTask(task)
            scheduleNextLayer()
            return
        }
        
        // 检查任务是否已经在显示中（通过链接比较）
        let isAlreadyActive = activeLayers.contains { $0.task.link == task.link }
        if isAlreadyActive {
            print("[H5] [MultiLayerVM] ⚠️ 任务已在显示中，跳过: \(task.taskDescription)")
            return
        }
        
        let layerId = UUID().uuidString
        // 新层级应该在最底层，zIndex 为负数
        // 使用当前已有层级数量+1，确保新层级在最底层
        let currentMaxZIndex = activeLayers.map { $0.zIndex }.min() ?? 0
        let zIndex = currentMaxZIndex - 1
        let layer = WebViewLayer(
            id: layerId,
            task: task,
            url: link,
            zIndex: zIndex
        )
        
        // 获取任务的存活时间用于日志
        let duration: TimeInterval
        switch task.type {
        case .show, .move:
            duration = TimeInterval(task.sleepTime)
        case .fClick, .mFClick:
            duration = TimeInterval(task.clickFuncTime)
        case .aClick, .mAClick:
            duration = TimeInterval(task.clickAdTime)
        }
        
        // 创建任务处理器
        let taskHandler = MultiLayerTaskHandler(task: task) { [weak self] in
            print("[H5] [MultiLayerVM] 🏁 任务处理器完成回调，准备销毁层级: \(layerId)")
            self?.destroyLayer(layerId)
        }
        taskHandlers[layerId] = taskHandler
        
        // 添加到活跃层级列表的开头（底层）
        activeLayers.insert(layer, at: 0)
        // 恢复保存的透明度
        restoreLayerOpacity(for: layer)
        
        print("[H5] [MultiLayerVM] 🎬 开始显示第\(activeLayers.count)层 WebView (zIndex: \(zIndex))")
        print("[H5] [MultiLayerVM] 📋 任务详情: 类型=\(task.type), 🔗 链接: \(link), 存活时间=\(duration)秒")
        
        // 只在初始阶段（未达到最大层级数时）继续调度下一层
        if activeLayers.count < taskService.initConfig?.levelMax ?? 0 {
            print("[H5] [MultiLayerVM] 🔄 层级创建完成，继续调度下一层")
            scheduleNextLayer()
        } else {
            print("[H5] [MultiLayerVM] ✅ 已达到最大层级数，停止初始调度")
        }
    }
    
    /// 销毁指定层级
    private func destroyLayer(_ layerId: String) {
        guard let layerIndex = activeLayers.firstIndex(where: { $0.id == layerId }) else {
            print("[H5] [MultiLayerVM] ⚠️ 未找到要销毁的层级: \(layerId)")
            return
        }
        
        let layer = activeLayers[layerIndex]
        print("[H5] [MultiLayerVM] 🗑️ 开始销毁层级 (zIndex: \(layer.zIndex))")
        print("[H5] [MultiLayerVM] 📋 销毁任务: \(layer.task.taskDescription)")
        
        // 清理任务处理器
        taskHandlers[layerId]?.stop()
        taskHandlers.removeValue(forKey: layerId)
        print("[H5] [MultiLayerVM] 🧹 已清理任务处理器")
        
        // 清理定时器
        layerTimers[layerId]?.invalidate()
        layerTimers.removeValue(forKey: layerId)
        
        // 立即删除数据库任务，标记为已完成
        taskService.deleteTask(layer.task)
        print("[H5] [MultiLayerVM] ✅ 已从数据库删除任务")
        
        // 从活跃层级中移除
        _ = withAnimation(.easeOut(duration: 0.5)) {
            activeLayers.remove(at: layerIndex)
        }
        print("[H5] [MultiLayerVM] 📊 层级销毁完成，当前活跃层级数: \(activeLayers.count)")
        
        // 立即尝试调度新层级来补充空缺
        print("[H5] [MultiLayerVM] 🔄 尝试补充新层级")
        scheduleReplacementLayer()
        
        // 检查是否所有任务都已完成
        checkCompletionStatus()
    }
    
    /// 专门用于补充替换层级的调度方法
    private func scheduleReplacementLayer() {
        guard let initConfig = taskService.initConfig else {
            print("[H5] [MultiLayerVM] ❌ 缺少初始化配置，无法调度")
            return
        }
        
        // 如果当前层级数少于最大层级数，立即尝试补充
        guard activeLayers.count < initConfig.levelMax else {
            print("[H5] [MultiLayerVM] ℹ️ 当前层级已满，无需补充")
            return
        }
        
        // 查找下一个可用任务
        guard let nextTask = taskService.getNextAvailableMultiLayerTask() else {
            print("[H5] [MultiLayerVM] ℹ️ 无可用任务补充，当前层级: \(activeLayers.count)")
            return
        }
        
        // 立即显示新层级，无需等待间隔时间
        print("[H5] [MultiLayerVM] 🔄 立即补充新层级，保持最大层级数")
        createAndDisplayLayer(for: nextTask)
    }
    
    /// 检查完成状态
    private func checkCompletionStatus() {
        if taskService.multiLayerTasks.isEmpty && activeLayers.isEmpty {
            print("[H5] [MultiLayerVM] ✅ 所有任务已完成")
            isAllTasksCompleted = true
        }
    }
    
    /// 清理资源
    private func cleanup() {
        // 清理层级间隔定时器
        gapTimer?.invalidate()
        gapTimer = nil
        
        // 清理所有层级定时器
        layerTimers.values.forEach { $0.invalidate() }
        layerTimers.removeAll()
        
        // 清理所有任务处理器
        taskHandlers.values.forEach { $0.stop() }
        taskHandlers.removeAll()
        
        // 清理订阅
        cancellables.removeAll()
    }
    
}

// MARK: - 任务处理相关方法
internal extension MultiLayerViewModel {
    
    /// 获取指定层级的任务处理器
    func getTaskHandler(for layerId: String) -> MultiLayerTaskHandler? {
        return taskHandlers[layerId]
    }
    
    /// 更新指定层级的透明度
    func updateLayerOpacity(_ opacity: Double, for layerId: String) {
        if let index = activeLayers.firstIndex(where: { $0.id == layerId }) {
            TaskLauncher.shared.setLayerOpacity(opacity, for: layerId)
            withAnimation(.easeInOut(duration: 0.25)) {
                activeLayers[index].opacity = opacity
            }
        }
    }
    
    /// 从启动管理器中恢复层级透明度
    private func restoreLayerOpacity(for layer: WebViewLayer) {
        let opacity = TaskLauncher.shared.getLayerOpacity(layer.id)
        if opacity != layer.opacity {
            updateLayerOpacity(opacity, for: layer.id)
        }
    }
    
}
