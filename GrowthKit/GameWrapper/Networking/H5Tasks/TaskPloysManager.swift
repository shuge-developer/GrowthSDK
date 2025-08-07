//
//  TaskPloysManager.swift
//  GrowthKit
//
//  Created by arvin on 2025/6/4.
//

import Foundation

// MARK: - 请求间隔配置枚举
/// 配置刷新间隔类型，支持关联值设计
internal enum RefreshGapInterval {
    /// 每N日请求一次
    case daily(Int)
    /// 只请求一次
    case once
    
    /// 获取间隔天数
    var days: Int {
        switch self {
        case .daily(let days):
            return days
        case .once:
            return -1
        }
    }
    
    /// 间隔描述
    var description: String {
        switch self {
        case .daily(let days):
            return "每\(days)日"
        case .once:
            return "仅一次"
        }
    }
    
    // MARK: - 便利方法
    static let everyDay = RefreshGapInterval.daily(1)
    static let threeDays = RefreshGapInterval.daily(3)
    static let fiveDays = RefreshGapInterval.daily(5)
    static let weekly = RefreshGapInterval.daily(7)
}

// MARK: - 配置类型枚举
/// H5配置的三种类型，每种类型有不同的请求策略
internal enum ConfigType: String, CaseIterable {
    /// 初始化配置
    case initConfig = "init"
    /// 任务链接配置
    case cfgConfig = "cfg"
    /// JS 代码配置
    case jsConfig = "js"
    
    /// 每种配置类型的默认刷新间隔
    var refreshInterval: RefreshGapInterval {
        switch self {
            // init 配置每日获取一次
        case .initConfig: return .everyDay
            // cfg 配置每日获取一次（有特殊限制）
        case .cfgConfig: return .everyDay
            // js 配置只获取一次
        case .jsConfig: return .once
        }
    }
    
    /// UserDefaults存储键
    var userDefaultsKey: UserDefaults.Key {
        switch self {
        case .initConfig: return .initConfigHistory
        case .cfgConfig: return .cfgConfigHistory
        case .jsConfig: return .jsConfigHistory
        }
    }
    
    /// 配置类型的中文描述
    var displayName: String {
        switch self {
        case .initConfig: return "init 配置"
        case .cfgConfig: return "cfg 配置"
        case .jsConfig: return "js 配置"
        }
    }
}

// MARK: - 请求历史记录
/// 存储每次配置请求的历史记录
internal struct RequestHistory: Codable {
    /// 配置类型
    let type: ConfigType
    /// 请求时间
    let requestTime: Date
    /// 当日第几次请求
    let count: Int
    
    private enum CodingKeys: String, CodingKey {
        case type, requestTime, count
    }
    
    init(type: ConfigType, requestTime: Date, count: Int) {
        self.type = type
        self.requestTime = requestTime
        self.count = count
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let typeString = try container.decode(String.self, forKey: .type)
        guard let configType = ConfigType(rawValue: typeString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .type, in: container,
                debugDescription: "无效的配置类型: \(typeString)"
            )
        }
        self.type = configType
        self.requestTime = try container.decode(Date.self, forKey: .requestTime)
        self.count = try container.decode(Int.self, forKey: .count)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type.rawValue, forKey: .type)
        try container.encode(requestTime, forKey: .requestTime)
        try container.encode(count, forKey: .count)
    }
}

// MARK: - H5配置请求策略管理器
/// 主要负责管理H5配置的请求策略和历史记录
///
/// 业务规则：
/// - init 配置：每日获取一次
/// - js 配置：只获取一次
/// - cfg 配置：复杂逻辑，需满足多个条件
///   1. 任务队列为空
///   2. 每日限制次数未达上限
///   3. 距离上次请求时间间隔满足要求
internal final class TaskPloysManager {
    
    static let shared = TaskPloysManager()
    
    private let historyManager = RequestHistoryManager()
    private let configValidator = ConfigValidator()
    
    private init() {
        print("[H5] [TaskPloysManager] 初始化配置管理器")
    }
    
    // MARK: - 公开接口
    /// 获取需要请求的配置keys
    /// - Returns: 拼接的配置key字符串，如 "init,cfg,js"
    func getRequestKeys() -> String {
        print("[H5] [TaskPloysManager] 开始分析配置请求需求...")
        let availableTypes = ConfigType.allCases.filter {
            let shouldRequest = shouldRequestConfig($0)
            print("[H5] [TaskPloysManager] \($0.displayName)(\($0.rawValue)): \(shouldRequest ? "✅需要请求" : "❌跳过")")
            return shouldRequest
        }
        let keys = availableTypes.map { $0.rawValue }
        let result = keys.joined(separator: ",")
        if !keys.isEmpty {
            print("[H5] [TaskPloysManager] 📤 准备请求配置: [\(keys.joined(separator: ", "))]")
        } else {
            print("[H5] \n")
            print("[H5] [TaskPloysManager] 🚫 当前无需请求任何配置")
        }
        return result
    }
    
