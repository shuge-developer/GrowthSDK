//
//  NetworkResponse.swift
//  GrowthSDK
//
//  Created by arvin on 2025/7/21.
//

import Foundation
import ObjectiveC

// MARK: -
internal class AnyAssociation<T: Any> {
    
    private let policy: objc_AssociationPolicy
    
    public init(policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC) {
        self.policy = policy
    }
    
    public subscript(obj: Any) -> T? {
        set { objc_setAssociatedObject(obj, Unmanaged.passUnretained(self).toOpaque(), newValue, policy) }
        get { return objc_getAssociatedObject(obj, Unmanaged.passUnretained(self).toOpaque()) as! T? }
    }
    
}

// MARK: -
internal extension NetworkRequest {
    
    private static let urlSessionRequestAssociation = AnyAssociation<Any>()
    
    var urlSessionRequest: Any? {
        get { return Self.urlSessionRequestAssociation[self] ?? nil }
        set { Self.urlSessionRequestAssociation[self] = newValue }
    }
    
}

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
