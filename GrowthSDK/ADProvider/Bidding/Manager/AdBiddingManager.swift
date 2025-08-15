//
//  AdBiddingManager.swift
//  SmallGame
//
//  Created by arvin on 2025/6/26.
//

import Foundation
internal import AppLovinSDK
internal import KwaiAdsSDK
internal import BigoADS

// MARK: -
@MainActor
internal class AdBiddingManager {
    
    // MARK: - 单例
    static let shared = AdBiddingManager()
    
    // MARK: - 核心配置和缓存
    private let config = BiddingConfig()
    private let cache = BiddingCache()
    
    // MARK: - 专门的管理器
    private lazy var executionManager = BiddingExecutionManager(config: config, parent: self)
    private lazy var showManager = BiddingAdShowManager(parent: self)
    
    // MARK: - 会话管理
    private var currentSessions: [BiddingType: BiddingSession] = [:]
    private var preloadCompleted: Set<BiddingType> = []
    
    // MARK: - 广告加载器管理
    private var adLoaders: [String: Any] = [:]
    
    // MARK: - 回调管理
    typealias BiddingComplete = ((BiddingResult?) -> Void)
    private var completionHandlers: [String: BiddingComplete] = [:]
    
    // MARK: - 初始化
    private init() {
        logInfo("竞价管理器初始化完成")
    }
    
}

// MARK: - 工具和辅助函数
extension AdBiddingManager {
    
    /// 统一的日志输出函数
    func logInfo(_ message: String) {
        Logger.info("[Ad] [AdBiddingManager] \(message)")
    }
    
    /// 格式化时间显示
    func formatTime(_ timeInterval: TimeInterval, precision: Int = 1) -> String {
        return String(format: "%.\(precision)f", timeInterval)
    }
    
    /// 格式化收益显示
    func formatRevenue(_ revenue: Double) -> String {
        return String(format: "%.4f", revenue)
    }
    
    /// 检查自动补充是否启用
    func checkAutoRefillEnabled() -> Bool {
        guard config.enableAutoRefill else {
            logInfo("⚠️ 自动补充已禁用")
            return false
        }
        return true
    }
    
    /// 清理单个加载器
    func cleanupLoader(_ loader: BiddingAdLoader) {
        loader.cleanup()
    }
    
    /// 生成加载器存储键
    func makeLoaderKey(for adStyle: AdStyle) -> String {
        return "\(adStyle)"
    }
    
    /// 统一的预加载完成日志
    func logPreloadSuccess(type: BiddingType, result: BiddingResult, isSession: Bool = true) {
        if isSession {
            logInfo("✅ \(type.description) 预加载完成并缓存会话")
        } else {
            logInfo("✅ \(type.description) 预加载完成并缓存结果")
        }
        logInfo("✅ 获胜广告: \(result.adStyle) [ID: \(result.adStyle.adId)] - Revenue: \(formatRevenue(result.revenue))")
    }
    
    /// 获取有效结果并排序
    func getValidResultsSorted(from session: BiddingSession) async -> [BiddingResult] {
        let validResults = await getValidResults(from: session)
        return validResults.sorted { $0.revenue > $1.revenue }
    }
    
    /// 获取有效的竞价结果
    func getValidResults(from session: BiddingSession) async -> [BiddingResult] {
        return await session.getValidResults()
    }
}

// MARK: - 公共接口
extension AdBiddingManager {
    
    /// 开始预加载所有竞价广告
    func preloadAllAds() {
        let totalAds = BiddingType.allCases.reduce(0) { $0 + $1.adStyles.count }
        logInfo("🚀 开始预加载所有竞价广告，总计 \(totalAds) 个广告")
        
        for type in BiddingType.allCases {
            logInfo("🚀   - \(type.description): \(type.adStyles.count) 个")
        }
        logInfo("🚀 使用并行模式预加载，提高效率")
        
        // 并行预加载所有类型
        for type in BiddingType.allCases {
            preloadAds(type: type)
        }
    }
    
