//
//  AlamofireProvider.swift
//  GrowthSDK
//
//  Created by arvin on 2025/7/18.
//

import Foundation

internal import Alamofire

// MARK: -
internal extension HTTPMethod {
    var alamofireMethod: Alamofire.HTTPMethod {
        switch self {
        case .get:      return .get
        case .post:     return .post
        case .put:      return .put
        case .connect:  return .connect
        case .delete:   return .delete
        case .patch:    return .patch
        case .head:     return .head
        }
    }
}
//#endif

// MARK: -
//#if canImport(Alamofire)
internal class AlamofireProvider: NetworkProviderProtocol {
    
    private let configure: RequestConfigure
    private let session: Session
    
    private var tasks: [String: NetworkRequestInternal] = [:]
    private var reachabilityManager: NetworkReachabilityManager?
    private var networkMonitorHandler: ((Bool) -> Void)?
    
    init(configure: RequestConfigure) {
        self.configure = configure
        let config = URLSessionConfiguration.af.default
        config.timeoutIntervalForRequest = configure.timeout
        config.waitsForConnectivity = true
        
        let retrier = RetryPolicy(retryLimit: configure.maxRetryCount, retryableHTTPMethods: [.post, .get])
        self.session = Session(configuration: config, interceptor: retrier)
        self.reachabilityManager = NetworkReachabilityManager()
    }
    
    // MARK: -
    func startNetworkMonitoring(handler: @escaping (Bool) -> Void) {
        self.networkMonitorHandler = handler
        reachabilityManager?.startListening { status in
            switch status {
            case .reachable:
                handler(true)
            default:
                handler(false)
            }
        }
    }
    
    func request(_ URL: BaseURL, method: HTTPMethod = .get, parameters: Parameters?, cachePolicy: CachePolicy) -> NetworkRequest {
        let networkRequest = NetworkRequest()
        let requestInternal = NetworkRequestInternal(networkRequest: networkRequest)
        networkRequest.internalRequest = requestInternal
        
        guard !URL.value.isEmpty else {
            networkRequest.handle(response: nil, error: .invalidURL)
            return networkRequest
        }
        
        let urlString: String = URL.value
        let params = parameters?.rawValue
        let cacheKey = urlString.cacheKey(params: params)
        let headers = HTTPHeaders(URL.customHeaders ?? [:])
        
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
        
        let alamofireMethod = method.alamofireMethod
        let encoder = JSONParameterEncoder.default
        let afRequest = session.request(
            urlString,
            method: alamofireMethod,
            parameters: params,
            encoder: encoder,
            headers: headers
        )
            .validate()
            .responseString { [weak self] response in
                guard let self = self else { return }
                let afResponse = NetworkRawResponse.external(response)
                requestInternal.handle(afResponse, configure: self.configure,
                                       cacheKey: cacheKey, cachePolicy: cachePolicy)
                self.tasks.removeValue(forKey: networkRequest.requestId)
            }
        
        requestInternal.alamofireRequest = afRequest
        tasks[networkRequest.requestId] = requestInternal
        return networkRequest
    }
    
    func request<T: APIProvider>(api: T, parameters: Parameters?, cachePolicy: CachePolicy) -> NetworkRequest {
        let networkRequest = NetworkRequest()
        let requestInternal = NetworkRequestInternal(networkRequest: networkRequest)
        networkRequest.internalRequest = requestInternal
        
        guard !configure.baseURL.value.isEmpty else {
            networkRequest.handle(response: nil, error: .invalidURL)
            return networkRequest
        }
        
        let urlString: String = urlString(with: api)
        let params = (parameters ?? api.parameters)?.rawValue
        let cacheKey = urlString.cacheKey(params: params)
        
        var requestParams: String? = nil
        var headers: HTTPHeaders = []
        
        switch configure.baseURL {
        case .global(_):
            let (encHeaders, encryptedParams) = processEncryption(params)
            requestParams = encryptedParams
            headers = encHeaders
            
        case .custom(_, let customHeaders):
            headers = HTTPHeaders(customHeaders ?? [:])
            requestParams = params
        }
        
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
        
        let alamofireMethod = api.method.alamofireMethod
        let encoder = JSONParameterEncoder.default
        let afRequest = session.request(
            urlString,
            method: alamofireMethod,
            parameters: requestParams,
            encoder: encoder,
            headers: headers
        )
            .validate()
            .response(configure) { [weak self] response in
                guard let self = self else { return }
                requestInternal.handle(response, configure: self.configure,
                                       cacheKey: cacheKey, cachePolicy: cachePolicy)
                self.tasks.removeValue(forKey: networkRequest.requestId)
            }
        
        requestInternal.alamofireRequest = afRequest
        tasks[networkRequest.requestId] = requestInternal
        return networkRequest
    }
    
}

