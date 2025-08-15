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
internal enum ConfigItem {
    case adjust, adUnit
    
    static func inferFromKey(_ key: String) -> ConfigItem? {
        let lowercasedKey = key.lowercased()
        if lowercasedKey.contains("adjust") || lowercasedKey.contains("verify") {
            return .adjust
        }
        if lowercasedKey.contains("ad") || lowercasedKey.contains("unit") ||
            lowercasedKey.contains("max") || lowercasedKey.contains("kwai") ||
            lowercasedKey.contains("bigo") || lowercasedKey.contains("admob") {
            return .adUnit
        }
        return nil
    }
}

// MARK: -
internal final class ConfigFetcher {
    
    static let shared = ConfigFetcher()
    
    // MARK: -
    private static var keyMapping: [String: ConfigItem] = [:]
    private static var _adjustConfig: AdjustConfig?
    private static var _adUnitConfig: AdUnitConfig?
    
    private let cacheExpiry: TimeInterval = 24 * 60 * 60
    private var lastFetchTime: [String: TimeInterval] = [:]
    private let queue = DispatchQueue(label: "com.growthsdk.config", qos: .utility)
    
    @DataCached<CacheReader, ConfigData>(path: .configs)
    private var cachedData: ConfigData?
    
    // MARK: -
    static var adjustConfig: AdjustConfig? {
        set { _adjustConfig = newValue }
        get { return _adjustConfig }
    }
    
    static var adUnitConfig: AdUnitConfig? {
        set { _adUnitConfig = newValue }
        get { return _adUnitConfig }
    }
    
    private init() {
        loadCachedConfigs()
    }
    
    // MARK: -
    func fetchConfigs(_ keys: [String]) {
        Logger.info("开始获取配置: \(keys)")
        guard !keys.isEmpty else { return }
        // 自动注册配置键映射
        ConfigFetcher.autoRegisterConfig(keys)
        // 开始异步配置请求
        queue.async { [weak self] in
            self?.performFetch(keys)
        }
    }
    
    // MARK: -
    func getConfigModel<T: Codable>(_ key: String) -> T? {
        guard let json = getConfigJson(key) else { return nil }
        let model = T.deserialize(from: json)
        return model
    }
    
    func getConfigJson(_ key: String) -> String? {
        return getCachedData()?.configs[key]
    }
    
    func getCachedData() -> ConfigData? {
        if let data = cachedData, !isExpired(data) {
            return data
        }
        return nil
    }
    
    func getExtendData() -> ConfigResponse.ExtendJson? {
        return getCachedData()?.extendJson
    }
    
    // MARK: -
    private func isExpired(_ data: ConfigData) -> Bool {
        return Date().timeIntervalSince1970 - data.timestamp > cacheExpiry
    }
    
    private func shouldFetch(_ key: String) -> Bool {
        guard let lastTime = lastFetchTime[key] else { return true }
        return Date().timeIntervalSince1970 - lastTime > cacheExpiry
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
                Logger.error("配置数据解析失败: \(json)")
                return
            }
            self.cachedData = ConfigData(from: response)
            CacheWriter.write(cachedData, to: .configs)
            updateStaticConfigs(cachedData!)
            
            let now = Date().timeIntervalSince1970
            keys.forEach { lastFetchTime[$0] = now }
            Logger.info("配置获取成功: \(keys)")
            
        case .failure(let error):
            Logger.error("配置获取失败: \(error)")
        }
    }
    
    // MARK: -
    private static func autoRegisterConfig(_ keys: [String]) {
        for key in keys {
            if keyMapping[key] == nil {
                if let configItem = ConfigItem.inferFromKey(key) {
                    Logger.info("自动注册配置键映射: \(key) -> \(configItem)")
                    keyMapping[key] = configItem
                } else {
                    Logger.warning("无法推断配置键类型: \(key)")
                }
            }
        }
    }
    
    private func updateStaticConfigs(_ configData: ConfigData) {
        for (key, json) in configData.configs {
            guard let configItem = ConfigFetcher.keyMapping[key] else {
                Logger.info("未找到配置键映射: \(key)")
                continue
            }
            switch configItem {
            case .adjust:
                if let adjustConfig = AdjustConfig.deserialize(from: json) {
                    ConfigFetcher.adjustConfig = adjustConfig
                    Logger.info("AdjustConfig 已更新 (key: \(key))")
                }
            case .adUnit:
                if let adUnitConfig = AdUnitConfig.deserialize(from: json) {
                    ConfigFetcher.adUnitConfig = adUnitConfig
                    Logger.info("AdUnitConfig 已更新 (key: \(key))")
                }
            }
        }
    }
    
    private func loadCachedConfigs() {
        guard let data = getCachedData() else { return }
        Logger.info("从缓存加载配置完成")
        updateStaticConfigs(data)
    }
    
}