    /// 展示竞价广告（Unity 调用的主要接口）
    /// - Parameters:
    ///   - type: 竞价类型
    ///   - adCallbacks: 广告回调闭包（可选）
    func showAd(type: BiddingType, adCallbacks: BiddingAdCallbacks? = nil) {
        logInfo("🎯 请求展示 \(type.description) 广告")
        logInfo("📊 缓存状态: \(cache.getCacheStats())")
        
        // 1. 优先检查缓存中的最优广告
        if let bestAd = cache.getBestAvailableAd(type: type) {
            logInfo("📦 使用缓存最优广告展示: \(bestAd.adStyle) [Revenue: \(formatRevenue(bestAd.revenue))]")
            Task {
                // 创建临时会话用于展示
                let session = await self.createShowSession(with: bestAd, type: type)
                session.isFromCache = true
                
                let showResult = await self.showManager.performShow(session: session, adCallbacks: adCallbacks, usedAdStyle: bestAd.adStyle)
                
                // 只有展示成功才移除已使用的广告
                if showResult.success {
                    self.cache.removeUsedAd(result: bestAd)
                    logInfo("✅ 缓存广告展示成功，已移除使用的广告，补充将在广告关闭后进行")
                    
                    // 检查是否需要补充
                    if self.cache.needsRefill(type: type) {
                        logInfo("⚠️ 缓存不足，将在后台补充广告")
                    }
                } else {
                    logInfo("❌ 缓存广告展示失败，保留缓存")
                }
            }
            return
        }
        
        // 2. 检查当前是否有进行中的竞价会话，且已有可用广告
        if let currentSession = currentSessions[type], currentSession.state == .loading {
            Task {
                let sessionResults = await currentSession.results
                if !sessionResults.isEmpty {
                    let validResults = await self.getValidResults(from: currentSession)
                    if !validResults.isEmpty {
                        self.logInfo("⚡ 发现进行中的竞价有可用广告，立即使用")
                        // 从当前会话中选择最佳广告立即展示
                        await self.usePartialBiddingResultWithCallbacks(session: currentSession, adCallbacks: adCallbacks)
                    }
                }
            }
            return
        }
        
        // 3. 没有缓存也没有可用的进行中竞价，立即开始新竞价
        logInfo("⚡ 没有可用广告，开始即时竞价")
        
        // 无缓存时 - 先回调开始加载
        adCallbacks?.onStartLoading?()
        
        startBidding(type: type, isImmediate: true) { [weak self] result in
            guard let self = self else {
                adCallbacks?.onLoadFailed?(AdError.adNotAvailable)
                return
            }
            if let result = result {
                // 竞价成功 - 回调加载成功
                adCallbacks?.onLoadSuccess?(result.adSource)
                
                // 立即展示获胜广告
                Task {
                    let session = await self.createShowSession(with: result, type: type)
                    
                    let showResult = await self.showManager.performShow(session: session, adCallbacks: adCallbacks)
                    
                    // 补充将在广告关闭后进行
                    if showResult.success {
                        self.logInfo("✅ 即时竞价广告展示成功，补充将在广告关闭后进行")
                    } else {
                        self.logInfo("❌ 即时竞价广告展示失败，不进行补充")
                    }
                }
            } else {
                logInfo("❌ 即时竞价失败，无法展示广告")
                adCallbacks?.onLoadFailed?(AdError.adNotAvailable)
            }
        }
    }
    
    /// 开始竞价
    /// - Parameters:
    ///   - type: 竞价类型
    ///   - isImmediate: 是否立即模式（用于即时展示）
    ///   - completion: 竞价完成回调
    private func startBidding(type: BiddingType, isImmediate: Bool = false, completion: @escaping BiddingComplete) {
        logInfo("🚀 开始 \(type.description) 竞价, 立即模式: \(isImmediate)")
        
        // 检查是否已有进行中的竞价
        if let currentSession = currentSessions[type], currentSession.state == .loading {
            logInfo("⚠️ \(type.description) 竞价已在进行中，SessionID: \(currentSession.id.prefix(8))")
            
            // 如果是立即模式且当前会话有可用广告，优先使用
            if isImmediate {
                Task {
                    let validResults = await getValidResults(from: currentSession)
                    if !validResults.isEmpty {
                        logInfo("⚡ 立即模式下使用当前竞价的可用广告")
                        // 直接返回第一个有效结果，无需额外展示
                        if let firstValidResult = validResults.first {
                            completion(firstValidResult)
                        } else {
                            completion(nil)
                        }
                    } else {
                        // 否则等待当前竞价完成
                        completionHandlers[currentSession.id] = completion
                    }
                }
                return
            }
            
            // 否则等待当前竞价完成
            completionHandlers[currentSession.id] = completion
            return
        }
        
        // 创建新的竞价会话
        let session = BiddingSession(type: type)
        currentSessions[type] = session
        completionHandlers[session.id] = completion
        
        Task {
            let description = await session.description
            logInfo("📝 创建竞价会话: \(description)")
        }
        
        // 开始异步竞价
        Task {
            if isImmediate {
                logInfo("⚡ 调用立即竞价模式")
                await executionManager.performImmediateBidding(session: session)
            } else {
                logInfo("📊 调用预加载竞价模式")
                await executionManager.performPreloadBidding(session: session)
            }
        }
    }
    
}

// MARK: - 资源清理
extension AdBiddingManager {
    
    /// 清理过期的竞价会话
    func cleanup() {
        let expiredTime: TimeInterval = 300 // 5分钟过期
        let now = Date()
        
        for (type, session) in currentSessions {
            let isExpired = now.timeIntervalSince(session.startTime) > expiredTime
            if isExpired {
                Task {
                    let description = await session.description
                    logInfo("🗑️ 清理过期竞价会话: \(description)")
                }
                completionHandlers.removeValue(forKey: session.id)
                cleanupSessionLoaders(session: session)
                currentSessions.removeValue(forKey: type)
            }
        }
        
        // 使用新的清理过期广告方法，而不是清理所有缓存
        cache.cleanupExpiredAds()
        logInfo("📊 清理后缓存状态: \(cache.getCacheStats())")
    }
    
