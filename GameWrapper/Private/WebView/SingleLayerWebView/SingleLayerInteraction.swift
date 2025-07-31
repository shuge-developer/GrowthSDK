//
//  SingleLayerInteraction.swift
//  GameWrapper
//
//  Created by arvin on 2025/6/13.
//

import Foundation

// MARK: -
/// 单层 WebView 交互相关定义
internal enum SingleLayerInteraction {
    
    /// 交互模式
    enum Mode {
        /// 仅广告点击
        case adClickOnly
        /// 滑动后广告点击
        case scrollThenAdClick
    }
    
    /// 交互状态
    enum State: Equatable {
        /// 初始状态
        case initial
        /// 加载中
        case loading
        /// 已加载
        case loaded
        /// 滑动中
        case scrolling
        /// 重试滑动中
        case retryScrolling
        /// 检测广告中
        case detecting
        /// 点击广告中
        case clicking
        /// 完成
        case completed
        /// 失败
        case failed(Error)
        
        /// 状态的原始值，用于比较
        var rawValue: String {
            switch self {
            case .initial:        return "initial"
            case .loading:        return "loading"
            case .loaded:         return "loaded"
            case .scrolling:      return "scrolling"
            case .retryScrolling: return "retryScrolling"
            case .detecting:      return "detecting"
            case .clicking:       return "clicking"
            case .completed:      return "completed"
            case .failed:         return "failed"
            }
        }
        
        /// 实现 Equatable 协议
        static func == (lhs: SingleLayerInteraction.State, rhs: SingleLayerInteraction.State) -> Bool {
            return lhs.rawValue == rhs.rawValue
        }
    }
}

// MARK: -
internal extension Error {
    var errorCode: Int {
        return (self as NSError).code
    }
    
    var errorDomain: String {
        return (self as NSError).domain
    }
}
