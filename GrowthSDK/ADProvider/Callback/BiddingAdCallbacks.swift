//
//  BiddingAdCallbacks.swift
//  SmallGame
//
//  Created by arvin on 2025/6/28.
//

import Foundation

// MARK: -
/// 广告展示结果
internal struct ShowResult {
    let success: Bool
    let usedAd: BiddingResult?
    
    init(success: Bool, usedAd: BiddingResult? = nil) {
        self.success = success
        self.usedAd = usedAd
    }
}

/// 竞价广告生命周期回调
internal struct BiddingAdCallbacks {
    /// 开始加载广告（无缓存时）
    let onStartLoading: (() -> Void)?
    
    /// 加载成功（无缓存时，竞价完成）
    let onLoadSuccess: ((AdCallback.AdSource) -> Void)?
    
    /// 加载失败（无缓存时，全部加载失败）
    let onLoadFailed: ((AdError) -> Void)?
    
    /// 广告展示成功
    let onShowSuccess: ((BiddingResult) -> Void)?
    
    /// 广告展示失败
    let onShowFailed: ((AdError) -> Void)?
    
    /// 获得广告奖励（激励视频专用）
    let onGetReward: ((BiddingResult) -> Void)?
    
    /// 广告点击
    let onAdClick: ((BiddingResult) -> Void)?
    
    /// 广告关闭
    let onClose: ((BiddingResult) -> Void)?
}
