//
//  ConfigSyncManager.swift
//  GrowthSDK
//
//  Created by arvin on 2025/6/4.
//

import Foundation
import Combine
import UIKit

// MARK: - 配置检查类型
/// 配置检查的触发来源类型
private enum ConfigCheckType: String {
    /// 应用启动触发的配置检查
    case startup = "应用启动"
    /// 任务队列清空触发的配置检查
    case taskQueueEmpty = "任务队列清空"
}

// MARK: - 拒绝原因类型
/// 配置请求被拒绝的原因类型
private enum RejectionReason: String, Codable {
    /// 未知原因
    case unknown = "unknown"
    /// 需要等待间隔时间
    case waitingForInterval = "waitingForInterval"
    /// 达到每日请求上限
    case dailyLimitReached = "dailyLimitReached"
    /// 其他条件不满足
    case otherConditionsNotMet = "otherConditionsNotMet"
}

// MARK: - 配置同步管理器
/// 负责监听用户状态变化，并在用户状态为变化或任务队列清空时触发配置重新加载
/// 专门针对cfg配置的复杂业务逻辑，包含优雅的重试机制
final class ConfigSyncManager: ObservableObject {
    
    // MARK: - 单例与属性
    static let shared = ConfigSyncManager()
    
    private var cancellables = Set<AnyCancellable>()
    private var retryTimer: Timer?
    
    private var currentCheckType: ConfigCheckType = .startup
    private var hasCompletedInitialCheck: Bool = false
    private var isRetryActive: Bool = false
    
    // MARK: - 配置状态管理
    private let baseRetryInterval: TimeInterval = 60
    private let maxRetryInterval: TimeInterval = 3000
    private let maxRetryCount: Int = 50
    private var retryCount: Int = 0
    
    // MARK: - 配置检查调度器
    private var configCheckScheduler: ConfigCheckScheduler?
    
    // MARK: - 初始化与释放
    private init() {
        print("[AutoRefresh] 🎯 任务队列自动刷新管理器已初始化")
        configCheckScheduler = ConfigCheckScheduler(self)
        setupObservers()
    }
    
    deinit {
        cancelRetryTimer()
        NotificationCenter.default.removeObserver(self)
        print("[AutoRefresh] 🗑️ 资源已释放")
    }
    
    // MARK: - 公开方法
    /// 应用启动时触发所有配置检查
    func triggerAllConfigCheck() {
        configCheckScheduler?.requestConfigCheck(trigger: .appLaunch)
    }
}

// MARK: - 观察者设置
extension ConfigSyncManager {
    
    private func setupObservers() {
        setupAppLifecycleObservers()
        setupTaskQueueObserver()
    }
    
    private func setupAppLifecycleObservers() {
        print("[AutoRefresh] 📱 设置应用生命周期观察者")
        let note: NotificationCenter = NotificationCenter.default
        let name1: NSNotification.Name = UIApplication.willEnterForegroundNotification
        let name2: NSNotification.Name = UIApplication.didEnterBackgroundNotification
        note.addObserver(forName: name1, object: nil, queue: .main) { [weak self] _ in
            self?.appWillEnterForeground()
        }
        note.addObserver(forName: name2, object: nil, queue: .main) { [weak self] _ in
            self?.appDidEnterBackground()
        }
    }
    
    private func setupTaskQueueObserver() {
        print("[AutoRefresh] 📡 设置任务队列观察者")
        TaskService.shared.$webTasks
            .debounce(for: .seconds(1.0), scheduler: DispatchQueue.main)
            .sink { [weak self] webTasks in
                self?.handleTaskQueueChange(webTasks)
            }
            .store(in: &cancellables)
    }
    
}

// MARK: - 应用生命周期事件处理
extension ConfigSyncManager {
    
    @objc private func appWillEnterForeground() {
        print("[AutoRefresh] 📱 应用进入前台")
        configCheckScheduler?.requestConfigCheck(trigger: .foreground)
    }
    
    @objc private func appDidEnterBackground() {
        print("[AutoRefresh] 📱 应用进入后台")
        // 如果有活跃的重试，保存当前状态
        if isRetryActive, let timer = retryTimer {
            persistRetryStateForBackground(timer)
        }
    }
    