    /// 强制清理所有竞价会话和加载器
    func forceCleanup() {
        logInfo("🧹 强制清理所有竞价资源")
        
        // 清理所有加载器
        cleanupAllLoaders()
        
        // 清理所有会话和状态
        currentSessions.removeAll()
        completionHandlers.removeAll()
        preloadCompleted.removeAll()
        cache.clearAll()
        logInfo("📊 强制清理后缓存状态: \(cache.getCacheStats())")
    }
    
    /// 清理会话相关的加载器
    private func cleanupSessionLoaders(session: BiddingSession) {
        for adStyle in session.type.adStyles {
            let loaderKey = makeLoaderKey(for: adStyle)
            if let loader = adLoaders.removeValue(forKey: loaderKey) as? BiddingAdLoader {
                cleanupLoader(loader)
            }
        }
    }
    
    /// 清理所有加载器
    private func cleanupAllLoaders() {
        for (_, loader) in adLoaders {
            if let adLoader = loader as? BiddingAdLoader {
                cleanupLoader(adLoader)
            }
        }
        adLoaders.removeAll()
    }
}

// MARK: - 预加载管理
private extension AdBiddingManager {
    
    /// 预加载指定类型的广告
    func preloadAds(type: BiddingType) {
        guard !preloadCompleted.contains(type) else {
            logInfo("\(type.description) 已预加载完成")
            return
        }
        
        logPreloadDetails(for: type)
        
        startBidding(type: type, isImmediate: false) { [weak self] result in
            self?.handlePreloadResult(type: type, result: result)
        }
    }
    
    /// 记录预加载详情
    private func logPreloadDetails(for type: BiddingType) {
        logInfo("📋 预加载详情: 共 \(type.adStyles.count) 个广告源")
        for (index, adStyle) in type.adStyles.enumerated() {
            logInfo("📋   \(index + 1). \(adStyle) [ID: \(adStyle.adId)]")
        }
    }
    
    /// 处理预加载结果
    private func handlePreloadResult(type: BiddingType, result: BiddingResult?) {
        if let result = result {
            handlePreloadSuccess(type: type, result: result)
        } else {
            handlePreloadFailure(type: type)
        }
    }
    
    /// 处理预加载成功
    private func handlePreloadSuccess(type: BiddingType, result: BiddingResult) {
        if let session = currentSessions[type] {
            cacheSessionResult(session: session, result: result, type: type)
            currentSessions.removeValue(forKey: type) // 清理引用，因为已经缓存
        } else {
            createAndCacheSession(type: type, result: result)
        }
        
        preloadCompleted.insert(type)
        checkAllPreloadCompleted()
    }
    
    /// 缓存会话结果
    private func cacheSessionResult(session: BiddingSession, result: BiddingResult, type: BiddingType) {
        session.winnerResult = result
        session.state = .completed
        cache.cacheSession(session: session)
        
        logPreloadSuccess(type: type, result: result, isSession: true)
        Task {
            let description = await session.description
            logInfo("✅ 会话详情: \(description)")
        }
        logInfo("📊 缓存后状态: \(cache.getCacheStats())")
    }
    
    /// 创建并缓存新会话
    private func createAndCacheSession(type: BiddingType, result: BiddingResult) {
        let session = BiddingSession(type: type)
        session.winnerResult = result
        session.state = .completed
        Task {
            await session.addResult(result)
        }
        cache.cacheSession(session: session)
        
        logPreloadSuccess(type: type, result: result, isSession: false)
        logInfo("📊 缓存后状态: \(cache.getCacheStats())")
    }
    
    /// 检查所有预加载是否完成
    private func checkAllPreloadCompleted() {
        if preloadCompleted.count == BiddingType.allCases.count {
            let totalCachedAds = preloadCompleted.reduce(0) { count, type in
                return count + cache.getAvailableCount(type: type)
            }
            logInfo("🎉 所有类型的广告预加载完成！")
            logInfo("🎉 总计已缓存 \(totalCachedAds) 个广告可供使用")
        }
    }
    
    /// 处理预加载失败
    private func handlePreloadFailure(type: BiddingType) {
        let retryDelay = config.exponentialBackoffDelay(attempt: 1)
        logInfo("\(type.description) 预加载失败，将在 \(formatTime(retryDelay)) 秒后重试")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) { [weak self] in
            self?.preloadAds(type: type)
        }
    }
    
}

// MARK: - 部分竞价结果处理
private extension AdBiddingManager {
    
