//
//  Transformable.swift
//  GrowthSDK
//
//  Created by arvin on 2025/8/15.
//

import Foundation

internal protocol Transformable: Codable {}

internal extension Transformable {
    
    func toDictionary() -> [String: Any]? {
        var dict: [String: Any]? = nil
        do {
            let data = try JSONEncoder().encode(self)
            let json = try JSONSerialization.jsonObject(
                with: data, options: .allowFragments
            )
            dict = json as? [String: Any]
        } catch {
            return nil
        }
        return dict
    }
    
    func toJsonString() -> String? {
        do {
            let data = try JSONEncoder().encode(self)
            let json = String(data: data, encoding: .utf8)
            return json
        } catch {
            return nil
        }
    }
    
}
