//
//  Headers.swift
//  GrowthSDK
//
//  Created by arvin on 2025/7/18.
//

import Foundation

// MARK: -
internal protocol HeaderConfigure {
    var appId: String! { get }
    var thirdPartyId: String? { get }
    var deviceId: String? { get }
    var versionName: String { get }
    var packageName: String? { get }
    var osVersion: String? { get }
    var deviceBrand: String { get }
    var deviceModel: String? { get }
    var language: String { get }
    var token: String? { get }
    var uuid: String { get }
    var gaid: String? { get }
    var appInstanceId: String? { get }
    var campaign: String? { get }
    var channel: String? { get }
    var adid: String? { get }
}

// MARK: -
internal extension HeaderConfigure {
    
    var thirdPartyId: String? {
        return nil
    }
    
    var deviceId: String? {
        return SystemIDUtils.idfvString
    }
    
    var versionName: String {
        let infoDict = Bundle.main.infoDictionary
        let vn = infoDict?["CFBundleShortVersionString"]
        return (vn as? String) ?? "0"
    }
    
    var packageName: String? {
        return Bundle.main.bundleIdentifier
    }
    
    var osVersion: String? {
        return Device.current.systemVersion
    }
    
    var deviceBrand: String {
        return "Apple"
    }
    
    var deviceModel: String? {
        return Device.current.description
    }
    
    var language: String {
        return NSLocale.preferredShortLanguage
    }
    
    var token: String? {
        return UUID().uuidString
    }
    
    var uuid: String {
        return SystemIDUtils.uuidString
    }
    
    var gaid: String? {
        return SystemIDUtils.idfaString
    }
    
    var appInstanceId: String? {
        return nil
    }
    
    var campaign: String? {
        return nil
    }
    
    var channel: String? {
        return nil
    }
    
    var adid: String? {
        return nil
    }
    
}

// MARK: -
internal extension HeaderConfigure {
    
    func header() -> String? {
        var header: [String: Any?] = [:]
        header["apd"] = appId
        header["tid"] = thirdPartyId
        header["ifv"] = deviceId
        header["avn"] = versionName
        header["pe"] = packageName
        header["ovn"] = osVersion
        header["pd"] = deviceBrand
        header["pl"] = deviceModel
        header["le"] = language
        header["tk"] = token
        header["uid"] = uuid
        header["ifa"] = gaid
        header["aiid"] = appInstanceId
        header["cmp"] = campaign
        header["qd"] = channel
        header["aid"] = adid
        let json = header.toJsonString()
        return json
    }
    
}
