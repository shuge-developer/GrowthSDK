//
//  AdError.swift
//  SmallGame
//
//  Created by arvin on 2025/6/26.
//

import Foundation
internal import GoogleMobileAds
internal import AppLovinSDK
internal import BigoADS

// MARK: -
internal enum AdError: Error {
    
    case bigoLoadFailed(BigoAdError)
    case bigoShowFailed(BigoAdError)
    case maxLoadFailed(MAError)
    case maxShowFailed(MAError)
    case kwaiLoadFailed(Error)
    case kwaiShowFailed(Error)
    case admobLoadFailed(Error)
    case admobShowFailed(Error)
    case sdkNotInitialized
    case adAlreadyShowing
    case adNotAvailable
    case adConflictDetected
    case timeout
    
    // MARK: -
    var localizedDescription: String {
        switch self {
        case .bigoLoadFailed(let error):
            return "[AdError] [BIGO] 广告加载失败, code: \(error.errorCode), message: \(error.errorMsg)."
        case .bigoShowFailed(let error):
            return "[AdError] [BIGO] 广告展示失败, code: \(error.errorCode), message: \(error.errorMsg)."
        case .maxLoadFailed(let error):
            return "[AdError] [MAX] 广告加载失败, code: \(error.code.rawValue), message: \(error.message)."
        case .maxShowFailed(let error):
            return "[AdError] [MAX] 广告展示失败, code: \(error.code.rawValue), message: \(error.message)."
        case .kwaiLoadFailed(let error):
            return "[AdError] [KWAI] 广告加载失败, code: \(error.code), message: \(error.localizedDescription)."
        case .kwaiShowFailed(let error):
            return "[AdError] [KWAI] 广告展示失败, code: \(error.code), message: \(error.localizedDescription)."
        case .admobLoadFailed(let error):
            return "[AdError] [ADMOB] 广告加载失败, code: \(error.code), message: \(error.localizedDescription)."
        case .admobShowFailed(let error):
            return "[AdError] [ADMOB] 广告展示失败, code: \(error.code), message: \(error.localizedDescription)."
        case .sdkNotInitialized:
            return "[AdError] SDK 未初始化."
        case .adAlreadyShowing:
            return "[AdError] 广告已在展示中."
        case .adNotAvailable:
            return "[AdError] 广告不可用."
        case .adConflictDetected:
            return "[AdError] 检测到广告冲突."
        case .timeout:
            return "[AdError] 广告请求超时."
        }
    }
    
    var errMsg: String {
        switch self {
        case .bigoLoadFailed(let error):
            return "code: \(error.errorCode), message: \(error.errorMsg)."
        case .bigoShowFailed(let error):
            return "code: \(error.errorCode), message: \(error.errorMsg)."
        case .maxLoadFailed(let error):
            return "code: \(error.code.rawValue), message: \(error.message)."
        case .maxShowFailed(let error):
            return "code: \(error.code.rawValue), message: \(error.message)."
        case .kwaiLoadFailed(let error):
            return "code: \(error.code), message: \(error.localizedDescription)."
        case .kwaiShowFailed(let error):
            return "code: \(error.code), message: \(error.localizedDescription)."
        case .admobLoadFailed(let error):
            return "code: \(error.code), message: \(error.localizedDescription)."
        case .admobShowFailed(let error):
            return "code: \(error.code), message: \(error.localizedDescription)."
        case .sdkNotInitialized:
            return "[AdError] SDK 未初始化."
        case .adAlreadyShowing:
            return "[AdError] 广告已在展示中."
        case .adNotAvailable:
            return "[AdError] 广告不可用."
        case .adConflictDetected:
            return "[AdError] 检测到广告冲突."
        case .timeout:
            return "[AdError] 广告请求超时."
        }
    }
    
}
