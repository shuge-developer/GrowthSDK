//
//  H5ConfigModel.swift
//  GameWrapper
//
//  Created by arvin on 2025/5/29.
//

import Foundation

// MARK: -
internal extension Decodable {
    
    /// 从 JSON 字符串反序列化对象
    /// - Parameter jsonString: JSON 字符串
    /// - Returns: 解析后的对象，如果解析失败返回 nil
    static func deserialize(from jsonString: String?) -> Self? {
        guard let jsonString = jsonString,
              let jsonData = jsonString.data(using: .utf8) else {
            return nil
        }
        return try? JSONDecoder().decode(Self.self, from: jsonData)
    }
    
}

// MARK: -
internal extension Array where Element: Decodable {
    
    /// 从 JSON 字符串反序列化对象数组
    /// - Parameter jsonString: JSON 字符串
    /// - Returns: 解析后的对象数组，如果解析失败返回 nil
    static func deserialize(from jsonString: String?) -> [Element]? {
        guard let jsonString = jsonString,
              let jsonData = jsonString.data(using: .utf8) else {
            return nil
        }
        return try? JSONDecoder().decode([Element].self, from: jsonData)
    }
    
}

// MARK: -
internal extension Encodable {
    
    /// 将对象序列化为 JSON 字符串
    /// - Returns: JSON 字符串，如果序列化失败返回 nil
    func toJSONString() -> String? {
        guard let jsonData = try? JSONEncoder().encode(self) else {
            return nil
        }
        return String(data: jsonData, encoding: .utf8)
    }
    
    /// 将对象序列化为格式化的 JSON 字符串
    /// - Returns: 格式化的 JSON 字符串，如果序列化失败返回 nil
    func toPrettyJSONString() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let jsonData = try? encoder.encode(self) else {
            return nil
        }
        return String(data: jsonData, encoding: .utf8)
    }
    
}

// MARK: -
internal extension String {
    
    /// 从当前字符串解析为指定类型
    /// - Parameter type: 目标类型
    /// - Returns: 解析后的对象，如果解析失败返回 nil
    func deserialize<T: Decodable>(as type: T.Type) -> T? {
        return T.deserialize(from: self)
    }
    
    /// 从当前字符串解析为指定类型的数组
    /// - Parameter type: 目标类型
    /// - Returns: 解析后的对象数组，如果解析失败返回 nil
    func deserialize<T: Decodable>(as type: T.Type) -> [T]? {
        return [T].deserialize(from: self)
    }
    
}
