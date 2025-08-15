//
//  AdDisplayManager.swift
//  SmallGame
//
//  Created by AI Assistant on 2025/7/2.
//

import Foundation
import UIKit

// MARK: -
@MainActor
internal class AdDisplayManager: ObservableObject {
    
    static let shared = AdDisplayManager()
    
    // MARK: -
    private var lastClickTime: Date = Date(timeIntervalSince1970: 0)
    private let clickProtectionInterval: TimeInterval = 1.0
    @Published var isShowingAd: Bool = false
    
    var hasAdShowing: Bool {
        return isShowingAd
    }
    
    // MARK: -
    func canShowAd() -> Bool {
        if isShowingAd {
            Logger.info("[Ad] [AdDisplayManager] ❌ 已有广告正在展示")
            return false
        }
        let now = Date()
        let timeSinceLastClick = now.timeIntervalSince(lastClickTime)
        if timeSinceLastClick < clickProtectionInterval {
            Logger.info("[Ad] [AdDisplayManager] ❌ 快速点击保护，间隔: \(String(format: "%.2f", timeSinceLastClick))s")
            return false
        }
        return true
    }
    
    func markAdStarted() {
        lastClickTime = Date()
        isShowingAd = true
        Logger.info("[Ad] [AdDisplayManager] 📱 标记广告开始展示")
    }
    
    func markAdClosed() {
        isShowingAd = false
        Logger.info("[Ad] [AdDisplayManager] 📱 标记广告关闭")
    }
    
    func markAdFailed() {
        isShowingAd = false
        Logger.info("[Ad] [AdDisplayManager] 📱 标记广告失败")
    }
    
    func forceReset() {
        lastClickTime = Date(timeIntervalSince1970: 0)
        isShowingAd = false
        Logger.info("[Ad] [AdDisplayManager] 📱 强制重置广告状态")
    }
    
}

// MARK: -
@MainActor internal func canShowAd() -> Bool {
    return AdDisplayManager.shared.canShowAd()
}

@MainActor internal func markAdStarted() {
    AdDisplayManager.shared.markAdStarted()
}

@MainActor internal func markAdClosed() {
    AdDisplayManager.shared.markAdClosed()
}

@MainActor internal func markAdFailed() {
    AdDisplayManager.shared.markAdFailed()
}

@MainActor internal func checkAndStartAd() -> Bool {
    guard canShowAd() else {
        return false
    }
    markAdStarted()
    return true
}