    /// 使用部分竞价结果立即展示（带回调）
    func usePartialBiddingResultWithCallbacks(session: BiddingSession, adCallbacks: BiddingAdCallbacks?) async {
        let validResults = await getValidResults(from: session)
        guard !validResults.isEmpty else {
            logInfo("❌ 没有可用的部分竞价结果")
            adCallbacks?.onShowFailed?(AdError.adNotAvailable)
            return
        }
        
        // 选择最高价广告
        let sortedResults = validResults.sorted { $0.revenue > $1.revenue }
        let winner = sortedResults.first!
        
        logInfo("⚡ 使用部分竞价结果展示: \(winner.description)")
        
        // 创建临时会话用于展示
        let showSession = await createTemporaryShowSession(from: session, winner: winner, validResults: validResults)
        let showResult = await showManager.performShow(session: showSession, adCallbacks: adCallbacks, usedAdStyle: winner.adStyle)
        
        // 补充将在广告关闭后进行
        if showResult.success {
            logInfo("✅ 部分竞价广告展示成功，补充将在广告关闭后进行")
        } else {
            logInfo("❌ 部分竞价广告展示失败，不进行补充")
        }
    }
    
    /// 创建临时展示会话
    private func createTemporaryShowSession(from session: BiddingSession, winner: BiddingResult, validResults: [BiddingResult]) async -> BiddingSession {
        let showSession = BiddingSession(type: session.type)
        showSession.winnerResult = winner
        await showSession.addResults(validResults)
        showSession.state = .completed
        return showSession
    }
    
    /// 创建用于展示的会话（基于单个广告结果）
    private func createShowSession(with result: BiddingResult, type: BiddingType) async -> BiddingSession {
        let session = BiddingSession(type: type)
        session.winnerResult = result
        await session.addResult(result)
        session.state = .completed
        return session
    }
}

// MARK: - 广告补充管理
extension AdBiddingManager {
    
