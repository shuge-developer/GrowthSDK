//
//  AdThinking.swift
//  SmallGame
//
//  Created by arvin on 2025/6/30.
//

//import Foundation
//import FirebaseAnalytics
//
//// MARK: -
//protocol AdScene {
//    var name: String { get }
//}
//
//extension String: AdScene {
//    var name: String {
//        return self
//    }
//}
//
//// MARK: -
//struct AdThinking {
//    
//    static func ad_firebaseThinking(_ info: AdInfo?) {
//        /// https://firebase.google.com/docs/analytics/measure-ad-revenue?hl=zh-cn
//        /// 如果您使用的是 `AdMob` 平台，请将 `AdMob` 应用关联到 `Firebase` 和 `Analytics`，以实现自动衡量广告收入。
//        /// 每当用户看到广告展示时，`Firebase SDK for Google Analytics` 都会自动记录 `ad_impression` 事件。
//        func params(for info: AdInfo, revenue: Double) -> [String: Any] {
//            let params: [String:Any] = [
//                AnalyticsParameterAdFormat: info.format?.rawValue ?? "",
//                AnalyticsParameterAdSource: info.networkName ?? "",
//                AnalyticsParameterAdPlatform: info.platform ?? "",
//                AnalyticsParameterAdUnitName: info.adId ?? "",
//                AnalyticsParameterCurrency: "USD",
//                AnalyticsParameterValue: revenue
//            ]
//            return params
//        }
//        guard let info else { return }
//        let revenue = info.adWorth / 1000
//        let p1 = params(for: info, revenue: revenue)
//        ThinkListener.frThink(.ad_impression, params: p1)
//        ThinkListener.frThink(.ad_revenue, params: p1)
//        
//        let key: UserDefaults.Key = .totalAdRevenue
//        var total = UserDefaults.double(for: key)
//        total += revenue
//        
//        if total >= 0.01 {
//            let p2 = params(for: info, revenue: total)
//            ThinkListener.frThink(.ad_totalRevenue,
//                                  params: p2)
//            total = 0.0
//        }
//        UserDefaults.set(value: total, key: key)
//    }
//    
//    // MARK: -
//    static func adShow<S>(_ scene: S, info: AdInfo?) where S: AdScene {
//        var params: [GameParams: Any] = [:]
//        params[.adrevenue] = info?.adWorth
//        params[.network] = info?.networkName
//        params[.adtype] = info?.adType
//        params[.adindex] = scene.name
//        params[.adid] = info?.adId
//        
//        ThinkListener.tdThink(.adShow) {
//            params
//        }
//    }
//    
//    static func adClick<S>(_ scene: S, info: AdInfo?) where S: AdScene {
//        var params: [GameParams: Any] = [:]
//        params[.adrevenue] = info?.adWorth
//        params[.network] = info?.networkName
//        params[.adtype] = info?.adType
//        params[.adindex] = scene.name
//        params[.adid] = info?.adId
//        
//        ThinkListener.tdThink(.adClick) {
//            params
//        }
//    }
//    
//    static func adLoadFail(_ style: AdStyle? = nil, error: AdError) {
//        var params: [GameParams: Any] = [:]
//        params[.adtype] = style?.adType()
//        params[.errmsg] = error.errMsg
//        ThinkListener.tdThink(.adFail) {
//            params
//        }
//    }
//    
//    static func adShowFail(_ error: AdError) {
//        ThinkListener.tdThink(.adShowFail) {
//            [.errmsg: error.errMsg]
//        }
//    }
//    
//}
