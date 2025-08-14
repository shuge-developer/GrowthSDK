//
//  HTTPHeader.swift
//  GrowthSDK
//
//  Created by arvin on 2025/1/16.
//

import Foundation

// MARK: -
internal struct HTTPHeader {
    internal let name: String
    internal let value: String
    
    internal init(name: String, value: String) {
        self.name = name
        self.value = value
    }
    
    internal static func contentType(_ value: String) -> HTTPHeader {
        return HTTPHeader(name: "Content-Type", value: value)
    }
}

// MARK: -
internal struct HTTPHeaders {
    private var headers: [String: String] = [:]
    
    internal init(_ dictionary: [String: String] = [:]) {
        self.headers = dictionary
    }
    
    internal mutating func add(_ header: HTTPHeader) {
        headers[header.name] = header.value
    }
    
    internal mutating func add(name: String, value: String) {
        headers[name] = value
    }
    
    internal var dictionary: [String: String] {
        return headers
    }
    
    internal var description: String {
        return headers.description
    }
}
