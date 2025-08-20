//
//  EventName.swift
//  GrowthSDK
//
//  Created by arvin on 2025/8/15.
//

import Foundation

typealias EventName = String
extension EventName {
    static let sdk_ad_impression = "ad_impression"
    static let sdk_ad_totalRevenue = "Total_Ads_Revenue_001"
    static let sdk_ad_revenue = "Ad_Impression_Revenue"
}

extension EventName {
    static let sdk_adShow = "ad_show"
    static let sdk_adClick = "ad_click"
    static let sdk_adShowFail = "ad_show_fail"
    static let sdk_adAllFail = "ad_all_fail"
    static let sdk_adFail = "ad_fail"
}

extension EventName {
    static let sdk_attTime = "tenji_time"
    static let sdk_serTime = "host_time"
}
