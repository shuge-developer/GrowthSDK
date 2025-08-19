//
//  ConfigFetcher.swift
//  GrowthSDK
//
//  Created by arvin on 2025/1/18.
//

import Foundation
import Combine

// MARK: -
internal enum ConfigError: Error {
    case retryExhausted
    case networkError(Error)
    case timeout
}

// MARK: -
internal enum ConfigState {
    case initial
    case loading(attempt: Int)
    case loaded(ConfgConfig)
    case failed(ConfigError)
}

// MARK: -
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
    
    internal typealias _ConfigKeyItem = (key: String, item: ConfigItem?)
    @Published private(set) var configState: ConfigState = .initial
    internal var configPublisher: AnyPublisher<ConfigState, Never> {
        $configState.eraseToAnyPublisher()
    }
    
    private var keyMapping: [String: ConfigItem] = [:]
    private let cacheExpiry: TimeInterval = 24 * 60 * 60
    private var retryTask: Task<Void, Never>?
    private let options: ConfigOptions
    
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
    internal func fetchConfigs(with configKeyItems: [_ConfigKeyItem]) {
        Logger.info("开始获取配置(结构化配置键): \(configKeyItems.map { $0.key })")
        registerConfigKeyItems(configKeyItems)
        
        retryTask?.cancel()
        retryTask = Task { [weak self] in
            guard let self = self else { return }
            let keys = configKeyItems.map { $0.key }
            await self.performFetchWithRetry(keys)
        }
    }
    
    internal func performFetchWithRetry(_ keys: [String]) async {
        let keysToFetch = computeKeysToFetch(keys)
        guard !keysToFetch.isEmpty else { return }
        configState = .loading(attempt: 1)
        do {
            let json = try await retry(options.maxRetries, baseDelay: options.retryDelay, timeout: options.timeout) { @Sendable in
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
            guard let response = ConfigResponse.deserialize(from: json) else {
                let userInfo = [NSLocalizedDescriptionKey: "Invalid response format"]
                let err = NSError(domain: "ConfigFetcher", code: -1, userInfo: userInfo)
                throw ConfigError.networkError(err)
            }
            processResponse(response)
            
            let now = Date().timeIntervalSince1970
            keysToFetch.forEach {
                setPersistedLastFetchTime(for: $0, now)
            }
            Logger.info("配置获取成功: \(keysToFetch)")
        } catch {
            let err = ConfigError.networkError(error)
            Logger.warning("配置获取失败(重试结束): \(err)")
            configState = .failed(err)
        }
    }
    
    // MARK: -
    private func computeKeysToFetch(_ keys: [String]) -> [String] {
        let now = Date().timeIntervalSince1970
        return keys.compactMap { key in
            guard let item = keyMapping[key] else {
                return key
            }
            if item.requestOnce {
                let hasCache: Bool = {
                    switch item {
                    case .config: return Self.confgConfig != nil
                    case .adjust: return Self.adjustConfig != nil
                    case .adUnit: return false
                    }
                }()
                return hasCache ? nil : key
            } else {
                if let last = persistedLastFetchTime(for: key) {
                    return (now - last) > cacheExpiry ? key : nil
                } else {
                    if item == .adUnit, Self.adUnitConfig != nil {
                        setPersistedLastFetchTime(for: key, now)
                        return nil
                    }
                    return key
                }
            }
        }
    }
    
    private func persistedLastFetchTime(for key: String) -> TimeInterval? {
        let k = "GrowthSDK.lastFetchTime." + key
        let value = UserDefaults.standard.double(forKey: k)
        return value > 0 ? value : nil
    }
    
    private func setPersistedLastFetchTime(for key: String, _ time: TimeInterval) {
        let k = "GrowthSDK.lastFetchTime." + key
        UserDefaults.standard.set(time, forKey: k)
    }
    
    private func retry<T>(_ maxRetries: Int, baseDelay: TimeInterval, timeout: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        var attempt = 0
        while true {
            attempt += 1
            do {
                return try await withTimeout(seconds: timeout) { try await operation() }
            } catch {
                if attempt >= maxRetries { throw error }
                let jitter = Double.random(in: 0...0.3) * baseDelay
                let delay = (baseDelay * pow(2, Double(attempt - 1)) + jitter)
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
    }
    
    private func withTimeout<T>(seconds: TimeInterval, _ body: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { try await body() }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw ConfigError.timeout
            }
            defer { group.cancelAll() }
            guard let first = try await group.next() else {
                let userInfo = [NSLocalizedDescriptionKey: "No task result"]
                let err = NSError(domain: "ConfigFetcher", code: -2, userInfo: userInfo)
                throw ConfigError.networkError(err)
            }
            return first
        }
    }
    
    // MARK: -
    private func registerConfigKeyItems(_ configKeyItems: [_ConfigKeyItem]) {
        for configKeyItem in configKeyItems {
            guard !configKeyItem.key.isEmpty else { continue }
            guard let item = configKeyItem.item else { continue }
            keyMapping[configKeyItem.key] = item
        }
    }
    
    private func processResponse(_ response: ConfigResponse) {
        for bean in response.configBeans {
            guard let key = bean.id, let json = bean.jsonContent else {
                continue
            }
            guard let configItem = keyMapping[key] else {
                Logger.info("未找到配置键映射: \(key)")
                continue
            }
            switch configItem {
            case .config:
                if let confg = ConfgConfig.deserialize(from: json) {
                    CacheWriter.write(confg, to: .confg)
                    ConfigFetcher.confgConfig = confg
                    configState = .loaded(confg)
                }
            case .adjust:
                if var adjust = AdjustConfig.deserialize(from: json) {
                    adjust.adChannel = response.extendJson?.adChannel
                    adjust.userId = response.extendJson?.userId
                    CacheWriter.write(adjust, to: .adjust)
                    ConfigFetcher.adjustConfig = adjust
                }
            case .adUnit:
                if let adu = AdUnitConfig.deserialize(from: json) {
                    CacheWriter.write(adu, to: .adUnit)
                    ConfigFetcher.adUnitConfig = adu
                }
            }
        }
    }
    
}
