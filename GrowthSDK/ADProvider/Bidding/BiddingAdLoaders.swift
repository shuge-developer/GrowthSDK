//
//  BiddingAdLoaders.swift
//  SmallGame
//
//  Created by arvin on 2025/6/26.
//

import Foundation
internal import BigoADS

// MARK: - 广告加载器基类
internal protocol BiddingAdLoader: AnyObject {
    var adStyle: AdStyle { get }
    var isLoading: Bool { get }
    var isLoaded: Bool { get }
    var loadTime: Date? { get }
    
    func load(completion: @escaping (Result<AdCallback.AdSource, AdError>) -> Void)
    func show(from viewController: UIViewController?, customData: String?) -> Bool
    func cleanup()
    
    // 竞价结果通知（可选实现）
    func notifyBidWin(secondPrice: Double, secondBidder: String)
    func notifyBidLoss(firstPrice: Double, firstBidder: String, lossReason: BiddingLossReason)
    
    // 广告状态验证（可选实现）
    func isAdValid() -> Bool
}

// MARK: - BiddingAdLoader 默认实现
extension BiddingAdLoader {
    /// 默认实现：对于不支持过期检查的广告源，返回 true
    func isAdValid() -> Bool {
        return true
    }
}

// MARK: - 竞价失败原因
internal enum BiddingLossReason {
    case lowerPrice       // 价格过低（低于其他竞争者）
    case lowerThanFloor   // 低于底价
    case timeout          // 超时
    case networkError     // 网络错误
    case unknown          // 未知原因
    
    var reason: Int8 {
        switch self {
        case .lowerPrice: return 101
        case .lowerThanFloor: return 100
        case .timeout: return 2
        case .networkError: return 1
        case .unknown: return 1
        }
    }
    
    var bigoReason: BGAdLossReasonType {
        return BGAdLossReasonType(rawValue: reason) ?? .internalError
    }
    
}

// MARK: - 广告加载器工厂
internal class BiddingLoaderFactory {
    
    static func createLoader(for adStyle: AdStyle) -> BiddingAdLoader? {
        switch adStyle {
        case .rewarded(let source), .inserted(let source):
            switch source {
            case .max1, .max2:
                return MaxBiddingLoader(adStyle: adStyle)
            case .kwai1, .kwai2:
                return KwaiBiddingLoader(adStyle: adStyle)
            case .bigo1, .bigo2:
                return BigoBiddingLoader(adStyle: adStyle)
            }
        case .custom(_, let source, _):
            switch source {
            case .max1, .max2:
                return MaxBiddingLoader(adStyle: adStyle)
            case .kwai1, .kwai2:
                return KwaiBiddingLoader(adStyle: adStyle)
            case .bigo1, .bigo2:
                return BigoBiddingLoader(adStyle: adStyle)
            }
        default:
            Logger.info("[Ad] [BiddingLoaderFactory] ❌ 不支持的广告样式: \(adStyle)")
            return nil
        }
    }
}