    private func persistRetryStateForBackground(_ timer: Timer) {
        let remainingSeconds = timer.fireDate.timeIntervalSince(Date())
        if remainingSeconds > 0 {
            print("[AutoRefresh] 💾 保存当前重试状态，剩余: \(Int(remainingSeconds))秒")
            let resolveTime = Date().timeIntervalSince1970 + remainingSeconds
            UserDefaults.set(value: resolveTime, key: .configResolveTime)
            UserDefaults.set(value: Date().timeIntervalSince1970, key: .configRejectionTime)
            UserDefaults.set(value: RejectionReason.waitingForInterval.rawValue, key: .configRejectionReason)
        }
    }
}

// MARK: - 任务队列变化处理
extension ConfigSyncManager {
    
    private func handleTaskQueueChange(_ webTasks: [LinkTask]) {
        print("[AutoRefresh] 📊 任务队列状态更新: \(webTasks.count)个任务")
        
        if !hasCompletedInitialCheck {
            print("[AutoRefresh] ⏭️ 等待首次启动配置检查完成，忽略任务队列变化")
            return
        }
        
        guard webTasks.isEmpty else {
            print("[AutoRefresh] 📋 任务队列非空，不触发配置检查")
            return
        }
        
        // 记录任务完成时间
        TaskService.shared.recordTaskCompletion()
        print("[AutoRefresh] 🔄 检测到任务队列为空，记录任务完成时间")
        
        print("[AutoRefresh] 🔄 触发配置检查")
        if currentCheckType != .taskQueueEmpty || !isRetryActive {
            cancelRetry()
        }
        configCheckScheduler?.requestConfigCheck(trigger: .taskQueueEmpty)
    }
}

// MARK: - 配置检查核心逻辑
extension ConfigSyncManager {
    
    private func performConfigCheck(type: ConfigCheckType) {
        print("[AutoRefresh] 🔄 开始执行\(type.rawValue)的配置检查")
        
        // 检查是否有持久化的拒绝状态
        if checkPersistedRejectionState() {
            if configCheckScheduler?.isInitialCheckInProgress == true {
                configCheckScheduler?.onConfigCheckFailure()
            }
            return
        }
        
        if getCurrentRejectionReason() == .dailyLimitReached {
            print("[AutoRefresh] 📅 已达到每日请求上限，跳过配置检查")
            if configCheckScheduler?.isInitialCheckInProgress == true {
                configCheckScheduler?.onConfigCheckFailure()
            }
            return
        }
        
        let requestKeys = TaskPloysManager.shared.getRequestKeys()
        if requestKeys.isEmpty {
            handleEmptyRequestKeys(type)
            if configCheckScheduler?.isInitialCheckInProgress == true {
                configCheckScheduler?.onConfigCheckFailure()
            }
            return
        }
        
        print("[AutoRefresh] 📤 满足配置条件，开始网络请求: \(requestKeys)")
        currentCheckType = type
        
        NetworkServer.performConfigRequest(for: requestKeys) { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    print("[AutoRefresh] ✅ 配置刷新成功")
                    self?.handleConfigRefreshSuccess()
                } else {
                    print("[AutoRefresh] ❌ 配置刷新失败，安排重试")
                    self?.handleConfigRefreshFailure()
                }
            }
        }
    }
    
    private func handleEmptyRequestKeys(_ type: ConfigCheckType) {
        print("[AutoRefresh] ⏰ 当前不满足配置请求条件")
        
        guard type == .taskQueueEmpty else { return }
        
        print("[AutoRefresh] 🔄 任务队列为空但条件不满足，分析拒绝原因")
        let result = analyzeRejectionReason()
        
        switch result.reason {
        case .waitingForInterval:
            if let seconds = result.remainingSeconds, seconds > 0 {
                scheduleExactRetry(seconds, reason: "等待间隔时间")
            } else {
                scheduleExactRetry(60, reason: "等待间隔时间(默认)")
            }
            
        case .dailyLimitReached:
            print("[AutoRefresh] 📅 已达到每日请求上限，今天不再重试")
            persistRejectionState(.dailyLimitReached)
            
        case .otherConditionsNotMet, .unknown:
            print("[AutoRefresh] ⚠️ 其他条件不满足，使用标准重试")
            persistRejectionState(result.reason)
            scheduleStandardRetry("配置条件不满足")
        }
    }
    
    private func handleConfigRefreshSuccess() {
        clearRejectionState()
        cancelRetry()
        
        // 通知调度器配置检查成功
        configCheckScheduler?.onConfigCheckSuccess()
    }
    
    private func handleConfigRefreshFailure() {
        scheduleStandardRetry("网络请求失败")
        
        // 通知调度器配置检查失败
        configCheckScheduler?.onConfigCheckFailure()
    }
}

