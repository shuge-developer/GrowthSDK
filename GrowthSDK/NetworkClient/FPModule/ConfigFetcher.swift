//
//  ConfigFetcher.swift
//  GrowthSDK
//
//  Created by arvin on 2025/1/18.
//

import Foundation
import Combine

// MARK: - 配置错误
internal enum ConfigError: Error {
    case retryExhausted
    case networkError(Error)
    case timeout
}

// MARK: - 配置状态
internal enum ConfigState {
    case initial
    case loading(attempt: Int)
    case loaded(ConfgConfig)
    case failed(ConfigError)
}

// MARK: - 配置选项
internal struct ConfigOptions {
    let maxRetries: Int
    let retryDelay: TimeInterval
    let timeout: TimeInterval
    
    static let `default` = ConfigOptions(
        maxRetries: 3,
        retryDelay: 2.0,
        timeout: 5.0
    )
}

// MARK: -
internal struct ConfigResponse: Codable {
    let configBeans: [ConfigBean]
    let extendJson: ExtendJson?
    
    struct ConfigBean: Codable {
        let jsonContent: String?
        let id: String?
    }
    
    struct ExtendJson: Codable {
        let adChannel: String?
        let userCountry: String?
        let userId: String?
    }
}

// MARK: -
internal final class ConfigFetcher {
    
    static let shared = ConfigFetcher()
    
    // MARK: -
    private let queue = DispatchQueue(label: "com.growthsdk.config", qos: .utility)
    private var lastFetchTime: [String: TimeInterval] = [:]
    private let cacheExpiry: TimeInterval = 24 * 60 * 60
    
    // MARK: -
    @Published private(set) var configState: ConfigState = .initial
    private static var keyMapping: [String: ConfigItem] = [:]
    private var retryTask: Task<Void, Never>?
    private let options: ConfigOptions
    
    var configStatePublisher: AnyPublisher<ConfigState, Never> {
        $configState.eraseToAnyPublisher()
    }
    
    @DataCached<CacheReader, ConfgConfig>(path: .confg)
    private(set) static var confgConfig: ConfgConfig?
    
    @DataCached<CacheReader, AdjustConfig>(path: .adjust)
    private(set) static var adjustConfig: AdjustConfig?
    
    @DataCached<CacheReader, AdUnitConfig>(path: .adUnit)
    private(set) static var adUnitConfig: AdUnitConfig?
    
    // MARK: -
    private init(options: ConfigOptions = .default) {
        self.options = options
        if let config = ConfigFetcher.confgConfig {
            configState = .loaded(config)
        }
    }
    
    deinit {
        retryTask?.cancel()
    }
    
    // MARK: -
    func fetchConfigs(with configKeyItems: [(key: String, item: ConfigItem?)]) {
        Logger.info("开始获取配置(结构化配置键): \(configKeyItems.map { $0.key })")
        ConfigFetcher.registerConfigKeyItems(configKeyItems)
        // 取消之前的重试任务
        retryTask?.cancel()
        // 开始新的请求（带重试）
        retryTask = Task { [weak self] in
            guard let self = self else { return }
            let keys = configKeyItems.map { $0.key }
            await self.performFetchWithRetry(keys)
        }
    }
    
    // MARK: - 私有方法
    private func shouldFetch(_ key: String) -> Bool {
        guard let lastTime = lastFetchTime[key] else { return true }
        return Date().timeIntervalSince1970 - lastTime > cacheExpiry
    }
    