    /// 开始补充特定广告源
    /// - Parameters:
    ///   - adStyle: 需要补充的特定广告源
    ///   - delay: 延迟时间（用于广告关闭后触发）
    func startRefillSpecificAd(adStyle: AdStyle, delay: TimeInterval = 0.0) {
        guard checkAutoRefillEnabled() else {
            return
        }
        let refillTask = createRefillTask(for: adStyle)
        if delay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                refillTask()
            }
        } else {
            refillTask()
        }
    }
    
    /// 创建补充任务
    private func createRefillTask(for adStyle: AdStyle) -> () -> Void {
        return { [weak self] in
            guard let self = self else { return }
            self.logInfo("🔄 开始补充特定广告源: \(adStyle)")
            Task {
                let result = await self.loadSingleAdWithRetry(style: adStyle, maxRetries: self.config.retryMaxCount)
                if result != nil {
                    self.logInfo("✅ 广告补充成功: \(adStyle)")
                } else {
                    self.logInfo("❌ 广告补充失败: \(adStyle)")
                }
            }
        }
    }
    
    /// 开始补充所有类型广告（预加载失败时使用）
    func startRefillAds(type: BiddingType) {
        guard checkAutoRefillEnabled() else {
            return
        }
        logInfo("🔄 开始补充 \(type.description) 广告")
        preloadCompleted.remove(type) // 标记需要重新加载
        preloadAds(type: type)
    }
    
    /// 带重试机制的单个广告加载
    func loadSingleAdWithRetry(style: AdStyle, maxRetries: Int) async -> BiddingResult? {
        let startTime = Date()
        logInfo("🔄 开始加载广告: \(style)")
        
        var attemptCount = 0
        
        while attemptCount < maxRetries {
            let isRetry = attemptCount > 0
            
            if isRetry {
                // 使用指数退避算法计算延迟时间
                let delay = config.exponentialBackoffDelay(attempt: attemptCount)
                logInfo("🔄 重试加载广告 (第\(attemptCount + 1)次尝试，第\(attemptCount)次重试): \(style)，延迟 \(formatTime(delay))s")
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            } else {
                logInfo("🔄 首次加载广告: \(style)")
            }
            
            guard let loader = BiddingLoaderFactory.createLoader(for: style) else {
                logInfo("❌ 无法创建广告加载器: \(style)")
                attemptCount += 1
                continue // 继续下一次尝试
            }
            
            do {
                let adSource = try await AdUtils.withTimeout(seconds: style.timeout) {
                    try await withCheckedThrowingContinuation { continuation in
                        loader.load { result in
                            switch result {
                            case .success(let adSource):
                                continuation.resume(returning: adSource)
                            case .failure(let error):
                                continuation.resume(throwing: error)
                            }
                        }
                    }
                }
                
                let result = BiddingResult(
                    adSource: adSource,
                    adStyle: style,
                    revenue: adSource.revenue,
                    loadTime: startTime,
                    isValid: true
                )
                
                // 存储加载器以备后续使用（使用AdStyle完整描述作为key避免冲突）
                let loaderKey = makeLoaderKey(for: style)
                adLoaders[loaderKey] = loader
                logInfo("🔗 存储广告加载器: Key=\(loaderKey), LoaderType=\(type(of: loader))")
                
                let duration = Date().timeIntervalSince(startTime)
                if isRetry {
                    logInfo("✅ 广告重试加载成功 (第\(attemptCount + 1)次尝试，第\(attemptCount)次重试): \(style) [ID: \(style.adId)], Revenue: \(formatRevenue(adSource.revenue)), Duration: \(formatTime(duration))s")
                } else {
                    logInfo("✅ 广告首次加载成功: \(style) [ID: \(style.adId)], Revenue: \(formatRevenue(adSource.revenue)), Duration: \(formatTime(duration))s")
                }
                return result
                
            } catch {
                let duration = Date().timeIntervalSince(startTime)
                cleanupLoader(loader)
                
                let currentAttempt = attemptCount + 1
                attemptCount += 1
                
                if attemptCount < maxRetries {
                    logInfo("⚠️ 广告加载失败 (第\(currentAttempt)次尝试，将重试): \(style) [ID: \(style.adId)], Error: \(error.localizedDescription), Duration: \(formatTime(duration))s")
                    continue // 重试
                } else {
                    logInfo("❌ 广告加载最终失败 (已重试\(maxRetries - 1)次): \(style) [ID: \(style.adId)], Error: \(error.localizedDescription), Duration: \(formatTime(duration))s")
                    return nil
                }
            }
        }
        return nil
    }
    
    /// 重试失败的广告源
    func retryFailedAds(failedAdStyles: [AdStyle]) async {
        logInfo("🔄 开始重试 \(failedAdStyles.count) 个失败的广告源")
        for adStyle in failedAdStyles {
            await retrySpecificAdStyle(adStyle)
        }
        logInfo("🎉 失败广告源重试完成")
    }
    
    /// 重试特定广告源
    private func retrySpecificAdStyle(_ adStyle: AdStyle) async {
        logInfo("🔄 重试加载失败的广告源: \(adStyle)")
        let result = await loadSingleAdWithRetry(style: adStyle, maxRetries: config.retryMaxCount)
        if let result = result {
            logInfo("✅ 广告源重试成功: \(adStyle)")
            addRetryResultToSession(result: result, adStyle: adStyle)
        } else {
            logInfo("❌ 广告源重试最终失败: \(adStyle)")
        }
    }
    
    /// 将重试成功的结果添加到会话
    private func addRetryResultToSession(result: BiddingResult, adStyle: AdStyle) {
        if let session = currentSessions[adStyle.type] {
            Task {
                await session.addResult(result)
                let description = await session.description
                logInfo("📝 已将重试成功的广告添加到会话: \(description)")
            }
        }
    }
    
    /// 精确补充指定广告源
    /// - Parameter adStyle: 需要补充的广告源
    func startPreciseRefill(for adStyle: AdStyle, delay: TimeInterval = 1.0) {
        guard checkAutoRefillEnabled() else {
            return
        }
        
        let type = adStyle.type
        logInfo("🎯 开始精确补充: \(adStyle), 当前缓存: \(cache.getAvailableCount(type: type))个")
        
        // 延迟补充，避免与广告关闭事件冲突
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            
            Task {
                let result = await self.loadSingleAdWithRetry(style: adStyle, maxRetries: self.config.retryMaxCount)
                if let result = result {
                    // 直接缓存到新的缓存系统
                    self.cache.cacheAd(result: result)
                    self.logInfo("✅ 精确补充成功: \(adStyle) [Revenue: \(self.formatRevenue(result.revenue))]")
                    self.logInfo("📊 补充后缓存状态: \(self.cache.getCacheStats())")
                } else {
                    self.logInfo("❌ 精确补充失败: \(adStyle)")
                    
                    // 如果单个广告补充失败，检查是否需要全类型补充
                    if self.cache.getAvailableCount(type: type) == 0 {
                        self.logInfo("⚠️ 该类型无可用广告，启动全类型补充")
                        self.startRefillAds(type: type)
                    }
                }
            }
        }
    }
}

// MARK: - 内部方法（被分离的管理器调用）
extension AdBiddingManager {
    
    /// 加载单个广告（被TaskGroupExecutor调用）
    func loadSingleAd(style: AdStyle) async -> BiddingResult? {
        return await loadSingleAdWithRetry(style: style, maxRetries: config.retryMaxCount)
    }
    
    /// 判断是否应该执行部分竞价（被TaskGroupExecutor调用）
    func shouldPerformPartialBidding(session: BiddingSession, timeout: TimeInterval, isImmediate: Bool = true) async -> Bool {
        let validResults = await getValidResults(from: session)
        if isImmediate {
            return shouldPerformImmediateBidding(validResults: validResults, session: session)
        } else {
            return shouldPerformPreloadBidding(validResults: validResults, session: session)
        }
    }
    
    /// 获取加载器（被AdShowManager调用）
    func getLoader(for adStyle: AdStyle) -> BiddingAdLoader? {
        let loaderKey = makeLoaderKey(for: adStyle)
        return adLoaders[loaderKey] as? BiddingAdLoader
    }
    
