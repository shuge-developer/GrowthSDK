//
//  RetryPolicy.swift
//  GrowthSDK
//
//  Created by arvin on 2025/1/16.
//

import Foundation

// MARK: -
internal class RetryPolicy {
    
    private let retryLimit: UInt
    private let retryableHTTPMethods: Set<HTTPMethod>
    
    internal init(retryLimit: UInt, retryableHTTPMethods: Set<HTTPMethod>) {
        self.retryLimit = retryLimit
        self.retryableHTTPMethods = retryableHTTPMethods
    }
    
    internal func shouldRetry(method: HTTPMethod, attempt: UInt, error: Error) -> Bool {
        guard attempt < retryLimit else { return false }
        guard retryableHTTPMethods.contains(method) else {
            return false
        }
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut, .networkConnectionLost, .notConnectedToInternet:
                return true
            default:
                return false
            }
        }
        return false
    }
    
}
