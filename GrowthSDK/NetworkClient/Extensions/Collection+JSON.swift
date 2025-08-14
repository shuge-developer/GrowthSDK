//
//  Collection+JSON.swift
//  GrowthSDK
//
//  Created by arvin on 2025/7/19.
//

import Foundation

// MARK: -
protocol JSONSerializationable {
    func toJsonString() -> String?
}

private func serializeToJson(_ obj: Any) -> String? {
    guard JSONSerialization.isValidJSONObject(obj) else { return nil }
    if let data = try? JSONSerialization.data(withJSONObject: obj, options: []) {
        if let json = String(data: data, encoding: .utf8) {
            return json
        }
    }
    return nil
}

// MARK: -
extension Dictionary: JSONSerializationable {
    internal func toJsonString() -> String? {
        return serializeToJson(self)
    }
}

// MARK: -
extension Array: JSONSerializationable {
    internal func toJsonString() -> String? {
        return serializeToJson(self)
    }
}