// MARK: - 拒绝原因分析
extension ConfigSyncManager {
    
    private func analyzeRejectionReason() -> (reason: RejectionReason, remainingSeconds: Int?) {
        // 检查是否有 init 配置
        guard let initConfig = TaskService.shared.initConfig else {
            return (.otherConditionsNotMet, nil)
        }
        
        // 检查每日限制
        let historyManager = TaskPloysManager.shared.getHistoryManager()
        let todayCount = historyManager.getTodayRequestCount(for: .cfgConfig)
        if todayCount >= initConfig.limit {
            print("[AutoRefresh] 📊 已达到每日请求上限: \(todayCount)/\(initConfig.limit)")
            return (.dailyLimitReached, nil)
        }
        
        // 检查间隔时间
        if let taskCompletionTime = TaskService.shared.getLastTaskCompletionTime() {
            let requiredInterval = TimeInterval(initConfig.refreshGapTime)
            let timeInterval = Date().timeIntervalSince(taskCompletionTime)
            
            // 添加1秒的容差，避免边界条件问题
            let tolerance: TimeInterval = 1.0
            if timeInterval + tolerance < requiredInterval {
                let remainingTime = Int(requiredInterval - timeInterval)
                print("[AutoRefresh] ⏱️ 间隔时间不足: 还需等待 \(remainingTime) 秒")
                return (.waitingForInterval, remainingTime)
            }
        }
        
        return (.otherConditionsNotMet, nil)
    }
}

// MARK: - 重试调度
extension ConfigSyncManager {
    
    private func scheduleExactRetry(_ seconds: Int, reason: String) {
        guard !isRetryActive else {
            print("[AutoRefresh] ⏳ 重试机制已激活，跳过重复安排")
            return
        }
        
        let adjustedSeconds = adjustRetryTimeForDayBoundary(seconds)
        
        print("[AutoRefresh] ⏱️ 安排精确间隔重试，原因: \(reason)")
        print("[AutoRefresh] - 检查类型: \(currentCheckType.rawValue)")
        print("[AutoRefresh] - 精确等待时间: \(adjustedSeconds)秒")
        
        isRetryActive = true
        persistRejectionState(.waitingForInterval, remainingSeconds: adjustedSeconds)
        
        scheduleTimer(timeInterval: TimeInterval(adjustedSeconds), repeats: false) { [weak self] in
            self?.handleRetryTimerFired()
        }
    }
    
    private func scheduleStandardRetry(_ reason: String) {
        guard retryCount < maxRetryCount else {
            print("[AutoRefresh] ⚠️ 已达到最大重试次数 \(maxRetryCount)，停止重试")
            isRetryActive = false
            return
        }
        
        guard !isRetryActive else {
            print("[AutoRefresh] ⏳ 重试机制已激活，跳过重复安排")
            return
        }
        
        isRetryActive = true
        retryCount += 1
        
        let retryInterval = calculateStandardRetryInterval()
        
        print("[AutoRefresh] ⏱️ 安排重试，原因: \(reason)")
        print("[AutoRefresh] - 检查类型: \(currentCheckType.rawValue)")
        print("[AutoRefresh] - 当前重试次数: \(retryCount)/\(maxRetryCount)")
        print("[AutoRefresh] - 重试间隔: \(Int(retryInterval))秒")
        
        scheduleTimer(timeInterval: retryInterval, repeats: false) { [weak self] in
            self?.handleRetryTimerFired()
        }
    }
    
    private func handleRetryTimerFired() {
        print("[AutoRefresh] ⏰ 重试定时器触发")
        isRetryActive = false
        performConfigCheck(type: currentCheckType)
    }
    
    private func scheduleTimer(timeInterval: TimeInterval, repeats: Bool, completion: @escaping () -> Void) {
        cancelRetryTimer()
        retryTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: repeats) { [weak self] _ in
            guard self != nil else { return }
            completion()
        }
        if let timer = retryTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    private func calculateStandardRetryInterval() -> TimeInterval {
        let linearInterval = baseRetryInterval * Double(retryCount)
        return min(linearInterval, maxRetryInterval)
    }
    
