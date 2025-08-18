//
//  ThinkListener.swift
//  GrowthSDK
//
//  Created by arvin on 2025/8/15.
//

import Foundation
internal import ThinkingSDK

// MARK: -
internal class ThinkListener {
    
    static func initialize(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        let appId = ConfigFetcher.confgConfig?.thinking?.appId ?? ""
        let sUrl = ConfigFetcher.confgConfig?.thinking?.serverUrl ?? ""
        let config = TDConfig(appId: appId, serverUrl: sUrl)
        config.trackRelaunchedInBackgroundEvents = true
        if let options = launchOptions {
            config.launchOptions = options
        }
        TDAnalytics.start(with: config)
        registerVisitorUser()
        
        let options: TDAutoTrackEventType = [
            .appInstall, .appViewCrash, .appEnd
        ]
        
        TDAnalytics.enableAutoTrack(options)
        TDAnalytics.enableLog(true)
        setSuperProperties()
    }
    
    // MARK: -
    private static func registerVisitorUser() {
        let key: UserDefaults.Key = .userLogin
        if !UserDefaults.bool(for: key) {
            let userId = SecureUtils.string(for: .userId)
            if let userId = userId, !userId.isEmpty {
                setLoginUser(userId)
            }
            UserDefaults.set(value: true, key: key)
            let uuid = SystemIDUtils.uuidString
            TDAnalytics.setDistinctId(uuid)
        }
    }
    
    private static func setSuperProperties() {
        let key: UserDefaults.Key = .baseParam
        if !UserDefaults.bool(for: key) {
            var params: [EventParams: Any] = [:]
            params[.version] = SystemIDUtils.versionString
            params[.build] = SystemIDUtils.buildString
            TDAnalytics.setSuperProperties(params)
            TDAnalytics.userSet(params)
            UserDefaults.set(value: true, key: key)
        }
    }
    
    internal static func setLoginUser(_ userId: String) {
        let cacheId = SecureUtils.string(for: .userId)
        if let cacheId = cacheId, !cacheId.isEmpty {
            return
        }
        SecureUtils.set(string: userId, for: .userId)
        TDAnalytics.login(userId)
    }
    
}

// MARK: -
internal extension ThinkListener {
    
    static func log(_ event: EventName, params: [EventParams: Any]? = nil) {
        TDAnalytics.track(event, properties: params)
    }
    
}
