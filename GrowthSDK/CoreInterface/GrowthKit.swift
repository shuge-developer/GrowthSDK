//
//  GrowthKit.swift
//  GrowthSDK
//
//  Created by arvin on 2025/7/28.
//

import Foundation
import Combine
import UIKit

// MARK: - SDK 状态
@objc public enum InitState: Int {
    case uninitialized  // 未初始化
    case initializing   // 初始化中
    case initialized    // 已初始化
    case failed         // 初始化失败
}

// MARK: - SDK 错误
public enum InitError: Error, LocalizedError {
    case alreadyInitialized
    case storageInitFailed(String)
    case serviceInitFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .alreadyInitialized:
            return "SDK 已经初始化"
        case .storageInitFailed(let message):
            return "CoreData 初始化失败: \(message)"
        case .serviceInitFailed(let message):
            return "任务服务初始化失败: \(message)"
        }
    }
}

// MARK: - SDK 主类
@objc public final class GrowthKit: NSObject {
    
    // MARK: -
    @objc public static let shared = GrowthKit()
    
    @objc public private(set) var state: InitState = .uninitialized {
        didSet { isInitialized = (state == .initialized) }
    }
    
    internal static var logger: GrowthSDKLogging = DefaultLogger.shared
    
    @Published @objc public private(set) var isInitialized: Bool = false
    
    // MARK: -
    private var initializationTask: Task<Void, Error>?
    
    internal var openAdCallbacks: AdCallbacks?
    
    private(set) var config: NetworkConfigurable!
    
    private override init() {
        super.init()
    }
    
    // MARK: - Objective-C 公开方法
    
    /// 初始化 SDK
    /// - Parameters:
    ///   - config: 配置信息
    ///   - completion: 完成回调
    @objc public func initialize(with config: NetworkConfig, launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil, completion: ((Error?) -> Void)? = nil) {
        // 取消之前的初始化任务
        initializationTask?.cancel()
        // 创建新的初始化任务
        initializationTask = Task {
            do {
                try await initialize(with: config, launchOptions: launchOptions)
                await MainActor.run {
                    completion?(nil)
                }
            } catch {
                await MainActor.run {
                    completion?(error)
                }
            }
        }
    }
    
    // MARK: - Swift 公开方法
    
    /// 初始化 SDK
    /// - Parameter config: 配置信息
    public func initialize(with config: NetworkConfigurable, launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) async throws {
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
            // 5. 初始化埋点 SDK
            try await initializeThinking(launchOptions)
            // 5. 初始化广告 SDK
            try await initializeAdSDKs()
            // 6. 完成初始化
            state = .initialized
            Logger.info("SDK 初始化成功")
        } catch {
            state = .failed
            Logger.error("SDK 初始化失败: \(error)")
            throw error
        }
    }
}

// MARK: - 私有方法
private extension GrowthKit {
    
    /// 初始化 CoreData
    func initializeCoreData() async throws {
        Logger.info("开始初始化 CoreData...")
        // 数据存储管理器是懒加载的
        let dataStore = DataStore.shared
        // 检查初始化状态
        guard !dataStore.container.persistentStoreDescriptions.isEmpty else {
            throw InitError.storageInitFailed("CoreData 容器初始化失败")
        }
        // 等待初始化完成（减少延迟时间）
        try await Task.sleep(nanoseconds: 50_000_000)
        Logger.info("CoreData 初始化成功")
    }
    
    /// 初始化任务服务
    func initializeTaskService() async throws {
        Logger.info("开始初始化任务服务...")
        // 加载任务
        TaskService.shared.loadTasks()
        // 等待初始化完成（减少延迟时间）
        try await Task.sleep(nanoseconds: 50_000_000)
        // 检查初始化状态
        guard TaskService.shared.isInitialized else {
            throw InitError.serviceInitFailed("任务服务初始化失败")
        }
        Logger.info("任务服务初始化成功")
    }
    
    /// 初始化网络服务
    func initializeNetworkService() async throws {
        Logger.info("开始初始化网络服务...")
        // 初始化配置同步管理器
        let configSyncManager = ConfigSyncManager.shared
        // 触发初始配置检查
        configSyncManager.triggerAllConfigCheck()
        // 如果提供了配置键，则异步获取配置
        if let configKeys = config.configKeys, !configKeys.isEmpty {
            Task { ConfigFetcher.shared.fetchConfigs(configKeys) }
        }
        Logger.info("网络服务初始化成功")
    }
    
    /// 初始化埋点 SDK
    func initializeThinking(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?) async throws {
        Logger.info("开始初始化埋点SDK...")
        ThinkListener.initialize(launchOptions)
        Logger.info("埋点 SDK初始化成功")
    }
    
    /// 初始化广告SDK
    func initializeAdSDKs() async throws {
        Logger.info("开始初始化广告SDK...")
        await MainActor.run {
            AdLoadProvider.startup()
        }
    }
    
}
