//
//  AdCallback.swift
//  SmallGame
//
//  Created by arvin on 2025/6/26.
//

import Foundation
internal import KwaiAdsSDK
internal import GoogleMobileAds
internal import AppLovinSDK
internal import BigoADS

// MARK: -
internal class AdCallback: NSObject {
    
    typealias AdLoadStateComplete = (AdLoadState) -> Void
    
    public var adStateComplete: AdLoadStateComplete?
    
    // MARK: -
    internal enum AdSource {
        case bigo(BigoAdWrapper?)
        case kwai(KwaiAdWrapper?)
        case admob(AdMobAdWrapper?)
        case max(MaxAdWrapper?)
        
        var description: String {
#if DEBUG
            switch self {
            case .bigo(let wrapper):
                return "[AdSource] [BIGO] \(wrapper?.description ?? "nil")"
            case .kwai(let wrapper):
                return "[AdSource] [KWAI] \(wrapper?.description ?? "nil")"
            case .admob(let wrapper):
                return "[AdSource] [ADMOB] \(wrapper?.platform ?? "nil")"
            case .max(let wrapper):
                return "[AdSource] [MAX] \(wrapper?.description ?? "nil")"
            }
#else
            return ""
#endif
        }
        
        var revenue: Double {
            switch self {
            case .bigo(let wrapper):
                return wrapper?.revenue ?? 0
            case .kwai(let wrapper):
                return wrapper?.revenue ?? 0
            case .max(let wrapper):
                return wrapper?.revenue ?? 0
            case .admob(let wrapper):
                return wrapper?.revenue ?? 0
            }
        }
        
        var adObj: Any? {
            switch self {
            case .bigo(let wrapper):
                return wrapper
            case .kwai(let wrapper):
                return wrapper
            case .admob(let wrapper):
                return wrapper
            case .max(let wrapper):
                return wrapper
            }
        }
        
        var name: String {
            switch self {
            case .bigo(_):
                return "Bigo"
            case .kwai(_):
                return "Kwai"
            case .admob(_):
                return "AdMob"
            case .max(_):
                return "MAX"
            }
        }
        
    }
    
    // MARK: -
    internal enum AdLoadState {
        /// 广告加载完成
        case didLoad(AdSource)
        /// 广告加载失败
        case loadFailure(AdError)
        /// 广告展示失败
        case showFailure(AdError)
        /// 广告展示
        case didDisplay(AdSource)
        /// 获得奖励
        case didReward(AdSource)
        /// 点击广告
        case didClick(AdSource)
        /// 广告关闭
        case didHide(AdSource)
    }
    
}
