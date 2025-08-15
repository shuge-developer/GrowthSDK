//
//  MaxAdCallback.swift
//  SmallGame
//
//  Created by arvin on 2025/6/26.
//

import Foundation
internal import AppLovinSDK

// MARK: -
internal class MaxAdCallback: AdCallback, MAAdRevenueDelegate, MARewardedAdDelegate, MAAdDelegate {
    
    // MARK: - MAAdDelegate
    
    /// 当新广告加载时，SDK 会调用此方法。
    /// - Parameter ad: 已加载的广告。
    func didLoad(_ ad: MAAd) {
        let wrapper = MaxAdWrapper(ad: ad)
        adStateComplete?(.didLoad(.max(wrapper)))
    }
    
    /// 当广告无法获取时，SDK会调用该方法。
    /// <b>常见错误代码：</b><table>
    /// <tr><td>`204`</td><td>`没有可用广告`</td></tr>
    /// <tr><td>`5xx`</td><td>`服务器内部错误`</td></tr>
    /// <tr><td>`负数`</td><td>`内部错误`</td></tr></table>
    /// - Parameters:
    ///   - adUnitIdentifier: SDK 加载广告失败的广告单元 ID。
    ///   - error: 封装失败信息的对象。
    func didFailToLoadAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
        let err = AdError.maxLoadFailed(error)
        adStateComplete?(.loadFailure(err))
    }
    
    /// 全屏广告展示时，SDK会调用该方法。
    /// SDK 在主 UI 线程上调用此方法。
    /// 对于 MREC，此方法已被弃用。 仅当全屏广告时才会调用它。
    /// - Parameter ad: 显示的广告。
    func didDisplay(_ ad: MAAd) {
        let wrapper = MaxAdWrapper(ad: ad)
        adStateComplete?(.didDisplay(.max(wrapper)))
    }
    
    /// 全屏广告隐藏时，SDK会调用该方法。
    /// SDK 在主 UI 线程上调用此方法。
    /// 对于 MREC，此方法已被弃用。 仅当全屏广告时才会调用它。
    /// - Parameter ad: 隐藏的广告。
    func didHide(_ ad: MAAd) {
        let wrapper = MaxAdWrapper(ad: ad)
        adStateComplete?(.didHide(.max(wrapper)))
    }
    
    /// 当广告被点击时，SDK 会调用该方法。
    /// SDK 在主 UI 线程上调用此方法。
    /// - Parameter ad: 被点击的广告。
    func didClick(_ ad: MAAd) {
        let wrapper = MaxAdWrapper(ad: ad)
        adStateComplete?(.didClick(.max(wrapper)))
    }
    
    /// 当广告展示失败时，SDK会调用该方法。
    /// SDK 在主 UI 线程上调用此方法。
    /// - Parameters:
    ///   - ad: 未能展示的广告。
    ///   - error: 封装失败信息的对象。
    func didFail(toDisplay ad: MAAd, withError error: MAError) {
        let err = AdError.maxLoadFailed(error)
        adStateComplete?(.showFailure(err))
    }
    
    // MARK: - MARewardedAdDelegate
    
    /// 当用户应该获得奖励时，SDK会调用此方法。
    /// - Parameters:
    ///   - ad: 奖励广告的广告。
    ///   - reward: 授予用户的奖励。
    func didRewardUser(for ad: MAAd, with reward: MAReward) {
        let wrapper = MaxAdWrapper(ad: ad)
        adStateComplete?(.didReward(.max(wrapper)))
    }
    
    // MARK: - MAAdRevenueDelegate
    
    /// SDK 在检测到广告收入事件时调用此回调。
    /// SDK 在 UI 线程上调用此回调。
    /// - Parameter ad: 检测到收入事件的广告。
    func didPayRevenue(for ad: MAAd) {
        if ad.adFormat == .INTER { // 插屏广告触发
            let wrapper = MaxAdWrapper(ad: ad)
            adStateComplete?(.didReward(.max(wrapper)))
        }
    }
    
}
