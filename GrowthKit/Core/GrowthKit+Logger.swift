//
//  GrowthKit+Logger.swift
//  GrowthKit
//
//  Created by arvin on 2025/7/28.
//

import Foundation

// MARK: - 日志级别
public enum LogLevel: Int {
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
public protocol GrowthKitLogging {
    func log(_ level: LogLevel, message: String)
}

// MARK: - 默认日志实现
public final class DefaultLogger: GrowthKitLogging {
    public static let shared = DefaultLogger()
    
    private init() {}
    
    public func log(_ level: LogLevel, message: String) {
        let fileName = (#file as NSString).lastPathComponent
        print("[GrowthKit] \(level.emoji) [\(fileName):\(#line)] \(message)")
    }
}

// MARK: - 日志工具
enum Logger {
    static func info(_ message: String) {
        GrowthSDK.logger.log(.info, message: message)
    }
    
    static func error(_ message: String) {
        GrowthSDK.logger.log(.error, message: message)
    }
}
