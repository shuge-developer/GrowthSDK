//
//  GameWrapper.swift
//  GameWrapper
//
//  Created by arvin on 2025/7/28.
//

import Foundation

// MARK: -
public class GameWebWrapper {
    
    public static let shared = GameWebWrapper()
    
    private(set) var config: NetworkConfig!
    
    private init() {}
    
    public func setup(network config: NetworkConfig) {
        self.config = config
        if self.config == nil {
            assertionFailure("config cannot be nil！")
        }
    }
    
}

// MARK: -
public struct NetworkConfig {
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
    }
    
}