    private func adjustRetryTimeForDayBoundary(_ seconds: Int) -> Int {
        let targetTime = Date().addingTimeInterval(TimeInterval(seconds))
        
        // 检查是否跨天
        if !Calendar.current.isDateInToday(targetTime) {
            print("[AutoRefresh] 📆 检测到重试时间将跨天，重置为明天凌晨")
            // 设置为明天凌晨触发
            let tomorrow = Calendar.current.startOfDay(for: Date()).addingTimeInterval(24*60*60)
            let secondsToTomorrow = Int(tomorrow.timeIntervalSince(Date())) + 5 // 凌晨后5秒触发
            return secondsToTomorrow
        }
        
        return seconds
    }
    
    private func cancelRetry() {
        print("[AutoRefresh] ⏹️ 停止重试机制")
        retryCount = 0
        isRetryActive = false
        cancelRetryTimer()
    }
    
    private func cancelRetryTimer() {
        retryTimer?.invalidate()
        retryTimer = nil
    }
}

// MARK: - 状态持久化
extension ConfigSyncManager {
    
    private func checkPersistedRejectionState() -> Bool {
        let reasonString: String? = UserDefaults.get(key: .configRejectionReason)
        let rejectionTime: Double? = UserDefaults.get(key: .configRejectionTime)
        
        guard let reasonStr = reasonString,
              let reason = RejectionReason(rawValue: reasonStr),
              let rejTime = rejectionTime else {
            print("[AutoRefresh] 🆕 无有效的历史拒绝状态")
            // 确保清除任何残留的状态数据
            clearRejectionState()
            return false
        }
        
        let lastRejectDate = Date(timeIntervalSince1970: rejTime)
        let now = Date()
        
        // 如果拒绝状态太久远，则忽略
        // 特别处理时间跳跃的情况：如果时间差异过大（可能是手动调整时间），也清除状态
        let timeDifference = now.timeIntervalSince(lastRejectDate)
        if timeDifference < 0 || timeDifference > 24*60*60 {
            print("[AutoRefresh] 🕒 历史拒绝状态已过期或时间异常(差异: \(Int(timeDifference))秒)")
            clearRejectionState()
            return false
        }
        
        print("[AutoRefresh] 🔍 检查保存的拒绝状态: \(reasonStr)")
        
        switch reason {
        case .dailyLimitReached:
            return handlePersistedDailyLimit(lastRejectDate)
            
        case .waitingForInterval:
            return handlePersistedWaitingInterval()
            
        case .otherConditionsNotMet, .unknown:
            clearRejectionState()
            return false
        }
    }
    
    private func handlePersistedDailyLimit(_ lastRejectDate: Date) -> Bool {
        let limitDateStr: String? = UserDefaults.get(key: .configDailyLimitDate)
        let today = formatDateString(Date())
        
        print("[AutoRefresh] 📅 检查每日限制状态 - 保存日期: \(limitDateStr ?? "无"), 今日: \(today)")
        
        if let limitDate = limitDateStr, limitDate == today {
            print("[AutoRefresh] 📅 检测到今日已达请求上限，跳过配置检查")
            return true
        } else {
            print("[AutoRefresh] 📆 日期已变更，重置每日限制状态")
            clearRejectionState()
            return false
        }
    }
    
    private func handlePersistedWaitingInterval() -> Bool {
        let resolveTime: Double? = UserDefaults.get(key: .configResolveTime)
        guard let resTime = resolveTime else {
            clearRejectionState()
            return false
        }
        let now = Date().timeIntervalSince1970
        if now < resTime {
            // 间隔时间还没到
            let remainingSeconds = Int(resTime - now)
            print("[AutoRefresh] ⏱️ 恢复间隔等待，剩余: \(remainingSeconds)秒")
            
            // 检查是否跨天
            let resolveDate = Date(timeIntervalSince1970: resTime)
            if !Calendar.current.isDateInToday(resolveDate) {
                print("[AutoRefresh] 📆 检测到重试时间将跨天，重置为当前")
                clearRejectionState()
                return false
            }
            
            scheduleExactRetry(remainingSeconds, reason: "恢复保存的等待间隔")
            return true
        } else {
            print("[AutoRefresh] ⏰ 间隔时间已满足，继续配置检查")
            clearRejectionState()
            return false
        }
    }
    
