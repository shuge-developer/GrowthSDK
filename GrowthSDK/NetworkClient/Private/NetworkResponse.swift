//
//  NetworkResponse.swift
//  GrowthSDK
//
//  Created by arvin on 2025/7/21.
//

import Foundation

// MARK: -
internal class NetworkResponse: Codable {
    var code: Int = 0
    var data: String?
    var msg: String?
    
    // MARK: -
    static func decode(from data: Data) -> Self? {
        do {
            return try JSONDecoder().decode(Self.self, from: data)
        } catch {
            return nil
        }
    }
}
