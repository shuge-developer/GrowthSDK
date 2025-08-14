//
//  NetworkProviderProtocol.swift
//  GrowthSDK
//
//  Created by arvin on 2025/7/18.
//

import Foundation

// MARK: -
internal protocol NetworkProviderProtocol {
    func startNetworkMonitoring(handler: @escaping (Bool) -> Void)
    func request(_ URL: BaseURL, method: HTTPMethod, parameters: Parameters?, cachePolicy: CachePolicy) -> NetworkRequest
    func request<T: APIProvider>(api: T, parameters: Parameters?, cachePolicy: CachePolicy) -> NetworkRequest
}
