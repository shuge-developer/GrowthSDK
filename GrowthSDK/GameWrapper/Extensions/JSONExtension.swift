//
//  JSONExtension.swift
//  GrowthSDK
//
//  Created by arvin on 2025/5/29.
//

import Foundation

// MARK: -
internal protocol JSONPostMapping {
    mutating func didFinishMapping()
}

// MARK: -
internal extension Array where Element: Decodable {
    
    static func deserialize(from jsonString: String?) -> [Element]? {
        guard let jsonString = jsonString, !jsonString.isEmpty else {
            print("[JSON] ❌ JSON字符串为空")
            return nil
        }
        guard let jsonData = jsonString.data(using: .utf8) else {
            print("[JSON] ❌ JSON字符串转换为Data失败")
            return nil
        }
        do {
            var results = try JSONDecoder().decode([Element].self, from: jsonData)
            for (index, result) in results.enumerated() {
                if var postMapping = result as? JSONPostMapping {
                    postMapping.didFinishMapping()
                    if let processed = postMapping as? Element {
                        results[index] = processed
                    }
                }
            }
            return results
        } catch {
            print("[JSON] ❌ 数组解析失败: \(error)")
            return nil
        }
    }
    
}

internal extension Decodable {
    
    static func deserialize(from jsonString: String?) -> Self? {
        guard let jsonString = jsonString, !jsonString.isEmpty else {
            print("[JSON] ❌ JSON字符串为空")
            return nil
        }
        guard let jsonData = jsonString.data(using: .utf8) else {
            print("[JSON] ❌ JSON字符串转换为Data失败")
            return nil
        }
        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(Self.self, from: jsonData)
            if var postMapping = result as? JSONPostMapping {
                postMapping.didFinishMapping()
                return postMapping as? Self
            }
            return result
        } catch {
            print("[JSON] ❌ 解析失败: \(error)")
            return nil
        }
    }
    
}

internal extension Encodable {
    
    func toJSONString() -> String? {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(self)
            return String(data: data, encoding: .utf8)
        } catch {
            print("[JSON] ❌ 序列化失败: \(error)")
            return nil
        }
    }
    
}