    /// 判断是否应该执行立即竞价
    private func shouldPerformImmediateBidding(validResults: [BiddingResult], session: BiddingSession) -> Bool {
        let hasMinCount = validResults.count >= config.immediateMinSuccessCount
        let hasMinTime = session.duration >= config.immediateMinWaitTime
        let hasMaxTime = session.duration >= config.immediateMaxWaitTime
        
        logInfo("📊 立即竞价检查: 成功数(\(validResults.count)/\(config.immediateMinSuccessCount)), 时间(\(formatTime(session.duration))s/\(formatTime(config.immediateMinWaitTime))s), 超时(\(hasMaxTime))")
        return hasMaxTime || (hasMinCount && hasMinTime)
    }
    
    /// 判断是否应该执行预加载竞价
    private func shouldPerformPreloadBidding(validResults: [BiddingResult], session: BiddingSession) -> Bool {
        let hasMinCount = validResults.count >= config.preloadMinSuccessCount
        let hasMinTime = session.duration >= config.preloadMinWaitTime
        let hasMaxTime = session.duration >= config.preloadMaxWaitTime
        let allSuccess = validResults.count == session.type.adStyles.count
        
        logInfo("📊 预加载竞价检查: 成功数(\(validResults.count)/\(config.preloadMinSuccessCount)), 时间(\(formatTime(session.duration))s/\(formatTime(config.preloadMinWaitTime))s), 超时(\(hasMaxTime)), 全部成功(\(allSuccess))")
        return hasMaxTime || allSuccess || (hasMinCount && hasMinTime)
    }
}

// MARK: - 收益计算和算法管理
extension AdBiddingManager {
    
    /// 执行竞价算法
    func executeBiddingAlgorithm(session: BiddingSession) async {
        let description = await session.description
        logInfo("🎯 executeBiddingAlgorithm 方法被调用，会话: \(description)")
        let validResults = await getValidResults(from: session)
        
        guard !validResults.isEmpty else {
            logInfo("❌ 没有有效的广告参与竞价")
            await finishBidding(session: session, state: .failed)
            return
        }
        
        // 执行竞价逻辑
        let sortedResults = performBiddingLogic(validResults: validResults, session: session)
        let winner = sortedResults.first!
        session.winnerResult = winner
        
        // 记录竞价结果
        logBiddingResults(sortedResults: sortedResults, session: session)
        
        // 通知所有广告源竞价结果
        await notifyBiddingResults(validResults: sortedResults, winner: winner)
        await finishBidding(session: session, state: .completed)
    }
    
    /// 执行竞价逻辑
    private func performBiddingLogic(validResults: [BiddingResult], session: BiddingSession) -> [BiddingResult] {
        // 详细打印参与竞价的所有广告
        logInfo("🎯 开始执行竞价算法: \(session.type.description)")
        logInfo("📋 参与竞价的广告列表:")
        for (index, result) in validResults.enumerated() {
            logInfo("📋   \(index + 1). \(result.adStyle) [ID: \(result.adStyle.adId)] - Revenue: \(formatRevenue(result.revenue))")
        }
        // 按收益排序
        return validResults.sorted { $0.revenue > $1.revenue }
    }
    
    /// 记录竞价结果
    private func logBiddingResults(sortedResults: [BiddingResult], session: BiddingSession) {
        let winner = sortedResults.first!
        logInfo("🏆 竞价完成，获胜广告: \(winner.adStyle) [ID: \(winner.adStyle.adId)] - Revenue: \(formatRevenue(winner.revenue))")
        
        if sortedResults.count > 1 {
            let secondPlace = sortedResults[1]
            logInfo("🥈 第二名广告: \(secondPlace.adStyle) [ID: \(secondPlace.adStyle.adId)] - Revenue: \(formatRevenue(secondPlace.revenue))")
            logInfo("💰 价格优势: 获胜者比第二名高 \(formatRevenue(winner.revenue - secondPlace.revenue))")
        }
        
        let validCount = sortedResults.count
        Task {
            let totalCount = await session.results.count
            logInfo("📊 竞价统计: 总加载 \(totalCount), 成功 \(validCount), 耗时 \(formatTime(session.duration))s")
        }
    }
}

// MARK: - 竞价结果通知管理
extension AdBiddingManager {
    
    /// 通知竞价结果给各个广告源
    func notifyBiddingResults(validResults: [BiddingResult], winner: BiddingResult) async {
        logInfo("📢 开始通知竞价结果给各广告源")
        let winnerPrice = winner.revenue
        let secondPrice = validResults.count > 1 ? validResults[1].revenue : winnerPrice * 0.9
        
        for result in validResults {
            let loaderKey = makeLoaderKey(for: result.adStyle)
            guard let loader = adLoaders[loaderKey] as? BiddingAdLoader else {
                continue
            }
            if result.adStyle.adId == winner.adStyle.adId {
                // 通知获胜方
                await notifyAdWin(loader: loader, result: result, secondPrice: secondPrice)
            } else {
                // 通知失败方
                await notifyAdLoss(loader: loader, result: result, winnerPrice: winnerPrice, winnerSource: winner.adSource)
            }
        }
        logInfo("✅ 竞价结果通知完成")
    }
    
