//
//  BiddingExecutionManager.swift
//  SmallGame
//
//  Created by arvin on 2025/6/28.
//

import Foundation

// MARK: - 竞价执行管理器
@MainActor
internal class BiddingExecutionManager {
    private let config: BiddingConfig
    private weak var parent: AdBiddingManager?
    
    init(config: BiddingConfig, parent: AdBiddingManager) {
        self.config = config
        self.parent = parent
    }
    
    /// 执行立即竞价
    func performImmediateBidding(session: BiddingSession) async {
        session.state = .loading
        parent?.logInfo("⚡ 开始执行立即竞价: \(await session.description)")
        
        guard AdsInitProvider.videoAdInitialized else {
            parent?.logInfo("❌ 广告 SDK 未完全初始化")
            await parent?.finishBidding(session: session, state: .failed)
            return
        }
        
        await performBiddingWithTimeout(session: session, timeout: 8.0)
    }
    
    /// 执行预加载竞价
    func performPreloadBidding(session: BiddingSession) async {
        session.state = .loading
        parent?.logInfo("📊 开始执行竞价: \(await session.description)")
        
        guard AdsInitProvider.videoAdInitialized else {
            parent?.logInfo("❌ 广告 SDK 未完全初始化")
            await parent?.finishBidding(session: session, state: .failed)
            return
        }
        
        await performBiddingWithTimeout(session: session, timeout: config.maxWaitTime)
    }
    
    /// 执行带超时的竞价（重构后的简化版本）
    private func performBiddingWithTimeout(session: BiddingSession, timeout: TimeInterval) async {
        let executor = TaskGroupExecutor(session: session, timeout: timeout, config: config, parent: parent)
        await executor.execute()
        await parent?.executeBiddingAlgorithm(session: session)
    }
    
}
