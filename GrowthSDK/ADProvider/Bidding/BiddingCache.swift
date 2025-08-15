//
//  BiddingCache.swift
//  SmallGame
//
//  Created by arvin on 2025/6/27.
//

import Foundation

// MARK: - 缓存管理
internal class BiddingCache {
    // 按类型和广告源双重索引缓存单个广告结果
    private var cachedAds: [BiddingType: [AdStyle: BiddingResult]] = [:]
    private let config = BiddingConfig()
    
    /// 缓存单个广告结果
    func cacheAd(result: BiddingResult) {
        // 初始化类型缓存
        if cachedAds[result.adStyle.type] == nil {
            cachedAds[result.adStyle.type] = [:]
        }
        
        // 缓存广告结果
        cachedAds[result.adStyle.type]?[result.adStyle] = result
        Logger.info("[Ad] [BiddingCache] 📦 缓存单个广告: \(result.adStyle) [Revenue: \(String(format: "%.4f", result.revenue))]")
    }
    
    /// 批量缓存竞价会话中的所有有效广告
    func cacheSession(session: BiddingSession) {
        Task {
            let validResults = await session.results.filter { $0.isValid }
            Logger.info("[Ad] [BiddingCache] 📦 批量缓存竞价会话: \(session.type.description), 共 \(validResults.count) 个有效广告")
            for result in validResults {
                cacheAd(result: result)
            }
            Logger.info("[Ad] [BiddingCache] ✅ 批量缓存完成: \(session.type.description)")
        }
    }
    
    /// 获取最优可用广告（按收益排序）
    func getBestAvailableAd(type: BiddingType) -> BiddingResult? {
        guard let typeCache = cachedAds[type] else {
            return nil
        }
        
        // 获取所有有效广告并按收益排序
        let validAds = typeCache.values
            .filter { isAdValid($0) }
            .sorted { $0.revenue > $1.revenue }
        
        guard let bestAd = validAds.first else {
            Logger.info("[Ad] [BiddingCache] ❌ 没有可用的 \(type.description) 广告")
            return nil
        }
        
        Logger.info("[Ad] [BiddingCache] ✅ 获取最优广告: \(bestAd.adStyle) [Revenue: \(String(format: "%.4f", bestAd.revenue))]")
        return bestAd
    }
    
    /// 获取指定广告源的广告
    func getAd(type: BiddingType, adStyle: AdStyle) -> BiddingResult? {
        guard let result = cachedAds[type]?[adStyle] else {
            return nil
        }
        
        if isAdValid(result) {
            Logger.info("[Ad] [BiddingCache] ✅ 获取指定广告: \(adStyle)")
            return result
        } else {
            Logger.info("[Ad] [BiddingCache] ❌ 指定广告已过期: \(adStyle)")
            removeAd(type: type, adStyle: adStyle)
            return nil
        }
    }
    
    /// 移除已使用的广告
    func removeUsedAd(result: BiddingResult) {
        let type = result.adStyle.type
        let adStyle = result.adStyle
        
        if cachedAds[type]?[adStyle] != nil {
            cachedAds[type]?[adStyle] = nil
            Logger.info("[Ad] [BiddingCache] 🗑️ 移除已使用广告: \(adStyle)")
            
            // 如果该类型没有其他广告了，清空类型缓存
            if cachedAds[type]?.values.compactMap({$0}).isEmpty == true {
                cachedAds[type] = nil
                Logger.info("[Ad] [BiddingCache] 🧹 清空类型缓存: \(type.description)")
            }
        }
    }
    
    /// 移除指定广告源的广告
    func removeAd(type: BiddingType, adStyle: AdStyle) {
        if cachedAds[type]?[adStyle] != nil {
            cachedAds[type]?[adStyle] = nil
            Logger.info("[Ad] [BiddingCache] 🗑️ 移除指定广告: \(adStyle)")
        }
    }
    
    /// 获取指定类型的可用广告数量
    func getAvailableCount(type: BiddingType) -> Int {
        guard let typeCache = cachedAds[type] else {
            return 0
        }
        
        let count = typeCache.values.compactMap { result in
            return isAdValid(result) ? result : nil
        }.count
        
        return count
    }
    
    /// 获取所有可用广告列表（按收益排序）
    func getAllAvailableAds(type: BiddingType) -> [BiddingResult] {
        guard let typeCache = cachedAds[type] else {
            return []
        }
        
        return typeCache.values
            .compactMap { result in
                return isAdValid(result) ? result : nil
            }
            .sorted { $0.revenue > $1.revenue }
    }
    
    /// 检查是否需要补充广告
    func needsRefill(type: BiddingType, threshold: Int = 2) -> Bool {
        let availableCount = getAvailableCount(type: type)
        let needsRefill = availableCount < threshold
        
        if needsRefill {
            Logger.info("[Ad] [BiddingCache] ⚠️ \(type.description) 需要补充广告: 当前 \(availableCount) 个，阈值 \(threshold) 个")
        }
        
        return needsRefill
    }
    
    /// 清理过期广告
    func cleanupExpiredAds() {
        var cleanupCount = 0
        
        for (type, typeCache) in cachedAds {
            var updatedCache: [AdStyle: BiddingResult] = [:]
            
            for (adStyle, result) in typeCache {
                if isAdValid(result) {
                    updatedCache[adStyle] = result
                } else {
                    cleanupCount += 1
                    Logger.info("[Ad] [BiddingCache] 🧹 清理过期广告: \(adStyle)")
                }
            }
            
            if updatedCache.isEmpty {
                cachedAds[type] = nil
            } else {
                cachedAds[type] = updatedCache
            }
        }
        
        if cleanupCount > 0 {
            Logger.info("[Ad] [BiddingCache] ✅ 清理完成，共清理 \(cleanupCount) 个过期广告")
        }
    }
    
    /// 清理指定类型的所有缓存
    func clearType(type: BiddingType) {
        if let count = cachedAds[type]?.values.compactMap({$0}).count, count > 0 {
            cachedAds[type] = nil
            Logger.info("[Ad] [BiddingCache] 🧹 清理类型缓存: \(type.description)，共 \(count) 个广告")
        }
    }
    
    /// 清理所有缓存
    func clearAll() {
        let totalCount = cachedAds.values.flatMap { $0.values.compactMap{$0} }.count
        cachedAds.removeAll()
        Logger.info("[Ad] [BiddingCache] 🧹 清理所有缓存，共 \(totalCount) 个广告")
    }
    
    /// 获取缓存统计信息
    func getCacheStats() -> String {
        var stats: [String] = []
        
        for type in BiddingType.allCases {
            let count = getAvailableCount(type: type)
            if count > 0 {
                stats.append("\(type.description): \(count)个")
            }
        }
        
        return stats.isEmpty ? "无缓存" : stats.joined(separator: ", ")
    }
    
    // MARK: - 私有方法
    
    /// 检查广告是否有效（未过期且加载器状态正常）
    private func isAdValid(_ result: BiddingResult) -> Bool {
        // 检查基本有效性
        guard result.isValid else {
            return false
        }
        
        // 检查时间过期
        let elapsed = Date().timeIntervalSince(result.loadTime)
        if elapsed > config.cacheExpireTime {
            return false
        }
        
        // 这里可以添加更多的有效性检查，比如检查 loader 状态
        // 但需要访问 AdBiddingManager 来获取 loader，暂时先简化
        
        return true
    }
}
