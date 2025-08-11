//
//  GrowthKit+Logger.swift
//  GrowthKit
//
//  Created by arvin on 2025/7/28.
//

import Foundation

// MARK: - 日志级别
internal enum LogLevel: Int {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    
    var emoji: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        }
    }
}

// MARK: - 日志协议
internal protocol GrowthKitLogging {
    func log(_ level: LogLevel, message: String)
}

// MARK: - 默认日志实现
internal final class DefaultLogger: GrowthKitLogging {
    static let shared = DefaultLogger()
    
    private init() {}
    
    public func log(_ level: LogLevel, message: String) {
        print("[GrowthKit] \(level.emoji) \(message)")
    }
}

// MARK: - 日志工具
internal enum Logger {
    static func info(_ message: String) {
        GrowthSDK.logger.log(.info, message: message)
    }
    
    static func error(_ message: String) {
        GrowthSDK.logger.log(.error, message: message)
    }
}