    /// 记录请求历史
    /// - Parameter keys: 本次请求的配置keys
    func record(for keys: String) {
        print("[H5] [TaskPloysManager] 📝 开始记录请求历史: \(keys)")
        let requestedTypes = parseRequestedTypes(from: keys)
        guard !requestedTypes.isEmpty else {
            print("[H5] [TaskPloysManager] ⚠️ 无有效的配置类型需要记录")
            return
        }
        historyManager.recordRequest(for: requestedTypes)
        let typeNames = requestedTypes.map { $0.displayName }.joined(separator: ", ")
        print("[H5] [TaskPloysManager] ✅ 已记录请求历史: \(typeNames)")
    }
    
    /// 获取历史记录管理器实例
    /// - Returns: RequestHistoryManager 实例
    func getHistoryManager() -> RequestHistoryManager {
        return historyManager
    }
    
    // MARK: - 私有方法
    /// 判断是否应该请求指定配置
    /// - Parameter type: 配置类型
    /// - Returns: 是否应该请求
    private func shouldRequestConfig(_ type: ConfigType) -> Bool {
        print("[H5] \n")
        print("[H5] [TaskPloysManager] 🔍 检查 \(type.displayName)请求条件...")
        let result: Bool
        switch type {
        case .initConfig:
            result = configValidator.shouldRequestInitConfig()
        case .cfgConfig:
            result = configValidator.shouldRequestCfgConfig()
        case .jsConfig:
            result = configValidator.shouldRequestJSConfig()
        }
        print("[H5] [TaskPloysManager] \(type.displayName)检查结果: \(result ? "✅通过" : "❌拒绝")")
        return result
    }
    
    /// 解析请求的配置类型
    /// - Parameter keys: 配置keys字符串
    /// - Returns: 配置类型数组
    private func parseRequestedTypes(from keys: String) -> [ConfigType] {
        let types = keys.components(separatedBy: ",").compactMap {
            let value = $0.trimmingCharacters(in: .whitespaces)
            return ConfigType(rawValue: value)
        }
        print("[H5] [TaskPloysManager] 解析配置类型: \(keys) -> \(types.map { $0.rawValue })")
        return types
    }
}

// MARK: - 请求历史管理器
/// 专门负责请求历史的存储和查询
internal class RequestHistoryManager {
    
    /// 记录请求历史
    /// - Parameter types: 配置类型数组
    func recordRequest(for types: [ConfigType]) {
        let currentDate = Date()
        print("[H5] [RequestHistoryManager] 📊 记录\(types.count)个配置的请求历史")
        for type in types {
            let todayCount = getTodayRequestCount(for: type)
            let newRecord = RequestHistory(
                type: type,
                requestTime: currentDate,
                count: todayCount + 1
            )
            saveRequestHistory(newRecord)
            print("[H5] [RequestHistoryManager] ✍️ \(type.displayName): 今日第\(newRecord.count)次请求")
        }
    }
    
    /// 获取指定类型的请求历史
    /// - Parameter type: 配置类型
    /// - Returns: 历史记录数组
    func getRequestHistory(for type: ConfigType) -> [RequestHistory] {
        let key: UserDefaults.Key = type.userDefaultsKey
        let histories: [RequestHistory]? = UserDefaults.get(key: key)
        let result = histories ?? []
        print("[H5] [RequestHistoryManager] 📖 \(type.displayName)历史记录: \(result.count)条")
        return result
    }
    