    internal func performFetchWithRetry(_ keys: [String]) async {
        var attempt = 0
        
        while attempt < options.maxRetries {
            attempt += 1
            configState = .loading(attempt: attempt)
            
            // 过滤需要请求的键（针对 requestOnce：如已有分类缓存则跳过）
            let keysToFetch = keys.filter { key in
                if let item = ConfigFetcher.keyMapping[key], item.requestOnce {
                    let hasCategoryCache: Bool = {
                        switch item {
                        case .config: return ConfigFetcher.confgConfig != nil
                        case .adjust: return ConfigFetcher.adjustConfig != nil
                        case .adUnit: return ConfigFetcher.adUnitConfig != nil
                        }
                    }()
                    if hasCategoryCache {
                        Logger.info("跳过仅请求一次的配置键(已缓存): \(key)")
                        return false
                    }
                }
                return shouldFetch(key)
            }
            
            guard !keysToFetch.isEmpty else { return }
            
            do {
                // 创建网络请求任务
                let fetchTask = Task { () -> String in
                    try await withCheckedThrowingContinuation { continuation in
                        NetworkServer.fetchConfigs(keysToFetch) { result in
                            switch result {
                            case .success(let json):
                                continuation.resume(returning: json)
                            case .failure(let error):
                                let err = ConfigError.networkError(error)
                                continuation.resume(throwing: err)
                            }
                        }
                    }
                }
                
                // 等待任一任务完成
                let json = try await withThrowingTaskGroup(of: String.self) { group in
                    // 网络请求任务
                    group.addTask { try await fetchTask.value }
                    // 超时任务：抛出超时错误以抢占完成
                    group.addTask {
                        try await Task.sleep(nanoseconds: UInt64(self.options.timeout * 1_000_000_000))
                        throw ConfigError.timeout
                    }
                    // 任一完成后，取消其他任务
                    defer { group.cancelAll() }
                    guard let first = try await group.next() else {
                        throw ConfigError.networkError(NSError(domain: "ConfigFetcher", code: -2, userInfo: [NSLocalizedDescriptionKey: "No task result"]))
                    }
                    return first
                }
                
                // 处理响应
                if let response = ConfigResponse.deserialize(from: json) {
                    if let userId = response.extendJson?.userId {
                        ThinkListener.setLoginUser(userId)
                    }
                    self.processResponse(response)
                    
                    let now = Date().timeIntervalSince1970
                    keysToFetch.forEach { lastFetchTime[$0] = now }
                    Logger.info("配置获取成功: \(keysToFetch)")
                    return
                }
                
                throw ConfigError.networkError(NSError(domain: "ConfigFetcher", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"]))
                
            } catch {
                let configError: ConfigError
                if error is ConfigError {
                    configError = error as! ConfigError
                } else {
                    configError = .networkError(error)
                }
                
                if attempt >= options.maxRetries {
                    configState = .failed(configError)
                    return
                }
                
                Logger.warning("配置获取失败(尝试 \(attempt)/\(options.maxRetries)): \(error)")
                try? await Task.sleep(nanoseconds: UInt64(options.retryDelay * 1_000_000_000))
            }
        }
        
        configState = .failed(.retryExhausted)
    }
    
    // MARK: -
    private static func registerConfigKeyItems(_ configKeyItems: [(key: String, item: ConfigItem?)]) {
        for configKeyItem in configKeyItems {
            guard !configKeyItem.key.isEmpty else {
                Logger.info("跳过空的配置键")
                continue
            }
            guard let type = configKeyItem.item else {
                Logger.info("跳过无类型的配置键: \(configKeyItem.key)")
                continue
            }
            Logger.info("注册配置键: \(configKeyItem.key) -> \(type.rawValue)")
            ConfigFetcher.keyMapping[configKeyItem.key] = type
        }
    }
    
    private func processResponse(_ response: ConfigResponse) {
        for bean in response.configBeans {
            guard let key = bean.id, let json = bean.jsonContent else {
                continue
            }
            guard let configItem = ConfigFetcher.keyMapping[key] else {
                Logger.info("未找到配置键映射: \(key)")
                continue
            }
            switch configItem {
            case .config:
                if let confg = ConfgConfig.deserialize(from: json) {
                    CacheWriter.write(confg, to: .confg)
                    ConfigFetcher.confgConfig = confg
                    configState = .loaded(confg)
                    Logger.info("ConfgConfig 已更新 (key: \(key))")
                }
            case .adjust:
                if var adjust = AdjustConfig.deserialize(from: json) {
                    adjust.adChannel = response.extendJson?.adChannel
                    adjust.userId = response.extendJson?.userId
                    CacheWriter.write(adjust, to: .adjust)
                    ConfigFetcher.adjustConfig = adjust
                    Logger.info("AdjustConfig 已更新 (key: \(key))")
                }
            case .adUnit:
                if let adu = AdUnitConfig.deserialize(from: json) {
                    CacheWriter.write(adu, to: .adUnit)
                    ConfigFetcher.adUnitConfig = adu
                    Logger.info("AdUnitConfig 已更新 (key: \(key))")
                }
            }
        }
    }
    
}