// MARK: -
internal extension AlamofireProvider {
    
    private func urlString<T: APIProvider>(with api: T) -> String {
        var urlString: String = ""
        switch configure.baseURL {
        case .global(let base):
            urlString = base + api.path
            
        case .custom(let full, _):
            urlString = full
        }
        return urlString
    }
    
    private func processEncryption(_ params: String?) -> (HTTPHeaders, String?) {
        var headers = HTTPHeaders([
            .contentType("application/json; charset=utf-8")
        ])
        
        if let appId = configure.headerProvider.appId, !appId.isEmpty {
            headers.add(.init(name: "APD", value: appId))
        }
        
        let randomkey = String.randomString(length: 16)
        if let aesKey = try? randomkey.rsaEncrypt(publicKey: configure.rsaPublicKey) {
            headers.add(.init(name: "AESKEY", value: aesKey))
        }
        
        let body = configure.headerProvider.v2Header()
        if let head = try? body?.aesEncrypt(key: randomkey, iv: randomkey) {
            headers.add(.init(name: "HBCONTENT", value: head))
        }
        
        if configure.isLogEnabled {
            logHeaderBody(headers: headers, body: body, key: randomkey)
        }
        
        var encryptedParams: String? = nil
        encryptedParams = try? params?.aesEncrypt(key: randomkey, iv: randomkey)
        return (headers, encryptedParams)
    }
    
    private func getCache(for cacheKey: String) -> String? {
        if let cachedResponse = NetworkCacheManager.shared.getCache(
            for: cacheKey, expiration: configure.cacheTTL) {
            return cachedResponse
        }
        return nil
    }
    
}

// MARK: - Logging Helper
internal extension AlamofireProvider {
    
    private func logHeaderBody(headers: HTTPHeaders, body: String?, key: String) {
        Logger.info("Request randomkey: \(key)")
        Logger.info("Request Headers: \(headers.description)")
        Logger.info("Request body: \(body ?? "nil")")
    }
    
    private func logRequest(_ url: String, params: Parameters?, encryptedParams: String? = nil) {
        let paramsString = params?.rawValue ?? "nil"
        let encryptedString = encryptedParams ?? "nil"
        Logger.info("Request URL: \(url)")
        Logger.info("Request Original Parameters: \(paramsString)")
        Logger.info("Request Encrypted Parameters: \(encryptedString)")
    }
    
}
//#endif
//
//#if !canImport(Alamofire)
//// 当 Alamofire 不可用时的占位符实现
//internal class AlamofireProvider: NetworkProviderProtocol {
//    
//    init(configure: RequestConfigure) {
//        // 空实现
//    }
//    
//    func startNetworkMonitoring(handler: @escaping (Bool) -> Void) {
//        // 空实现
//    }
//    
//    func request(_ URL: BaseURL, method: HTTPMethod, parameters: Parameters?, cachePolicy: CachePolicy) -> NetworkRequest {
//        let networkRequest = NetworkRequest()
//        networkRequest.handle(response: nil, error: .networkUnavailable)
//        return networkRequest
//    }
//    
//    func request<T: APIProvider>(api: T, parameters: Parameters?, cachePolicy: CachePolicy) -> NetworkRequest {
//        let networkRequest = NetworkRequest()
//        networkRequest.handle(response: nil, error: .networkUnavailable)
//        return networkRequest
//    }
//}
//#endif
