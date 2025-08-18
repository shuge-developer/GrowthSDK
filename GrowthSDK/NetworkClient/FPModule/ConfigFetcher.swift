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
            guard let id = bean.id, id.isValid, let content = bean.jsonContent, content.isValid else {
                Logger.info("[ConfigFetcher] 跳过无效的配置项: id=\(bean.id.orEmpty()), content=\(bean.jsonContent.orEmpty())")
                continue
            }
            configDict[id] = content
        }
        self.timestamp = Date().timeIntervalSince1970
        self.extendJson = response.extendJson
        self.configs = configDict
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
    func fetchConfigs(with configKeyItems: [(key: String, item: ConfigItem?)]) {
        Logger.info("开始获取配置(结构化配置键): \(configKeyItems.map { $0.key })")
        ConfigFetcher.registerConfigKeyItems(configKeyItems)
        let keys = configKeyItems.map { $0.key }
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
        return cachedData?.configs[key]
    }
    
    // MARK: - 私有方法
    private func shouldFetch(_ key: String) -> Bool {
        guard let lastTime = lastFetchTime[key] else { return true }
        return Date().timeIntervalSince1970 - lastTime > cacheExpiry
    }
    
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
            if let userId = response.extendJson?.userId {
                ThinkListener.setLoginUser(userId)
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
    private static func registerConfigKeyItems(_ configKeyItems: [(key: String, item: ConfigItem?)]) {
        for configKeyItem in configKeyItems {
            guard !configKeyItem.key.isEmpty else {
                Logger.info("跳过空的配置键")
                continue
            }
            Logger.info("注册配置键: \(configKeyItem.key) -> \(configKeyItem.item)")
            keyMapping[configKeyItem.key] = configKeyItem.item
        }
    }
    
    private func updateStaticConfigs(_ configData: ConfigData) {
        for (key, json) in configData.configs {
            guard !key.isEmpty, !json.isEmpty else {
                Logger.info("跳过空的配置: key=\(key), json=\(json)")
                continue
            }
            guard let configItem = ConfigFetcher.keyMapping[key] else {
                Logger.info("未找到配置键映射: \(key)")
                continue
            }
            switch configItem {
            case .adjust:
                if let adjustConfig = AdjustConfig.deserialize(from: json) {
                    adjustConfig.adChannel = configData.extendJson?.adChannel
                    adjustConfig.userId = configData.extendJson?.userId
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
        guard let data = cachedData else { return }
        Logger.info("从缓存加载配置完成")
        updateStaticConfigs(data)
    }
    
}
