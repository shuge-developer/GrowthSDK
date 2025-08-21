//
//  JSON+Extensions.swift
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
            return nil
        }
        guard let jsonData = jsonString.data(using: .utf8) else {
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
            return nil
        }
    }
    
}

internal extension Decodable {
    
    static func deserialize(from jsonString: String?) -> Self? {
        guard let jsonString = jsonString, !jsonString.isEmpty else {
            return nil
        }
        guard let jsonData = jsonString.data(using: .utf8) else {
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
            return nil
        }
    }
    
}