    private func clearRejectionState() {
        print("[AutoRefresh] 🧹 清除历史拒绝状态")
        let keys: [UserDefaults.Key] = [
            .configRejectionReason, .configDailyLimitDate,
            .configRejectionTime, .configResolveTime
        ]
        keys.forEach {
            UserDefaults.standard.removeObject(
                forKey: $0.rawValue
            )
        }
    }
    
    private func persistRejectionState(_ reason: RejectionReason, remainingSeconds: Int? = nil) {
        print("[AutoRefresh] 💾 保存拒绝状态: \(reason.rawValue)")
        
        UserDefaults.set(value: reason.rawValue, key: .configRejectionReason)
        UserDefaults.set(value: Date().timeIntervalSince1970, key: .configRejectionTime)
        
        if reason == .dailyLimitReached {
            UserDefaults.set(value: formatDateString(Date()), key: .configDailyLimitDate)
            
        } else if reason == .waitingForInterval, let seconds = remainingSeconds {
            let resolveTime = Date().timeIntervalSince1970 + Double(seconds)
            UserDefaults.set(value: resolveTime, key: .configResolveTime)
        }
    }
    
    private func getCurrentRejectionReason() -> RejectionReason? {
        if let reasonString: String = UserDefaults.get(key: .configRejectionReason),
           let reason = RejectionReason(rawValue: reasonString) {
            return reason
        }
        return nil
    }
}

// MARK: - 辅助方法
extension ConfigSyncManager {
    
    private func formatDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - 配置检查调度器
extension ConfigSyncManager {
    
    private class ConfigCheckScheduler {
        private(set) var isInitialCheckInProgress: Bool = false
        private var pendingTriggers: Set<ConfigCheckTrigger> = []
        private weak var configSyncManager: ConfigSyncManager?
        
        enum ConfigCheckTrigger {
            case appLaunch
            case foreground
            case userStateChange
            case taskQueueEmpty
        }
        
        init(_ configSyncManager: ConfigSyncManager) {
            self.configSyncManager = configSyncManager
        }
        
        func requestConfigCheck(trigger: ConfigCheckTrigger) {
            guard let manager = configSyncManager else { return }
            
            print("[AutoRefresh] 📋 配置检查请求: \(trigger)")
            
            // 如果初始检查已完成，只允许特定触发器
            if manager.hasCompletedInitialCheck {
                switch trigger {
                case .taskQueueEmpty:
                    manager.performConfigCheck(type: .taskQueueEmpty)
                case .userStateChange:
                    // 用户状态变化触发的检查需要满足特定条件
                    if shouldTriggerForUserStateChange() {
                        manager.performConfigCheck(type: .startup)
                    }
                default:
                    print("[AutoRefresh] ⏭️ 初始检查已完成，跳过 \(trigger) 触发")
                }
                return
            }
            
            // 初始检查阶段的处理
            if isInitialCheckInProgress {
                print("[AutoRefresh] ⏳ 初始检查进行中，\(trigger) 加入待处理队列")
                pendingTriggers.insert(trigger)
                return
            }
            
            // 开始初始检查
            startInitialCheck()
        }
        
        private func startInitialCheck() {
            guard let manager = configSyncManager else { return }
            
            isInitialCheckInProgress = true
            print("[AutoRefresh] 🚀 开始初始配置检查")
            
            // 确保在继续配置检查前，所有拒绝状态都已清除
            manager.clearRejectionState()
            manager.performConfigCheck(type: .startup)
        }
        
        private func completeInitialCheck() {
            guard let manager = configSyncManager else { return }
            
            isInitialCheckInProgress = false
            manager.hasCompletedInitialCheck = true
            pendingTriggers.removeAll()
            
            print("[AutoRefresh] ✅ 初始配置检查完成")
        }
        
        private func shouldTriggerForUserStateChange() -> Bool {
            // 用户状态变化触发配置检查的条件
            // 这里可以根据具体业务逻辑调整
            return false // 暂时禁用用户状态变化触发
        }
        
        func onConfigCheckSuccess() {
            if isInitialCheckInProgress {
                completeInitialCheck()
            }
        }
        
        func onConfigCheckFailure() {
            // 配置检查失败时的处理
            if isInitialCheckInProgress {
                // 初始检查失败，但仍标记为完成，避免重复触发
                completeInitialCheck()
            }
        }
    }
}