    /// 获取今日请求次数
    /// - Parameter type: 配置类型
    /// - Returns: 今日请求次数
    func getTodayRequestCount(for type: ConfigType) -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.add(value: 1, to: today)
        let history = getRequestHistory(for: type)
        let count = history.filter { record in
            record.requestTime >= today &&
            record.requestTime < tomorrow
        }.count
        print("[H5] [RequestHistoryManager] 📅 \(type.displayName)今日请求次数: \(count)")
        return count
    }
    
    /// 获取最后一次请求时间
    /// - Parameter type: 配置类型
    /// - Returns: 最后请求时间
    func getLastRequestTime(for type: ConfigType) -> Date? {
        let history = getRequestHistory(for: type)
        let lastTime = history.last?.requestTime
        if let time = lastTime {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM-dd HH:mm:ss"
            let date = formatter.string(from: time)
            print("[H5] [RequestHistoryManager] 🕐 \(type.displayName)上次请求: \(date)")
        } else {
            print("[H5] [RequestHistoryManager] 🆕 \(type.displayName)无请求历史")
        }
        return lastTime
    }
    
    /// 保存请求历史记录
    /// - Parameter record: 历史记录
    private func saveRequestHistory(_ record: RequestHistory) {
        var history = getRequestHistory(for: record.type)
        history.append(record)
        // 只保留最近30天的记录，避免数据膨胀
        let thirtyDaysAgo = Calendar.add(value: -30)
        let originalCount = history.count
        history = history.filter {
            $0.requestTime >= thirtyDaysAgo
        }
        if originalCount != history.count {
            print("[H5] [RequestHistoryManager] 🧹 清理 \(record.type.displayName)历史记录: \(originalCount) -> \(history.count)")
        }
        let key: UserDefaults.Key = record.type.userDefaultsKey
        UserDefaults.set(value: history, key: key)
    }
}

// MARK: - 配置验证器
/// 专门负责各种配置的验证逻辑
private class ConfigValidator {
    
    private let historyManager = RequestHistoryManager()
    
    // MARK: -
    /// 检查是否应该请求init 配置
    /// - Returns: 是否应该请求
    func shouldRequestInitConfig() -> Bool {
        let result = shouldRequest(.initConfig)
        print("[H5] [ConfigValidator] init 配置检查完成: \(result ? "✅允许" : "❌拒绝")")
        return result
    }
    
    /// 检查是否应该请求cfg 配置（复杂业务逻辑）
    /// - Returns: 是否应该请求
    func shouldRequestCfgConfig() -> Bool {
        print("[H5] [ConfigValidator] - 步骤1: 检查前置条件")
        guard validateCfgPrerequisites() else {
            print("[H5] [ConfigValidator] cfg 配置检查完成: ❌前置条件不满足")
            return false
        }
        print("[H5] [ConfigValidator] - 步骤2: 检查特殊限制")
        let result = validateCfgSpecialLimits()
        print("[H5] [ConfigValidator] cfg 配置检查完成: \(result ? "✅所有条件满足" : "❌特殊限制不满足")")
        return result
    }
    
    /// 检查是否应该请求js 配置
    /// - Returns: 是否应该请求
    func shouldRequestJSConfig() -> Bool {
        let result = shouldRequest(.jsConfig, interval: .once)
        print("[H5] [ConfigValidator] js 配置检查完成: \(result ? "✅允许" : "❌已请求过")")
        return result
    }
    
    // MARK: -
    /// 验证cfg 配置的前置条件
    /// - Returns: 前置条件是否满足
    private func validateCfgPrerequisites() -> Bool {
        let taskCount = TaskService.shared.webTasks.count
        let isEmpty = taskCount == 0
        print("[H5] [ConfigValidator] 📋 任务队列状态: \(isEmpty ? "空" : "有\(taskCount)个任务")")
        guard isEmpty else {
            print("[H5] [ConfigValidator] ❌ cfg 配置请求被拒绝：任务队列不为空")
            return false
        }
        print("[H5] [ConfigValidator] ✅ 前置条件满足：任务队列为空")
        return true
    }
    
    /// 根据时间间隔判断是否应该请求
    /// - Parameters:
    ///   - type: 配置类型
    ///   - interval: 时间间隔（默认每日）
    /// - Returns: 是否应该请求
    private func shouldRequest(_ type: ConfigType, interval: RefreshGapInterval = .everyDay) -> Bool {
        print("[H5] [ConfigValidator] ⏰ 检查 \(type.displayName)时间间隔(\(interval.description))...")
        // 处理"仅一次"模式
        if case .once = interval {
            let history = historyManager.getRequestHistory(for: type)
            let hasHistory = !history.isEmpty
            print("[H5] [ConfigValidator] 仅一次模式: \(hasHistory ? "已请求过" : "首次请求")")
            return !hasHistory
        }
        // 检查天数间隔
        guard let lastRequest = historyManager.getLastRequestTime(for: type) else {
            print("[H5] [ConfigValidator] ✅ 无历史记录，允许请求")
            return true
        }
        let requiredDays = interval.days
        let daysPassed = naturalDaysPassed(from: lastRequest)
        let canRequest = daysPassed >= requiredDays
        print("[H5] [ConfigValidator] 📆 距离上次请求: \(daysPassed)天，要求间隔: \(requiredDays)天")
        print("[H5] [ConfigValidator] ⏰ 时间间隔检查: \(canRequest ? "✅满足" : "❌不足")")
        return canRequest
    }
    
