//
//  NetworkRequestExtension.swift
//  GrowthSDK
//
//  Created by arvin on 2025/7/18.
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
    
    // Keep old association for backward compatibility but deprecated
    private static let requestAssociation = AnyAssociation<Any>()
    private static let urlSessionRequestAssociation = AnyAssociation<Any>()
    
    // DEPRECATED: Use urlSessionRequest instead
    var internalRequest: Any? {
        get { return Self.requestAssociation[self] ?? nil }
        set { Self.requestAssociation[self] = newValue }
    }
    
    // New URLSession-based request handler
    var urlSessionRequest: Any? {
        get { return Self.urlSessionRequestAssociation[self] ?? nil }
        set { Self.urlSessionRequestAssociation[self] = newValue }
    }
    
}
