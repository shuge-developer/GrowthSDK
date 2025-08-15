//
//  TaskGroupExecutor.swift
//  SmallGame
//
//  Created by arvin on 2025/6/28.
//

import Foundation

// MARK: - 任务组执行器
@MainActor
internal class TaskGroupExecutor {
    let session: BiddingSession
    let timeout: TimeInterval
    let config: BiddingConfig
    weak var parent: AdBiddingManager?
    
    init(session: BiddingSession, timeout: TimeInterval, config: BiddingConfig, parent: AdBiddingManager?) {
        self.session = session
        self.timeout = timeout
        self.config = config
        self.parent = parent
    }
    
    func execute() async {
        let adStyles = session.type.adStyles
        logTaskGroupStart(adStyles: adStyles)
        
        let startTime = Date()
        var completedCount = 0
        
        await withTaskGroup(of: BiddingResult?.self) { group in
            // 添加所有加载任务
            for adStyle in adStyles {
                group.addTask { [weak parent] in
                    return await parent?.loadSingleAd(style: adStyle)
                }
            }
            
            // 收集结果
            while !group.isEmpty {
                guard !checkTimeout(startTime: startTime) else {
                    group.cancelAll()
                    break
                }
                
                guard let result = await group.next() else { break }
                completedCount += 1
                
                if let result = result {
                    await handleSuccessResult(result: result)
                    
                    if await shouldEarlyExit() {
                        group.cancelAll()
                        break
                    }
                }
                
                if completedCount >= adStyles.count { break }
            }
        }
        
        logTaskGroupCompletion(adStyles: adStyles)
        startRetryForFailedAds(adStyles: adStyles)
    }
    
    private func checkTimeout(startTime: Date) -> Bool {
        let elapsed = Date().timeIntervalSince(startTime)
        if elapsed >= timeout {
            parent?.logInfo("⏰ TaskGroup 总体超时，强制结束")
            return true
        }
        return false
    }
    
    private func handleSuccessResult(result: BiddingResult) async {
        await session.addResult(result)
        parent?.logInfo("✅ 广告加载成功: \(result.adStyle) [ID: \(result.adStyle.adId)] - Revenue: \(parent?.formatRevenue(result.revenue) ?? "0")")
    }
    
    private func shouldEarlyExit() async -> Bool {
        let isPreloadMode = timeout >= config.preloadMaxWaitTime
        return await parent?.shouldPerformPartialBidding(session: session, timeout: timeout, isImmediate: !isPreloadMode) ?? false
    }
    
    private func logTaskGroupStart(adStyles: [AdStyle]) {
        parent?.logInfo("🎬 开始并发加载 \(session.type.description) 广告，共 \(adStyles.count) 个")
        parent?.logInfo("🎬 会话ID: \(session.id.prefix(8))")
    }
    
    private func logTaskGroupCompletion(adStyles: [AdStyle]) {
        Task {
            let resultCount = await session.resultCollector.getResultCount()
            parent?.logInfo("📊 TaskGroup 执行完毕")
            parent?.logInfo("📊 成功: \(resultCount)/\(adStyles.count)")
        }
    }
    
    private func startRetryForFailedAds(adStyles: [AdStyle]) {
        Task {
            let sessionResults = await session.results
            let loadedAdStyles = Set(sessionResults.map { $0.adStyle })
            let failedAdStyles = adStyles.filter { !loadedAdStyles.contains($0) }
            
            if !failedAdStyles.isEmpty {
                parent?.logInfo("🔄 开始异步重试失败的广告源...")
                await parent?.retryFailedAds(failedAdStyles: failedAdStyles)
            }
        }
    }
    
}