    /// 通知广告获胜
    func notifyAdWin(loader: BiddingAdLoader, result: BiddingResult, secondPrice: Double) async {
        logInfo("🏆 通知广告获胜: \(result.adStyle), SecondPrice: \(formatRevenue(secondPrice))")
        
        let secBidder = result.adSource.name// "竞品广告源" // 可以根据实际情况调整
        loader.notifyBidWin(secondPrice: secondPrice, secondBidder: secBidder)
    }
    
    /// 通知广告失败
    func notifyAdLoss(loader: BiddingAdLoader, result: BiddingResult, winnerPrice: Double, winnerSource: AdCallback.AdSource) async {
        logInfo("💔 通知广告失败: \(result.adStyle), WinnerPrice: \(formatRevenue(winnerPrice))")
        loader.notifyBidLoss(firstPrice: winnerPrice, firstBidder: winnerSource.name, lossReason: .lowerPrice)
    }
    
    /// 完成竞价
    func finishBidding(session: BiddingSession, state: BiddingState) async {
        session.state = state
        logInfo("🏁 竞价结束: \(await session.description)")
        
        // 处理预加载完成的特殊情况
        if state == .completed && !preloadCompleted.contains(session.type) {
            logPreloadCompletion(session: session)
        }
        
        // 清理会话引用
        cleanupSessionReference(session: session, state: state)
        
        // 执行完成回调
        let completion = completionHandlers.removeValue(forKey: session.id)
        completion?(session.winnerResult)
    }
    
    /// 记录预加载完成信息
    private func logPreloadCompletion(session: BiddingSession) {
        Task {
            let validResults = await getValidResults(from: session)
            let allResults = await session.results
            let validCount = validResults.count
            let totalCount = allResults.count
            
            if session.winnerResult != nil {
                logInfo("🎊 🎊 🎊 \(session.type.description) 预加载大功告成！🎊 🎊 🎊")
                logInfo("📊 预加载统计: 成功 \(validCount)/\(totalCount), 获胜者: \(session.winnerResult!.adStyle) (Revenue: \(formatRevenue(session.winnerResult!.revenue)))")
                logInfo("💾 正在缓存竞价结果...")
            }
        }
    }
    
    /// 清理会话引用
    private func cleanupSessionReference(session: BiddingSession, state: BiddingState) {
        // 清理当前会话引用（除非是需要缓存的成功会话）
        if state != .completed || preloadCompleted.contains(session.type) {
            currentSessions.removeValue(forKey: session.type)
        }
    }
}



// MARK: - 广告后处理管理
extension AdBiddingManager {
    
    /// 设置Loader回调监听（用于获取真实的广告事件）
    func setupLoaderCallbacks(loader: BiddingAdLoader, result: BiddingResult, adCallbacks: BiddingAdCallbacks?) {
        logInfo("🔗 设置广告事件监听: \(result.adStyle)")
        
        // 根据不同的 Loader 类型设置回调
        switch loader {
        case let maxLoader as MaxBiddingLoader:
            setupMaxLoaderCallbacks(maxLoader: maxLoader, result: result, adCallbacks: adCallbacks)
        case let kwaiLoader as KwaiBiddingLoader:
            setupKwaiLoaderCallbacks(kwaiLoader: kwaiLoader, result: result, adCallbacks: adCallbacks)
        case let bigoLoader as BigoBiddingLoader:
            setupBigoLoaderCallbacks(bigoLoader: bigoLoader, result: result, adCallbacks: adCallbacks)
        default:
            logInfo("⚠️ 未知的 Loader 类型: \(type(of: loader))")
        }
    }
    
    /// 设置 MAX Loader 回调监听
    func setupMaxLoaderCallbacks(maxLoader: MaxBiddingLoader, result: BiddingResult, adCallbacks: BiddingAdCallbacks?) {
        logInfo("🔗 设置 MAX 广告回调监听: \(result.adStyle)")
        
        // 保存原有回调
        let originalCallback = maxLoader.callback.adStateComplete
        
        // 使用 weak 引用避免循环引用，同时复制必要的数据
        let resultCopy = BiddingResult(
            adSource: result.adSource,
            adStyle: result.adStyle,
            revenue: result.revenue,
            loadTime: result.loadTime,
            isValid: result.isValid
        )
        
        // 由于 BiddingAdCallbacks 是 struct，直接捕获其副本，只对 self 使用 weak 引用
        let adCallbacksCopy = adCallbacks
        
        // 设置新的回调包装 - 使用 weak self 避免循环引用
        maxLoader.callback.adStateComplete = { [weak self] state in
            // 先执行原有逻辑
            originalCallback?(state)
            
            // 再执行我们的回调逻辑 - 使用弱引用避免循环引用
            self?.handleAdStateCallback(state: state, result: resultCopy, adCallbacks: adCallbacksCopy)
        }
    }
    
