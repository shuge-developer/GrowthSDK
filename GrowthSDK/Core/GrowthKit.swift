//
//  GrowthKit.swift
//  GrowthSDK
//
//  Created by arvin on 2025/7/28.
//

import Foundation
import Combine

// MARK: - 网络配置协议
public protocol NetworkConfigurable {
    var appid: String { get }
    var bundleName: String { get }
    var baseUrl: String { get }
    var publicKey: String { get }
    var appKey: String { get }
    var appIv: String { get }
}

// MARK: - Objective-C 兼容
@objcMembers
public class NetworkConfig: NSObject, NetworkConfigurable {
    public let appid: String
    public let bundleName: String
    public let baseUrl: String
    public let publicKey: String
    public let appKey: String
    public let appIv: String
    
    public init(appid: String, bundleName: String, baseUrl: String, publicKey: String, appKey: String, appIv: String) {
        self.appid = appid
        self.bundleName = bundleName
        self.baseUrl = baseUrl
        self.publicKey = publicKey
        self.appKey = appKey
        self.appIv = appIv
        super.init()
    }
}

// MARK: - SDK 状态
@objc public enum InitState: Int {
    case uninitialized  // 未初始化
    case initializing   // 初始化中
    case initialized    // 已初始化
    case failed        // 初始化失败
}

// MARK: - SDK 错误
public enum InitError: Error, LocalizedError {
    case notInitialized
    case alreadyInitialized
    case initializationTimeout
    case initializationFailed
    case coreDataInitFailed(String)
    case taskServiceInitFailed(String)
    case networkError(String)
    case invalidConfiguration
    
    public var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "SDK 尚未初始化"
        case .alreadyInitialized:
            return "SDK 已经初始化"
        case .initializationTimeout:
            return "SDK 初始化超时"
        case .initializationFailed:
            return "SDK 初始化失败"
        case .coreDataInitFailed(let message):
            return "CoreData 初始化失败: \(message)"
        case .taskServiceInitFailed(let message):
            return "任务服务初始化失败: \(message)"
        case .networkError(let message):
            return "网络错误: \(message)"
        case .invalidConfiguration:
            return "无效的配置"
        }
    }
}

// MARK: - SDK 主类
@objc public final class GrowthKit: NSObject {
    
    // MARK: - 公开属性
    
    /// 单例
    @objc public static let shared = GrowthKit()
    
    /// 当前状态
    @objc public private(set) var state: InitState = .uninitialized
    
    /// 日志工具
    internal static var logger: GrowthSDKLogging = DefaultLogger.shared
    
    /// 是否已初始化
    @objc public var isInitialized: Bool {
        return state == .initialized
    }
    
    // MARK: - 私有属性
    private var initializationTask: Task<Void, Error>?
    
    private(set) var config: NetworkConfigurable?
    
    private override init() {
        super.init()
    }
    
    // MARK: - Swift 公开方法
    
    /// 初始化 SDK (Swift)
    /// - Parameter config: 配置信息
    public func initialize(with config: NetworkConfigurable) async throws {
        guard state == .uninitialized else {
            throw InitError.alreadyInitialized
        }
        state = .initializing
        do {
            // 1. 保存配置
            self.config = config
            // 2. 初始化 CoreData
            try await initializeCoreData()
            // 3. 初始化任务服务
            try await initializeTaskService()
            // 4. 初始化网络服务
            try await initializeNetworkService()
            // 5. 完成初始化
            state = .initialized
            Logger.info("SDK 初始化成功")
        } catch {
            state = .failed
            Logger.error("SDK 初始化失败: \(error)")
            throw error
        }
    }
    
    // MARK: - Objective-C 公开方法
    
    /// 初始化 SDK (Objective-C)
    /// - Parameters:
    ///   - config: 配置信息
    ///   - completion: 完成回调
    @objc public func initialize(with config: NetworkConfig, completion: @escaping (Error?) -> Void) {
        // 取消之前的初始化任务
        initializationTask?.cancel()
        // 创建新的初始化任务
        initializationTask = Task {
            do {
                try await initialize(with: config)
                await MainActor.run {
                    completion(nil)
                }
            } catch {
                await MainActor.run {
                    completion(error)
                }
            }
        }
    }
}

// MARK: - 私有方法
internal extension GrowthKit {
    
    /// 等待 SDK 初始化完成
    /// - Parameter timeout: 超时时间（秒），默认为 5 秒
    /// - Returns: 是否初始化成功
    func waitForInitialization(timeout: TimeInterval = 5.0) async throws {
        let startTime = Date()
        while !isInitialized {
            // 检查是否超时
            if Date().timeIntervalSince(startTime) > timeout {
                throw InitError.initializationTimeout
            }
            // 如果初始化失败，直接抛出错误
            if state == .failed {
                throw InitError.initializationFailed
            }
            // 等待 50ms 后再次检查
            try await Task.sleep(nanoseconds: 50_000_000)
        }
    }
    
    /// 初始化 CoreData
    private func initializeCoreData() async throws {
        Logger.info("开始初始化 CoreData...")
        // 数据存储管理器是懒加载的
        let dataStore = DataStore.shared
        // 检查初始化状态
        guard !dataStore.container.persistentStoreDescriptions.isEmpty else {
            throw InitError.coreDataInitFailed("CoreData 容器初始化失败")
        }
        // 等待初始化完成（减少延迟时间）
        try await Task.sleep(nanoseconds: 50_000_000)
        Logger.info("CoreData 初始化成功")
    }
    
    /// 初始化任务服务
    private func initializeTaskService() async throws {
        Logger.info("开始初始化任务服务...")
        // 加载任务
        TaskService.shared.loadTasks()
        // 等待初始化完成（减少延迟时间）
        try await Task.sleep(nanoseconds: 50_000_000)
        // 检查初始化状态
        guard TaskService.shared.isInitialized else {
            throw InitError.taskServiceInitFailed("任务服务初始化失败")
        }
        Logger.info("任务服务初始化成功")
    }
    
    /// 初始化网络服务
    private func initializeNetworkService() async throws {
        Logger.info("开始初始化网络服务...")
        // 初始化配置同步管理器
        let configSyncManager = ConfigSyncManager.shared
        // 触发初始配置检查
        configSyncManager.triggerAllConfigCheck()
        // 等待初始化完成（减少延迟时间）
        try await Task.sleep(nanoseconds: 50_000_000)
        Logger.info("网络服务初始化成功")
    }
}
