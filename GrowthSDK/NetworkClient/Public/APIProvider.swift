//
//  APIProvider.swift
//  GrowthSDK
//
//  Created by arvin on 2025/7/18.
//

import Foundation

// MARK: -
internal protocol APIProvider {
    var path: String { get }
    var method: HTTPMethod { get }
    var parameters: Parameters? { get }
}

// MARK: -
internal extension APIProvider {
    
    var method: HTTPMethod {
        return .post
    }
    
    var parameters: Parameters? {
        return nil
    }
    
}

// MARK: -
internal protocol Parameters {
    var rawValue: String? { get }
}

// MARK: -
extension Dictionary: Parameters {
    internal var rawValue: String? {
        return toJsonString()
    }
}

extension Array: Parameters {
    internal var rawValue: String? {
        return toJsonString()
    }
}

extension String: Parameters {
    internal var rawValue: String? {
        return self
    }
}
