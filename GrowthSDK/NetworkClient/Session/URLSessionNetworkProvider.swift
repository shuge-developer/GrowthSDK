//
//  URLSessionNetworkProvider.swift
//  GrowthSDK
//
//  Created by arvin on 2025/1/16.
//

import Foundation

// MARK: -
internal class URLSessionNetworkProvider: NetworkProviderProtocol {
    
    private let configure: RequestConfigure
    private let session: URLSession
    private let retryPolicy: RetryPolicy
    
    private var tasks: [String: URLSessionTaskWrapper] = [:]
    private var reachabilityManager: NetworkReachabilityManager?
    private var networkMonitorHandler: ((Bool) -> Void)?
    
    init(configure: RequestConfigure) {
        self.configure = configure
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = configure.timeout
        config.waitsForConnectivity = true
        
        self.session = URLSession(configuration: config)
        self.retryPolicy = RetryPolicy(retryLimit: configure.maxRetryCount, retryableHTTPMethods: [.post, .get])
        self.reachabilityManager = NetworkReachabilityManager()
    }
    
    // MARK: - NetworkProviderProtocol
    func startNetworkMonitoring(handler: @escaping (Bool) -> Void) {
        self.networkMonitorHandler = handler
        reachabilityManager?.startListening { isReachable in
            handler(isReachable)
        }
    }
    
    func request(_ URL: BaseURL, method: HTTPMethod = .get, parameters: Parameters?, cachePolicy: CachePolicy) -> NetworkRequest {
        let networkRequest = NetworkRequest()
        let requestWrapper = URLSessionTaskWrapper(networkRequest: networkRequest, session: session, retryPolicy: retryPolicy)
        networkRequest.urlSessionRequest = requestWrapper
        
        guard !URL.value.isEmpty else {
            networkRequest.handle(response: nil, error: .invalidURL)
            return networkRequest
        }
        
        let urlString: String = URL.value
        let params = parameters?.rawValue
        let cacheKey = urlString.cacheKey(params: params)
        let headers = HTTPHeaders(URL.customHeaders ?? [:])
        
        // Handle cache policy
        switch cachePolicy {
        case .cacheOnly:
            if let cachedResponse = getCache(for: cacheKey) {
                networkRequest.handle(response: cachedResponse, error: nil)
                return networkRequest
            } else {
                let error: NetworkError = .cacheError("No cached data available")
                networkRequest.handle(response: nil, error: error)
                return networkRequest
            }
        case .useCache:
            if let cachedResponse = getCache(for: cacheKey) {
                networkRequest.handle(response: cachedResponse, error: nil)
                return networkRequest
            }
        default:
            break
        }
        
        if configure.isLogEnabled {
            logRequest(urlString, params: params)
        }
        
        // Execute request
        requestWrapper.executeRequest(
            url: urlString,
            method: method,
            parameters: params,
            headers: headers,
            configure: configure,
            cacheKey: cacheKey,
            cachePolicy: cachePolicy
        )
        
        tasks[networkRequest.requestId] = requestWrapper
        return networkRequest
    }
    
    func request<T: APIProvider>(api: T, parameters: Parameters?, cachePolicy: CachePolicy) -> NetworkRequest {
        let networkRequest = NetworkRequest()
        let requestWrapper = URLSessionTaskWrapper(networkRequest: networkRequest, session: session, retryPolicy: retryPolicy)
        networkRequest.urlSessionRequest = requestWrapper
        
        guard !configure.baseURL.value.isEmpty else {
            networkRequest.handle(response: nil, error: .invalidURL)
            return networkRequest
        }
        
        let urlString: String = urlString(with: api)
        let params = (parameters ?? api.parameters)?.rawValue
        let cacheKey = urlString.cacheKey(params: params)
        
        var requestParams: String? = nil
        var headers: HTTPHeaders = HTTPHeaders()
        
        switch configure.baseURL {
        case .global(_):
            let (encHeaders, encryptedParams) = processEncryption(params)
            requestParams = encryptedParams
            headers = encHeaders
            
        case .custom(_, let customHeaders):
            headers = HTTPHeaders(customHeaders ?? [:])
            requestParams = params
        }
        
        // Handle cache policy
        switch cachePolicy {
        case .cacheOnly:
            if let cachedResponse = getCache(for: cacheKey) {
                networkRequest.handle(response: cachedResponse, error: nil)
                return networkRequest
            } else {
                let error: NetworkError = .cacheError("No cached data available")
                networkRequest.handle(response: nil, error: error)
                return networkRequest
            }
        case .useCache:
            if let cachedResponse = getCache(for: cacheKey) {
                networkRequest.handle(response: cachedResponse, error: nil)
                return networkRequest
            }
        default:
            break
        }
        
        if configure.isLogEnabled {
            logRequest(urlString, params: params, encryptedParams: requestParams)
        }
        
        // Execute request
        requestWrapper.executeAPIRequest(
            url: urlString,
            method: api.method,
            parameters: requestParams,
            headers: headers,
            configure: configure,
            cacheKey: cacheKey,
            cachePolicy: cachePolicy
        )
        
        tasks[networkRequest.requestId] = requestWrapper
        return networkRequest
    }
}

// MARK: -
private extension URLSessionNetworkProvider {
    
    func urlString<T: APIProvider>(with api: T) -> String {
        var urlString: String = ""
        switch configure.baseURL {
        case .global(let base):
            urlString = base + api.path
            
        case .custom(let full, _):
            urlString = full
        }
        return urlString
    }
    
    func processEncryption(_ params: String?) -> (HTTPHeaders, String?) {
        var headers = HTTPHeaders([
            "Content-Type": "application/json; charset=utf-8"
        ])
        
        if let appId = configure.headerProvider.appId, !appId.isEmpty {
            headers.add(name: "APD", value: appId)
        }
        
        let randomkey = String.randomString(length: 16)
        if let aesKey = try? randomkey.rsaEncrypt(publicKey: configure.rsaPublicKey) {
            headers.add(name: "AESKEY", value: aesKey)
        }
        
        let body = configure.headerProvider.header()
        if let head = try? body?.aesEncrypt(key: randomkey, iv: randomkey) {
            headers.add(name: "HBCONTENT", value: head)
        }
        
        if configure.isLogEnabled {
            logHeaderBody(headers: headers, body: body, key: randomkey)
        }
        
        var encryptedParams: String? = nil
        encryptedParams = try? params?.aesEncrypt(key: randomkey, iv: randomkey)
        return (headers, encryptedParams)
    }
    
    func getCache(for cacheKey: String) -> String? {
        if let cachedResponse = NetworkCacheManager.shared.getCache(
            for: cacheKey, expiration: configure.cacheTTL) {
            return cachedResponse
        }
        return nil
    }
}

// MARK: -
private extension URLSessionNetworkProvider {
    
    func logHeaderBody(headers: HTTPHeaders, body: String?, key: String) {
        Logger.info("Request randomkey: \(key)")
        Logger.info("Request Headers: \(headers.description)")
        Logger.info("Request body: \(body ?? "nil")")
    }
    
    func logRequest(_ url: String, params: Parameters?, encryptedParams: String? = nil) {
        let paramsString = params?.rawValue ?? "nil"
        let encryptedString = encryptedParams ?? "nil"
        Logger.info("Request URL: \(url)")
        Logger.info("Request Original Parameters: \(paramsString)")
        Logger.info("Request Encrypted Parameters: \(encryptedString)")
    }
}
