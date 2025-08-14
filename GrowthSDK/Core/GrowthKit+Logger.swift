//
//  GrowthKit+Logger.swift
//  GrowthSDK
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
internal protocol GrowthSDKLogging {
    func log(_ level: LogLevel, message: String)
}

// MARK: - 默认日志实现
internal final class DefaultLogger: GrowthSDKLogging {
    static let shared = DefaultLogger()
    
    private init() {}
    
    public func log(_ level: LogLevel, message: String) {
//#if DEBUG
        let maxLength = 900
        var start = message.startIndex
        var index = 0
        while start < message.endIndex {
            let end = message.index(start, offsetBy: maxLength, limitedBy: message.endIndex) ?? message.endIndex
            let tag = "[GrowthSDK] [Part \(index)] \(level.emoji)"
            let part = String(message[start..<end])
            NSLog("%@ %@", tag, part)
            start = end
            index += 1
        }
//#endif
    }
}

// MARK: - 日志工具
internal enum Logger {
    static func debug(_ message: String) {
        GrowthKit.logger.log(.debug, message: message)
    }
    
    static func info(_ message: String) {
        GrowthKit.logger.log(.info, message: message)
    }
    
    static func warning(_ message: String) {
        GrowthKit.logger.log(.warning, message: message)
    }
    
    static func error(_ message: String) {
        GrowthKit.logger.log(.error, message: message)
    }
}
