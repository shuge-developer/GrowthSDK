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
        guard let loader = parent?.getLoader(for: result.adStyle),
              loader.isLoaded,
              loader.isAdValid() else {
            return false
        }
        
        parent?.setupLoaderCallbacks(loader: loader, result: result, adCallbacks: adCallbacks)
        
        return await withCheckedContinuation { continuation in
            // 使用独立的UIWindow展示广告，避免影响主应用视图层次结构
            let adWindow = UIWindow(frame: UIScreen.main.bounds)
            adWindow.windowLevel = UIWindow.Level.alert + 1
            adWindow.backgroundColor = UIColor.clear
            adWindow.isHidden = false
            
            // 创建一个透明的根视图控制器
            let adViewController = UIViewController()
            adViewController.view.backgroundColor = UIColor.clear
            adWindow.rootViewController = adViewController
            
            let data = MaxCustomData.adWorth(result.revenue)
            let result = loader.show(from: adViewController, customData: data)
            
            // 广告展示完成后清理window
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                adWindow.isHidden = true
            }
            
            continuation.resume(returning: result)
        }
    }
    
}
