//
//  NetworkProvider.swift
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

// MARK: -
internal class NetworkProvider {
    
    internal static let shared = NetworkProvider()
    internal private(set) var isNetworkReachable: Bool = true
    private var networkProvider: NetworkProviderProtocol?
    private var configure: RequestConfigure?
    
    private init() {}
    
    // MARK: -
    internal func setup(_ configure: RequestConfigure) {
        self.configure = configure
        self.networkProvider = URLSessionNetworkProvider(
            configure: configure
        )
        setupNetworkMonitoring()
    }
    
    internal func setupNetworkMonitoring() {
        networkProvider?.startNetworkMonitoring { [weak self] isReachable in
            self?.isNetworkReachable = isReachable
        }
    }
    
    // MARK: -
    @discardableResult
    internal func request(url: BaseURL, method: HTTPMethod = .get, parameters: Parameters? = nil, cachePolicy: CachePolicy = .reloadIgnoringCache, complete: @escaping (Result<String, NetworkError>) -> Void) -> NetworkRequest {
        guard let networkProvider = networkProvider else {
            let request = NetworkRequest()
            DispatchQueue.main.async {
                request.handle(response: nil, error: .notInitialized)
                complete(.failure(.notInitialized))
            }
            return request
        }
        let networkRequest = networkProvider.request(url, method: method, parameters: parameters, cachePolicy: cachePolicy)
        networkRequest.success { json in
            DispatchQueue.main.async {
                complete(.success(json))
            }
        }.failure { error in
            DispatchQueue.main.async {
                complete(.failure(error))
            }
        }
        return networkRequest
    }
    
    @discardableResult
    internal func request<T: APIProvider>(api: T, parameters: Parameters? = nil, cachePolicy: CachePolicy = .reloadIgnoringCache) -> NetworkRequest {
        guard let networkProvider = networkProvider else {
            let request = NetworkRequest()
            request.handle(response: nil, error: .notInitialized)
            return request
        }
        let networkRequest = networkProvider.request(api: api, parameters: parameters, cachePolicy: cachePolicy)
        return networkRequest
    }
    
}
