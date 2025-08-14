//
//  ConfigFetcher.swift
//  GrowthSDK
//
//  Created by arvin on 2025/1/18.
//

import Foundation

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
internal struct ConfigData: Codable {
    let configs: [String: String]
    let extendJson: ConfigResponse.ExtendJson?
    let timestamp: TimeInterval
    
    init(from response: ConfigResponse) {
        var configDict: [String: String] = [:]
        for bean in response.configBeans {
            if let id = bean.id, let content = bean.jsonContent {
                configDict[id] = content
            }
        }
        self.timestamp = Date().timeIntervalSince1970
        self.extendJson = response.extendJson
        self.configs = configDict
    }
}

// MARK: -
internal final class ConfigFetcher {
    
    static let shared = ConfigFetcher()
    
    private let cacheExpiry: TimeInterval = 24 * 60 * 60
    private var lastFetchTime: [String: TimeInterval] = [:]
    private let queue = DispatchQueue(label: "com.growthsdk.config", qos: .utility)
    
    @DataCached<CacheReader, ConfigData>(path: .configs)
    private var cachedData: ConfigData?
    
    private init() {}
    
    // MARK: -
    /// 获取配置数据
    func getConfig<T: Codable>(for key: String, type: T.Type) -> T? {
        guard let json = getConfigJSON(for: key) else { return nil }
        let model = T.deserialize(from: json)
        return model
    }
    
    /// 获取配置JSON字符串
    func getConfigJSON(for key: String) -> String? {
        return getCachedData()?.configs[key]
    }
    
    /// 获取扩展数据
    func getExtendData() -> ConfigResponse.ExtendJson? {
        return getCachedData()?.extendJson
    }
    
    /// 批量获取配置
    func fetchConfigs(_ keys: [String]) {
        Logger.info("开始获取配置: \(keys)")
        guard !keys.isEmpty else { return }
        queue.async { [weak self] in
            self?.performFetch(keys)
        }
    }
    
    // MARK: -
    private func isExpired(_ data: ConfigData) -> Bool {
        return Date().timeIntervalSince1970 - data.timestamp > cacheExpiry
    }
    
    private func shouldFetch(_ key: String) -> Bool {
        guard let lastTime = lastFetchTime[key] else { return true }
        return Date().timeIntervalSince1970 - lastTime > cacheExpiry
    }
    
    private func getCachedData() -> ConfigData? {
        if let data = cachedData, !isExpired(data) {
            return data
        }
        return nil
    }
    
    // MARK: -
    private func performFetch(_ keys: [String], refresh: Bool = false) {
        let keysToFetch = refresh ? keys : keys.filter { shouldFetch($0) }
        guard !keysToFetch.isEmpty else { return }
        
        NetworkServer.fetchConfigs(keysToFetch) { [weak self] result in
            self?.handleResponse(result, keys: keysToFetch)
        }
    }
    
    private func handleResponse(_ result: Result<String, NetworkError>, keys: [String]) {
        switch result {
        case .success(let json):
            guard let response = ConfigResponse.deserialize(from: json) else {
                Logger.info("配置数据解析失败")
                return
            }
            let configData = ConfigData(from: response)
            CacheWriter.write(configData, to: .configs)
            cachedData = configData
            
            let now = Date().timeIntervalSince1970
            keys.forEach { lastFetchTime[$0] = now }
            Logger.info("配置获取成功: \(keys)")
            
        case .failure(let error):
            Logger.error("配置获取失败: \(error)")
        }
    }
    
}
