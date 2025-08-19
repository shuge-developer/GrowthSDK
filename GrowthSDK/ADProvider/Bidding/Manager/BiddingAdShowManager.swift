//
//  BiddingAdShowManager.swift
//  SmallGame
//
//  Created by arvin on 2025/6/28.
//

import Foundation
import UIKit

// MARK: - 广告展示管理器
@MainActor
internal class BiddingAdShowManager {
    private weak var parent: AdBiddingManager?
    
    init(parent: AdBiddingManager) {
        self.parent = parent
    }
    
    /// 执行广告展示
    func performShow(session: BiddingSession, adCallbacks: BiddingAdCallbacks?, usedAdStyle: AdStyle? = nil) async -> ShowResult {
        guard session.winnerResult != nil else {
            parent?.logInfo("❌ 没有获胜广告可展示")
            adCallbacks?.onShowFailed?(AdError.adNotAvailable)
            return ShowResult(success: false)
        }
        
        let sortedResults = await parent?.getValidResultsSorted(from: session) ?? []
        
        for (index, result) in sortedResults.enumerated() {
            parent?.logInfo("🎬 尝试展示广告 (\(index + 1)/\(sortedResults.count)): \(result.description)")
            
            if await attemptShowAd(result: result, adCallbacks: adCallbacks) {
                parent?.logInfo("✅ 广告调用展示接口成功")
                parent?.cleanupUsedAdLoader(adStyle: result.adStyle)
                return ShowResult(success: true, usedAd: result)
            } else {
                // 如果广告展示失败，标记为无效并从缓存中移除
                parent?.logInfo("❌ 广告展示失败，从缓存中移除: \(result.description)")
                markAdAsInvalidAndRemove(result: result)
            }
        }
        
        parent?.logInfo("💥 所有广告展示失败")
        adCallbacks?.onShowFailed?(AdError.adNotAvailable)
        return ShowResult(success: false)
    }
    
    /// 标记广告为无效并从缓存中移除
    private func markAdAsInvalidAndRemove(result: BiddingResult) {
        parent?.removeFailedAd(result: result)
    }
    
    /// 尝试展示单个广告
    private func attemptShowAd(result: BiddingResult, adCallbacks: BiddingAdCallbacks?) async -> Bool {
        guard let loader = parent?.getLoader(for: result.adStyle), loader.isLoaded, loader.isAdValid() else {
            return false
        }
        parent?.setupLoaderCallbacks(loader: loader, result: result, adCallbacks: adCallbacks)
        return await withCheckedContinuation { continuation in
            guard let rootVC = AdWindowManager.shared.beginPresentation() else {
                parent?.logInfo("❌ 已存在正在展示的广告，拒绝并发展示请求")
                adCallbacks?.onShowFailed?(AdError.adAlreadyShowing)
                continuation.resume(returning: false)
                return
            }
            let data = MaxCustomData.adWorth(result.revenue)
            let showOK = loader.show(from: rootVC, customData: data)
            if !showOK { // 未能成功展示，立即结束展示并释放窗口
                AdWindowManager.shared.endPresentation()
            }
            // 立即返回展示结果；窗口释放由回调在广告结束/失败时触发
            continuation.resume(returning: showOK)
        }
    }
    
}
