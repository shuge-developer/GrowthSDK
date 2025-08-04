//
//  GameWrapper.swift
//  GameWrapper
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

// MARK: - SDK 初始化状态
public enum GameWrapperInitStatus {
    case notInitialized
    case initializing
    case initialized
    case failed(Error)
}

// MARK: - SDK 初始化错误
public enum GameWrapperInitError: Error, LocalizedError {
    case coreDataInitFailed(String)
    case taskRepositoryInitFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .coreDataInitFailed(let message):
            return "CoreData 初始化失败: \(message)"
        case .taskRepositoryInitFailed(let message):
            return "任务仓库初始化失败: \(message)"
        }
    }
}

// MARK: - SDK 主类
public class GameWebWrapper: ObservableObject {
    
    public static let shared = GameWebWrapper()
    
    private(set) var config: NetworkConfigurable!
    
    /// SDK 初始化状态
    @Published public private(set) var initStatus: GameWrapperInitStatus = .notInitialized
    
    /// 是否已初始化
    public var isInitialized: Bool {
        if case .initialized = initStatus {
            return true
        }
        return false
    }
    
    /// 初始化完成回调
    private var onInitComplete: ((Result<Void, GameWrapperInitError>) -> Void)?
    
    private init() {}
    
    // MARK: - 公开方法
    
    /// 初始化 SDK
    /// - Parameters:
    ///   - config: 网络配置参数
    ///   - completion: 初始化完成回调
    public func initialize(config: NetworkConfigurable, completion: @escaping (Result<Void, GameWrapperInitError>) -> Void) {
        // 避免重复初始化
        guard case .notInitialized = initStatus else {
            print("[GameWrapper] ⚠️ SDK 已初始化或正在初始化中")
            completion(.success(()))
            return
        }
        
        self.config = config
        initStatus = .initializing
        onInitComplete = completion
        
        print("[GameWrapper] 🚀 开始初始化 SDK")
        print("[GameWrapper] 📊 网络配置: appid=\(config.appid), bundleName=\(config.bundleName), baseUrl=\(config.baseUrl)")
        
        // 执行初始化流程
        performInitialization()
    }
    
    // MARK: - 私有方法
    
    /// 执行初始化流程
    private func performInitialization() {
        let initQueue = DispatchQueue(label: "com.gamewrapper.init", qos: .userInitiated)
        
        initQueue.async { [weak self] in
            guard let self = self else { return }
            
            // 步骤1: 初始化 CoreData
            self.initProgress("初始化 CoreData...")
            self.initializeCoreData { [weak self] result in
                switch result {
                case .success:
                    self?.initProgress("CoreData 初始化成功")
                    
                    // 步骤2: 初始化任务仓库
                    self?.initProgress("初始化任务仓库...")
                    self?.initializeTaskRepository { [weak self] result in
                        switch result {
                        case .success:
                            self?.initProgress("任务仓库初始化成功")
                            
                            // 步骤3: 启动自动刷新管理器（包含配置请求逻辑）
                            self?.initProgress("启动自动刷新管理器...")
                            self?.startRefreshManager { [weak self] result in
                                switch result {
                                case .success:
                                    self?.initProgress("自动刷新管理器启动成功")
                                    
                                    // 初始化完成
                                    DispatchQueue.main.async {
                                        self?.initStatus = .initialized
                                        self?.initProgress("SDK 初始化完成")
                                        self?.onInitComplete?(.success(()))
                                    }
                                    
                                case .failure(let error):
                                    DispatchQueue.main.async {
                                        self?.initStatus = .failed(error)
                                        self?.onInitComplete?(.failure(error))
                                    }
                                }
                            }
                            
                        case .failure(let error):
                            DispatchQueue.main.async {
                                self?.initStatus = .failed(error)
                                self?.onInitComplete?(.failure(error))
                            }
                        }
                    }
                    
                case .failure(let error):
                    DispatchQueue.main.async {
                        self?.initStatus = .failed(error)
                        self?.onInitComplete?(.failure(error))
                    }
                }
            }
        }
    }
    
    /// 初始化 CoreData
    private func initializeCoreData(completion: @escaping (Result<Void, GameWrapperInitError>) -> Void) {
        // CoreData 管理器是懒加载的，访问 container 属性会触发初始化
        let coreDataManager = CoreDataManager.shared
        
        // 检查 CoreData 是否初始化成功
        if coreDataManager.container.persistentStoreDescriptions.isEmpty {
            completion(.failure(.coreDataInitFailed("CoreData 容器初始化失败")))
            return
        }
        
        // 等待 CoreData 存储加载完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion(.success(()))
        }
    }
    
    /// 初始化任务仓库
    private func initializeTaskRepository(completion: @escaping (Result<Void, GameWrapperInitError>) -> Void) {
        // 任务仓库的 loadTasks() 方法会加载所有任务和配置
        TaskRepository.shared.loadTasks()
        
        // 检查任务仓库是否初始化成功
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let repository = TaskRepository.shared
            if repository.isInitialized {
                completion(.success(()))
            } else {
                completion(.failure(.taskRepositoryInitFailed("任务仓库初始化失败")))
            }
        }
    }
    
    /// 启动自动刷新管理器
    private func startRefreshManager(completion: @escaping (Result<Void, GameWrapperInitError>) -> Void) {
        // RefreshManager 在初始化时会自动：
        // 1. 调用 TaskRepository.shared.loadTasks() 加载任务
        // 2. 设置应用生命周期观察者
        // 3. 设置任务队列观察者
        // 4. 创建 ConfigCheckScheduler 来管理配置检查
        let refreshManager = RefreshManager.shared
        
        // 触发初始配置检查
        // 这会根据 TaskPloysManager 的业务逻辑来决定是否请求配置
        refreshManager.triggerAllConfigCheck()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion(.success(()))
        }
    }
    
    /// 更新初始化进度
    private func initProgress(_ message: String) {
        print("[GameWrapper] 📊 \(message)")
    }
}
