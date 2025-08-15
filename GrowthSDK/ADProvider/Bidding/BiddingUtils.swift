//
//  BiddingUtils.swift
//  SmallGame
//
//  Created by arvin on 2025/6/27.
//

import Foundation

// MARK: - 竞价结果数据模型
internal class BiddingResult {
    let adSource: AdCallback.AdSource
    let adStyle: AdStyle
    let revenue: Double
    let loadTime: Date
    
    private var _isValid: Bool
    var isValid: Bool {
        return _isValid
    }
    
    init(adSource: AdCallback.AdSource, adStyle: AdStyle, revenue: Double, loadTime: Date = Date(), isValid: Bool = true) {
        self.adSource = adSource
        self.adStyle = adStyle
        self.revenue = revenue
        self.loadTime = loadTime
        self._isValid = isValid
    }
    
    func invalidate() {
        _isValid = false
    }
    
    var description: String {
        return "[BiddingResult] Style: \(adStyle), Revenue: \(revenue), Valid: \(isValid), Source: \(adSource.description)"
    }
}

// MARK: - 竞价配置
internal struct BiddingConfig {
    let minWaitTime: TimeInterval = 5.0        // 最小等待时间（从2秒增加到5秒）
    let maxWaitTime: TimeInterval = 30.0       // 最大等待时间（从16秒增加到30秒）
    let minSuccessCount: Int = 3               // 最小成功广告数量（从1个增加到3个）
    let enablePartialBidding: Bool = true      // 启用部分竞价
    let enableFallback: Bool = true            // 启用回退机制
    let enableAutoRefill: Bool = true          // 启用自动补充广告
    let cacheExpireTime: TimeInterval = 1800   // 缓存过期时间（30分钟）
    let retryMaxCount: Int = 3                 // 最大重试次数
    let retryBaseDelay: TimeInterval = 1.0     // 重试基础延迟（用于指数退避）
    
    // 预加载专用配置（启动时预加载，追求最大广告源数量）
    let preloadMaxWaitTime: TimeInterval = 30.0     // 预加载最大等待时间
    let preloadMinWaitTime: TimeInterval = 25.0     // 预加载最小等待时间（接近最大值，确保充分预加载）
    // 预加载最小成功数量（全部6个广告源）
    var preloadMinSuccessCount: Int {
        let types = BiddingType.allCases.flatMap { $0.adStyles }
        return min(6, types.count)
    }
    // 立即竞价配置（展示时快速响应）
    let immediateMaxWaitTime: TimeInterval = 8.0    // 立即竞价最大等待时间
    let immediateMinWaitTime: TimeInterval = 3.0    // 立即竞价最小等待时间
    let immediateMinSuccessCount: Int = 2           // 立即竞价最小成功数量
    
    /// 计算指数退避延迟
    func exponentialBackoffDelay(attempt: Int) -> TimeInterval {
        let delay = retryBaseDelay * pow(2.0, Double(attempt - 1))
        return min(delay, 10.0)
    }
    
}

// MARK: - 竞价状态
internal enum BiddingState {
    case idle           // 空闲状态
    case loading        // 正在加载广告
    case completed      // 竞价完成
    case timeout        // 竞价超时
    case failed         // 竞价失败
    case cached         // 已缓存
    
    var description: String {
        switch self {
        case .idle:      return "空闲"
        case .loading:   return "加载中"
        case .completed: return "完成"
        case .timeout:   return "超时"
        case .failed:    return "失败"
        case .cached:    return "已缓存"
        }
    }
}

// MARK: - 竞价类型
internal enum BiddingType: Int, CaseIterable {
    case rewarded     = 1 // 激励视频竞价
    case interstitial = 0 // 插屏广告竞价
    
    var description: String {
        switch self {
        case .rewarded:     return "激励视频"
        case .interstitial: return "插屏广告"
        }
    }
    
    var adStyles: [AdStyle] {
        AdStyleConfigManager.shared.adStyles(for: self)
    }
    
    var localStyles: [AdStyle] {
        switch self {
        case .rewarded:
            return [
                .rewarded(.max1),  .rewarded(.max2),
                .rewarded(.kwai1), .rewarded(.kwai2),
                .rewarded(.bigo1), .rewarded(.bigo2)
            ]
        case .interstitial:
            return [
                .inserted(.max1),  .inserted(.max2),
                .inserted(.kwai1), .inserted(.kwai2),
                .inserted(.bigo1), .inserted(.bigo2)
            ]
        }
    }
}

// MARK: - 竞价会话
@MainActor
class BiddingSession {
    
    // MARK: -
    let id: String = UUID().uuidString
    let type: BiddingType
    let startTime: Date = Date()
    
    var state: BiddingState = .idle
    var winnerResult: BiddingResult?
    var isFromCache: Bool = false
    
    // MARK: -
    let resultCollector = ConcurrentResultCollector()
    
    // MARK: -
    init(type: BiddingType) {
        self.type = type
    }
    
    // MARK: -
    var duration: TimeInterval {
        return Date().timeIntervalSince(startTime)
    }
    
    // MARK: -
    /// 获取所有结果（异步，线程安全）
    var results: [BiddingResult] {
        get async {
            return await resultCollector.getAllResults()
        }
    }
    
    /// 获取成功结果数量（异步）
    var successCount: Int {
        get async {
            let allResults = await resultCollector.getAllResults()
            return allResults.filter { $0.isValid }.count
        }
    }
    
    /// 获取会话描述（异步）
    var description: String {
        get async {
            let successCount = await self.successCount
            let resultCount = await resultCollector.getResultCount()
            return "[BiddingSession] ID: \(id.prefix(8)), Type: \(type.description), State: \(state.description), Duration: \(String(format: "%.2f", duration))s, Results: \(successCount)/\(resultCount), Cache: \(isFromCache)"
        }
    }
    
    /// 添加单个结果（异步，线程安全）
    func addResult(_ result: BiddingResult) async {
        await resultCollector.addResult(result)
    }
    
    /// 批量添加结果（异步，线程安全）
    func addResults(_ results: [BiddingResult]) async {
        await resultCollector.addResults(results)
    }
    
    /// 获取有效结果（异步，线程安全）
    func getValidResults() async -> [BiddingResult] {
        let allResults = await resultCollector.getAllResults()
        return allResults.filter { $0.isValid }
    }
    
    /// 无效化指定广告样式的结果（异步，线程安全）
    func invalidateResult(for adStyle: AdStyle) async {
        await resultCollector.invalidateResult(for: adStyle)
    }
    
}

// MARK: - 并发安全的结果收集器
actor ConcurrentResultCollector {
    
    // MARK: -
    private var results: [BiddingResult] = []
    
    // MARK: -
    /// 添加单个结果
    func addResult(_ result: BiddingResult) {
        results.append(result)
    }
    
    /// 批量添加结果
    func addResults(_ newResults: [BiddingResult]) {
        results.append(contentsOf: newResults)
    }
    
    /// 获取所有结果
    func getAllResults() -> [BiddingResult] {
        return results
    }
    
    /// 获取结果数量
    func getResultCount() -> Int {
        return results.count
    }
    
    /// 无效化指定广告样式的结果
    func invalidateResult(for adStyle: AdStyle) {
        if let index = results.firstIndex(where: { $0.adStyle == adStyle }) {
            results[index].invalidate()
        }
    }
    
}