    /// 设置 Kwai Loader 回调监听
    func setupKwaiLoaderCallbacks(kwaiLoader: KwaiBiddingLoader, result: BiddingResult, adCallbacks: BiddingAdCallbacks?) {
        logInfo("🔗 设置 Kwai 广告回调监听: \(result.adStyle)")
        
        // 创建结果副本避免强引用
        let resultCopy = BiddingResult(
            adSource: result.adSource,
            adStyle: result.adStyle,
            revenue: result.revenue,
            loadTime: result.loadTime,
            isValid: result.isValid
        )
        
        // 由于 BiddingAdCallbacks 是 struct，直接捕获其副本
        let adCallbacksCopy = adCallbacks
        
        // Kwai 的回调已经在 setupCallback 中设置，我们需要获取对应的回调对象
        switch result.adStyle.format {
        case .rewarded:
            let originalCallback = kwaiLoader.rewardCallback.adStateComplete
            kwaiLoader.rewardCallback.adStateComplete = { [weak self] state in
                originalCallback?(state)
                self?.handleAdStateCallback(state: state, result: resultCopy, adCallbacks: adCallbacksCopy)
            }
        case .interstitial:
            let originalCallback = kwaiLoader.intersCallback.adStateComplete
            kwaiLoader.intersCallback.adStateComplete = { [weak self] state in
                originalCallback?(state)
                self?.handleAdStateCallback(state: state, result: resultCopy, adCallbacks: adCallbacksCopy)
            }
        default:
            break
        }
    }
    
    /// 设置 Bigo Loader 回调监听
    func setupBigoLoaderCallbacks(bigoLoader: BigoBiddingLoader, result: BiddingResult, adCallbacks: BiddingAdCallbacks?) {
        logInfo("🔗 设置 Bigo 广告回调监听: \(result.adStyle)")
        
        // 保存原有回调
        let originalCallback = bigoLoader.callback.adStateComplete
        
        // 创建结果副本避免强引用
        let resultCopy = BiddingResult(
            adSource: result.adSource,
            adStyle: result.adStyle,
            revenue: result.revenue,
            loadTime: result.loadTime,
            isValid: result.isValid
        )
        
        // 由于 BiddingAdCallbacks 是 struct，直接捕获其副本，只对 self 使用 weak 引用
        let adCallbacksCopy = adCallbacks
        
        // 设置新的回调包装 - 使用 weak self 避免循环引用
        bigoLoader.callback.adStateComplete = { [weak self] state in
            // 先执行原有逻辑
            originalCallback?(state)
            
            // 再执行我们的回调逻辑 - 使用弱引用避免循环引用
            self?.handleAdStateCallback(state: state, result: resultCopy, adCallbacks: adCallbacksCopy)
        }
    }
    
    /// 处理广告状态回调
    func handleAdStateCallback(state: AdCallback.AdLoadState, result: BiddingResult, adCallbacks: BiddingAdCallbacks?) {
        switch state {
        case .showFailure(let error):
            logInfo("❌ 广告展示失败回调: \(result.adStyle), 错误: \(error.localizedDescription)")
            adCallbacks?.onShowFailed?(error)
            
        case .didDisplay(_):
            logInfo("🎭 广告开始展示回调: \(result.adStyle)")
            adCallbacks?.onShowSuccess?(result)
            
        case .didReward(_):
            logInfo("🎁 广告奖励回调: \(result.adStyle)")
            adCallbacks?.onGetReward?(result)
            
        case .didClick(_):
            logInfo("👆 广告点击回调: \(result.adStyle)")
            adCallbacks?.onAdClick?(result)
            
        case .didHide(_):
            logInfo("🔒 广告关闭回调: \(result.adStyle)")
            adCallbacks?.onClose?(result)
            
            logInfo("🔄 广告已关闭，开始精确补充: \(result.adStyle)")
            startPreciseRefill(for: result.adStyle)
            
        default:
            // 其他状态不需要额外处理
            break
        }
    }
    
    /// 清理已使用的广告加载器状态
    func cleanupUsedAdLoader(adStyle: AdStyle) {
        let loaderKey = makeLoaderKey(for: adStyle)
        guard adLoaders[loaderKey] as? BiddingAdLoader != nil else {
            return
        }
        
        logInfo("🧹 清理广告加载器状态: \(adStyle)")
        
        // 移除该广告在当前竞价结果中的有效性
        invalidateAdInCurrentSession(adStyle: adStyle)
    }
    
    /// 在当前会话中标记广告为无效
    private func invalidateAdInCurrentSession(adStyle: AdStyle) {
        if let session = currentSessions[adStyle.type] {
            Task {
                await session.invalidateResult(for: adStyle)
                logInfo("✅ 已标记广告结果为无效: \(adStyle)")
            }
        }
    }
    
    /// 移除失败的广告并启动补充
    func removeFailedAd(result: BiddingResult) {
        logInfo("🗑️ 移除失败广告: \(result.description)")
        result.invalidate()
        cache.removeUsedAd(result: result)
        
        // 启动精确补充
        startPreciseRefill(for: result.adStyle, delay: 0.5)
    }
}
