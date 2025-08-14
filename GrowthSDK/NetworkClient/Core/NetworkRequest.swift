//
//  NetworkRequest.swift
//  GrowthSDK
//
//  Created by arvin on 2025/7/18.
//

import Foundation

// MARK: -
internal class NetworkRequest {
    
    internal typealias SuccessHandler = ((String) -> Void)
    internal typealias FailureHandler = ((NetworkError) -> Void)
    private var successHandler: SuccessHandler?
    private var failureHandler: FailureHandler?
    internal let requestId = UUID().uuidString
    
    internal init() {}
    
    // MARK: -
    @discardableResult
    internal func success(_ handler: @escaping SuccessHandler) -> Self {
        self.successHandler = handler
        return self
    }
    
    @discardableResult
    internal func failure(_ handler: @escaping FailureHandler) -> Self {
        self.failureHandler = handler
        return self
    }
    
    // MARK: -
    internal func handle(response: String?, error: NetworkError?) {
        DispatchQueue.main.async {
            if let json = response {
                self.successHandler?(json)
            } else if let error = error {
                self.failureHandler?(error)
            }
            self.clearHandlers()
        }
    }
    
    private func clearHandlers() {
        successHandler = nil
        failureHandler = nil
    }
    
}
