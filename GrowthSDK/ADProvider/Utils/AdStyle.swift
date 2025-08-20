//
//  AdStyle.swift
//  SmallGame
//
//  Created by arvin on 2025/6/26.
//

import Foundation
internal import AppLovinSDK

// MARK: -
internal enum AdStyle: Codable, CaseIterable, Hashable {
    static var allCases: [AdStyle] {
        return [
            // 激励广告
            .rewarded(.bigo1),
            .rewarded(.bigo2),
            .rewarded(.kwai1),
            .rewarded(.kwai2),
            .rewarded(.max1),
            .rewarded(.max2),
            // 插屏广告
            .inserted(.bigo1),
            .inserted(.bigo2),
            .inserted(.kwai1),
            .inserted(.kwai2),
            .inserted(.max1),
            .inserted(.max2),
            // 开屏
            .appOpen
        ]
    }
    
    internal enum Source: Codable {
        // bigo激励视频
        case bigo1
        case bigo2
        // kwai激励视频
        case kwai1
        case kwai2
        // max激励视频
        case max1
        case max2
        
        var name: String {
            switch self {
            case .bigo1, .bigo2:
                return "BIGO"
            case .kwai1, .kwai2:
                return "KWAI"
            case .max1, .max2:
                return "MAX"
            }
        }
    }
    
    /// 激励广告
    case rewarded(Source)
    /// 插屏广告
    case inserted(Source)
    /// 开屏广告
    case appOpen
    /// 自定义广告 ID
    case custom(id: String, source: Source, format: MAAd.AdFormat)
}

// MARK: -
extension AdStyle {
    
    static func style(by adUnitIdentifier: String) -> AdStyle? {
        return AdStyle.allCases.first {
            $0.adId == adUnitIdentifier
        }
    }
    
    var adId: String {
        switch self {
        case .appOpen:
            return AdIdManager.shared.appOpenAdId()
        case .custom(let id, _, _):
            return id
        default:
            return ""
        }
    }
    
}


// MARK: -
extension AdStyle {
    
    var format: MAAdFormat {
        switch self {
        case .rewarded(_):
            return .rewarded
        case .inserted(_):
            return .interstitial
        case .custom(_, _, let format):
            return format.maFormat
        case .appOpen:
            return .appOpen
        }
    }
    
    var timeout: TimeInterval {
        if case .appOpen = self {
            return 6.0
        } else {
            return 16
        }
    }
    
    /// 是否为激励视频广告
    var isRewarded: Bool {
        switch self {
        case .rewarded(_):
            return true
        case .inserted(_), .appOpen:
            return false
        case .custom(_, _, let format):
            return format == .REWARDED
        }
    }
    
    /// 获取广告源类型
    var sourceType: String {
        switch self {
        case .rewarded(let source), .inserted(let source):
            switch source {
            case .bigo1, .bigo2:
                return "Bigo"
            case .kwai1, .kwai2:
                return "Kwai"
            case .max1, .max2:
                return "MAX"
            }
        case .custom(_, let source, _):
            switch source {
            case .bigo1, .bigo2:
                return "Bigo"
            case .kwai1, .kwai2:
                return "Kwai"
            case .max1, .max2:
                return "MAX"
            }
        case .appOpen:
            return "AdMob"
        }
    }
    
    /// 是否为Bigo广告源
    var isBigoAd: Bool {
        return sourceType == "Bigo"
    }
    
    /// 对应的竞价类型
    var type: BiddingType {
        switch self {
        case .rewarded(_):
            return .rewarded
        case .inserted(_):
            return .interstitial
        case .custom(_, _, let format):
            switch format {
            case .REWARDED:
                return .rewarded
            case .INTER:
                return .interstitial
            default:
                return .rewarded
            }
        case .appOpen:
            return .rewarded
        }
    }
    
}

// MARK: -
extension AdStyle {
    
    func adType(by adObj: Any? = nil) -> Int {
        switch self {
        case .rewarded(let source):
            switch source {
            case .bigo1, .bigo2:
                return 6
            case .kwai1, .kwai2:
                return 5
            case .max1, .max2:
                return 0
            }
        case .inserted(let source):
            switch source {
            case .bigo1, .bigo2:
                return 8
            case .kwai1, .kwai2:
                return 9
            case .max1, .max2:
                return 2
            }
        case .appOpen:
            let maxAd = adObj as? MAAd
            let isAdmob = maxAd?.isAdmobOpen
            if isAdmob == false {
                return 4 // 其它平台开屏广告
            } else {
                return 7 // admob 开屏广告
            }
        case .custom(_, let source, let format):
            switch source {
            case .bigo1, .bigo2:
                switch format {
                case .REWARDED:
                    return 6
                case .INTER:
                    return 8
                default:
                    return -1
                }
            case .kwai1, .kwai2:
                switch format {
                case .REWARDED:
                    return 5
                case .INTER:
                    return 9
                default:
                    return -1
                }
            case .max1, .max2:
                return format.label
            }
        }
    }
    
}
