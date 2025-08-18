//
//  GrowthKit+Config.swift
//  GrowthSDK
//
//  Created by arvin on 2025/8/14.
//

import Foundation

// MARK: - 配置键类型枚举
@objc public enum ConfigItem: Int, Codable {
    case config = 0
    case adjust = 1
    case adUnit = 2
    
    internal var requestOnce: Bool {
        switch self {
        case .config, .adjust:
            return true
        default:
            return false
        }
    }
}

// MARK: - 配置键结构
@objc public class ConfigKeyItem: NSObject {
    @objc public let key: String
    @objc public let item: ConfigItem
    
    @objc public init(key: String, item: ConfigItem) {
        self.key = key
        self.item = item
        super.init()
    }
    
    @objc public convenience init(configKey: String) {
        self.init(key: configKey, item: .config)
    }
    
    @objc public convenience init(adjustKey: String) {
        self.init(key: adjustKey, item: .adjust)
    }
    
    @objc public convenience init(adUnitKey: String) {
        self.init(key: adUnitKey, item: .adUnit)
    }
}

// MARK: - 网络配置协议
public protocol NetworkConfigurable {
    var serviceId: String { get }
    var bundleName: String { get }
    var serviceUrl: String { get }
    var serviceKey: String { get }
    var serviceIv: String { get }
    var publicKey: String { get }
    
    var configKeyItems: [ConfigKeyItem]? { get }
    var thirdId: String? { get }
    var instanceId: String? { get }
    var campaign: String? { get }
    var referer: String? { get }
    var adid: String? { get }
}

public extension NetworkConfigurable {
    var configKeyItems: [ConfigKeyItem]? { return nil }
    var thirdId: String? { return nil }
    var instanceId: String? { return nil }
    var campaign: String? { return nil }
    var referer: String? { return nil }
    var adid: String? { return nil }
}

// MARK: -
@objcMembers
public class NetworkConfig: NSObject, NetworkConfigurable {
    public let serviceId: String
    public let bundleName: String
    public let serviceUrl: String
    public let serviceKey: String
    public let serviceIv: String
    public let publicKey: String
    public let configKeyItems: [ConfigKeyItem]?
    public let other: OtherConfig?
    
    public init(serviceId: String, bundleName: String, serviceUrl: String, serviceKey: String, serviceIv: String, publicKey: String, configKeyItems: [ConfigKeyItem]? = nil, other: OtherConfig? = nil) {
        self.serviceId = serviceId
        self.bundleName = bundleName
        self.serviceUrl = serviceUrl
        self.serviceKey = serviceKey
        self.serviceIv = serviceIv
        self.publicKey = publicKey
        self.configKeyItems = configKeyItems
        self.other = other
        super.init()
    }
    
    // MARK: -
    public var thirdId: String? {
        return other?.thirdId
    }
    
    public var instanceId: String? {
        return other?.instanceId
    }
    
    public var campaign: String? {
        return other?.campaign
    }
    
    public var referer: String? {
        return other?.referer
    }
    
    public var adid: String? {
        return other?.adid
    }
}

@objcMembers
public class OtherConfig: NSObject {
    public var thirdId: String?
    public var instanceId: String?
    public var campaign: String?
    public var referer: String?
    public var adid: String?
    
    public init(thirdId: String? = nil, instanceId: String? = nil, campaign: String? = nil, referer: String? = nil, adid: String? = nil) {
        self.thirdId = thirdId
        self.instanceId = instanceId
        self.campaign = campaign
        self.referer = referer
        self.adid = adid
        super.init()
    }
}