    /// 计算自然天数间隔（当天0点过后即算新的一天）
    /// - Parameter date: 起始日期
    /// - Returns: 自然天数间隔
    private func naturalDaysPassed(from date: Date) -> Int {
        let calendar = Calendar.current
        let fromDayStart = calendar.startOfDay(for: date)
        let todayStart = calendar.startOfDay(for: Date())
        
        let components = calendar.dateComponents([.day], from: fromDayStart, to: todayStart)
        let daysPassed = components.day ?? 0
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm:ss"
        let fromString = formatter.string(from: date)
        let todayString = formatter.string(from: Date())
        
        print("[H5] [ConfigValidator] 🕐 上次请求时间: \(fromString)")
        print("[H5] [ConfigValidator] 🕐 当前时间: \(todayString)")
        print("[H5] [ConfigValidator] 📅 自然天数计算: \(daysPassed)天")
        return daysPassed
    }
    
    /// 验证cfg 配置的特殊限制
    /// - Returns: 特殊限制是否满足
    private func validateCfgSpecialLimits() -> Bool {
        // 如果没有init 配置，说明是首次启动，允许请求
        guard let initConfig = TaskService.shared.initConfig else {
            print("[H5] [ConfigValidator] 🆕 首次启动，无init 配置限制")
            return true
        }
        print("[H5] [ConfigValidator] 📋 init 配置存在，检查限制条件...")
        print("[H5] [ConfigValidator] - 每日限制: \(initConfig.limit)次")
        print("[H5] [ConfigValidator] - 间隔要求: \(initConfig.refreshGapTime)秒")
        // 1. 检查每日限制次数
        let todayCount = historyManager.getTodayRequestCount(for: .cfgConfig)
        if todayCount >= initConfig.limit {
            print("[H5] [ConfigValidator] ❌ cfg 配置请求被拒绝：今日请求次数已达上限 \(initConfig.limit)")
            return false
        }
        print("[H5] [ConfigValidator] ✅ 次数检查通过: \(todayCount)/\(initConfig.limit)")
        
        // 2. 检查间隔时间（秒级别判断）
        // 从任务完成时间开始计算间隔，而不是上次请求时间
        if let taskCompletionTime = TaskService.shared.getLastTaskCompletionTime() {
            let requiredInterval = TimeInterval(initConfig.refreshGapTime)
            let timeInterval = Date().timeIntervalSince(taskCompletionTime)
            print("[H5] [ConfigValidator] ⏱️ 任务完成后间隔检查: \(Int(timeInterval))秒 vs 要求\(Int(requiredInterval))秒")
            
            // 添加1秒的容差，避免边界条件问题
            let tolerance: TimeInterval = 1.0
            if timeInterval + tolerance < requiredInterval {
                let remainingTime = Int(requiredInterval - timeInterval)
                print("[H5] [ConfigValidator] ❌ cfg 配置请求被拒绝：需要等待 \(remainingTime) 秒")
                return false
            }
            print("[H5] [ConfigValidator] ✅ 任务完成后间隔满足要求")
        } else {
            // 如果没有记录任务完成时间，则仍然使用上次请求时间作为回退
            print("[H5] [ConfigValidator] ⚠️ 无任务完成记录，回退到上次请求时间检查")
            if let lastRequest = historyManager.getLastRequestTime(for: .cfgConfig) {
                let requiredInterval = TimeInterval(initConfig.refreshGapTime)
                let timeInterval = Date().timeIntervalSince(lastRequest)
                print("[H5] [ConfigValidator] ⏱️ 上次请求间隔检查: \(Int(timeInterval))秒 vs 要求\(Int(requiredInterval))秒")
                
                // 添加1秒的容差，避免边界条件问题
                let tolerance: TimeInterval = 1.0
                if timeInterval + tolerance < requiredInterval {
                    let remainingTime = Int(requiredInterval - timeInterval)
                    print("[H5] [ConfigValidator] ❌ cfg 配置请求被拒绝：需要等待 \(remainingTime) 秒")
                    return false
                }
                print("[H5] [ConfigValidator] ✅ 上次请求间隔满足要求")
            } else {
                print("[H5] [ConfigValidator] ✅ 无历史记录，跳过时间间隔检查")
            }
        }
        print("[H5] [ConfigValidator] 🎉 cfg 配置所有限制条件均满足")
        return true
    }
    
}
