//
//  AlamofireProvider.swift
//  GrowthSDK
//
//  Created by arvin on 2025/7/18.
//

import Foundation

// REFACTORED: Now uses URLSession instead of Alamofire
// But keeps the same interface for compatibility
import Foundation
import Network

#if false && canImport(Alamofire)
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

// MARK: -
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
#endif

// MARK: - NEW URLSession Implementation
// This replaces the Alamofire implementation above

// MARK: - URLSession HTTP Headers
internal struct URLSessionHeaders {
    private var headers: [String: String] = [:]
    
    internal init(_ dictionary: [String: String] = [:]) {
        self.headers = dictionary
    }
    
    internal mutating func add(_ header: URLSessionHeader) {
        headers[header.name] = header.value
    }
    
    internal var dictionary: [String: String] {
        return headers
    }
    
    internal var description: String {
        return headers.description
    }
}

// MARK: - URLSession HTTP Header
internal struct URLSessionHeader {
    internal let name: String
    internal let value: String
    
    internal init(name: String, value: String) {
        self.name = name
        self.value = value
    }
    
    internal static func contentType(_ value: String) -> URLSessionHeader {
        return URLSessionHeader(name: "Content-Type", value: value)
    }
}

// MARK: - URLSession Retry Policy
internal class URLSessionRetryPolicy {
    private let retryLimit: UInt
    private let retryableHTTPMethods: Set<HTTPMethod>
    
    internal init(retryLimit: UInt, retryableHTTPMethods: Set<HTTPMethod>) {
        self.retryLimit = retryLimit
        self.retryableHTTPMethods = retryableHTTPMethods
    }
    
    internal func shouldRetry(method: HTTPMethod, attempt: UInt, error: Error) -> Bool {
        guard attempt < retryLimit else { return false }
        guard retryableHTTPMethods.contains(method) else { return false }
        
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

// MARK: - URLSession Network Reachability Manager
internal class URLSessionReachabilityManager {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "URLSessionReachabilityManager")
    private var statusHandler: ((Bool) -> Void)?
    
    internal func startListening(onUpdatePerforming listener: @escaping (Bool) -> Void) {
        statusHandler = listener
        
        monitor.pathUpdateHandler = { [weak self] path in
            let isReachable = path.status == .satisfied
            DispatchQueue.main.async {
                self?.statusHandler?(isReachable)
            }
        }
        
        monitor.start(queue: queue)
    }
    
    internal func stopListening() {
        monitor.cancel()
        statusHandler = nil
    }
}

// MARK: - AlamofireProvider (URLSession Implementation)
internal class AlamofireProvider: NetworkProviderProtocol {
    
    private let configure: RequestConfigure
    private let session: URLSession
    private let retryPolicy: URLSessionRetryPolicy
    
    private var tasks: [String: URLSessionTaskWrapper] = [:]
    private var reachabilityManager: URLSessionReachabilityManager?
    private var networkMonitorHandler: ((Bool) -> Void)?
    
    init(configure: RequestConfigure) {
        self.configure = configure
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = configure.timeout
        config.waitsForConnectivity = true
        
        self.session = URLSession(configuration: config)
        self.retryPolicy = URLSessionRetryPolicy(retryLimit: configure.maxRetryCount, retryableHTTPMethods: [.post, .get])
        self.reachabilityManager = URLSessionReachabilityManager()
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
        networkRequest.internalRequest = requestWrapper
        
        guard !URL.value.isEmpty else {
            networkRequest.handle(response: nil, error: .invalidURL)
            return networkRequest
        }
        
        let urlString: String = URL.value
        let params = parameters?.rawValue
        let cacheKey = urlString.cacheKey(params: params)
        let headers = URLSessionHeaders(URL.customHeaders ?? [:])
        
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
        networkRequest.internalRequest = requestWrapper
        
        guard !configure.baseURL.value.isEmpty else {
            networkRequest.handle(response: nil, error: .invalidURL)
            return networkRequest
        }
        
        let urlString: String = urlString(with: api)
        let params = (parameters ?? api.parameters)?.rawValue
        let cacheKey = urlString.cacheKey(params: params)
        
        var requestParams: String? = nil
        var headers: URLSessionHeaders = URLSessionHeaders()
        
        switch configure.baseURL {
        case .global(_):
            let (encHeaders, encryptedParams) = processEncryption(params)
            requestParams = encryptedParams
            headers = encHeaders
            
        case .custom(_, let customHeaders):
            headers = URLSessionHeaders(customHeaders ?? [:])
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

// MARK: - AlamofireProvider Extensions (URLSession Implementation)
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
    
    private func processEncryption(_ params: String?) -> (URLSessionHeaders, String?) {
        var headers = URLSessionHeaders([
            "Content-Type": "application/json; charset=utf-8"
        ])
        
        if let appId = configure.headerProvider.appId, !appId.isEmpty {
            headers.add(URLSessionHeader(name: "APD", value: appId))
        }
        
        let randomkey = String.randomString(length: 16)
        if let aesKey = try? randomkey.rsaEncrypt(publicKey: configure.rsaPublicKey) {
            headers.add(URLSessionHeader(name: "AESKEY", value: aesKey))
        }
        
        let body = configure.headerProvider.v2Header()
        if let head = try? body?.aesEncrypt(key: randomkey, iv: randomkey) {
            headers.add(URLSessionHeader(name: "HBCONTENT", value: head))
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

// MARK: - Logging Helper (URLSession Implementation)
internal extension AlamofireProvider {
    
    private func logHeaderBody(headers: URLSessionHeaders, body: String?, key: String) {
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

// MARK: - URLSession Task Wrapper
internal class URLSessionTaskWrapper {
    
    private let networkRequest: NetworkRequest
    private let session: URLSession
    private let retryPolicy: URLSessionRetryPolicy
    private var currentTask: URLSessionDataTask?
    private var currentAttempt: UInt = 0
    
    internal init(networkRequest: NetworkRequest, session: URLSession, retryPolicy: URLSessionRetryPolicy) {
        self.networkRequest = networkRequest
        self.session = session
        self.retryPolicy = retryPolicy
    }
    
    internal func executeRequest(
        url: String,
        method: HTTPMethod,
        parameters: String?,
        headers: URLSessionHeaders,
        configure: RequestConfigure,
        cacheKey: String,
        cachePolicy: CachePolicy
    ) {
        performRequest(
            url: url,
            method: method,
            parameters: parameters,
            headers: headers,
            configure: configure,
            cacheKey: cacheKey,
            cachePolicy: cachePolicy,
            isAPIRequest: false
        )
    }
    
    internal func executeAPIRequest(
        url: String,
        method: HTTPMethod,
        parameters: String?,
        headers: URLSessionHeaders,
        configure: RequestConfigure,
        cacheKey: String,
        cachePolicy: CachePolicy
    ) {
        performRequest(
            url: url,
            method: method,
            parameters: parameters,
            headers: headers,
            configure: configure,
            cacheKey: cacheKey,
            cachePolicy: cachePolicy,
            isAPIRequest: true
        )
    }
    
    private func performRequest(
        url: String,
        method: HTTPMethod,
        parameters: String?,
        headers: URLSessionHeaders,
        configure: RequestConfigure,
        cacheKey: String,
        cachePolicy: CachePolicy,
        isAPIRequest: Bool
    ) {
        guard let requestURL = URL(string: url) else {
            networkRequest.handle(response: nil, error: .invalidURL)
            return
        }
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = method.rawValue
        
        // Set headers
        for (key, value) in headers.dictionary {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Set body for POST/PUT/PATCH requests
        if let parameters = parameters, !parameters.isEmpty {
            if method == .post || method == .put || method == .patch {
                request.httpBody = parameters.data(using: .utf8)
            }
        }
        
        currentTask = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                self.handleError(
                    error: error,
                    method: method,
                    url: url,
                    parameters: parameters,
                    headers: headers,
                    configure: configure,
                    cacheKey: cacheKey,
                    cachePolicy: cachePolicy,
                    isAPIRequest: isAPIRequest
                )
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                self.networkRequest.handle(response: nil, error: .requestFailed(-1, "Invalid response"))
                return
            }
            
            // Validate status code
            guard 200..<300 ~= httpResponse.statusCode else {
                let errorMessage = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                let networkError = NetworkError.requestFailed(httpResponse.statusCode, errorMessage)
                self.handleFinalError(networkError, configure: configure, cacheKey: cacheKey, cachePolicy: cachePolicy)
                return
            }
            
            guard let data = data else {
                self.networkRequest.handle(response: nil, error: .noData)
                return
            }
            
            if isAPIRequest && !configure.isCustomURL {
                self.handleBusinessResponse(data: data, configure: configure, cacheKey: cacheKey, cachePolicy: cachePolicy)
            } else {
                self.handleExternalResponse(data: data, configure: configure, cacheKey: cacheKey, cachePolicy: cachePolicy)
            }
        }
        
        currentTask?.resume()
    }
    
    private func handleError(
        error: Error,
        method: HTTPMethod,
        url: String,
        parameters: String?,
        headers: URLSessionHeaders,
        configure: RequestConfigure,
        cacheKey: String,
        cachePolicy: CachePolicy,
        isAPIRequest: Bool
    ) {
        let networkError = convertURLErrorToNetworkError(error)
        
        // Check if we should retry
        if retryPolicy.shouldRetry(method: method, attempt: currentAttempt, error: error) {
            currentAttempt += 1
            
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(currentAttempt)) { [weak self] in
                self?.performRequest(
                    url: url,
                    method: method,
                    parameters: parameters,
                    headers: headers,
                    configure: configure,
                    cacheKey: cacheKey,
                    cachePolicy: cachePolicy,
                    isAPIRequest: isAPIRequest
                )
            }
        } else {
            handleFinalError(networkError, configure: configure, cacheKey: cacheKey, cachePolicy: cachePolicy)
        }
    }
    
    private func handleBusinessResponse(data: Data, configure: RequestConfigure, cacheKey: String, cachePolicy: CachePolicy) {
        guard let model = NetworkResponse.decode(from: data) else {
            networkRequest.handle(response: nil, error: .decodeError)
            return
        }
        
        guard model.code == 200 else {
            let error: NetworkError = .resposeError(model.code, model.msg)
            networkRequest.handle(response: nil, error: error)
            return
        }
        
        guard let data = model.data, !data.isEmpty else {
            networkRequest.handle(response: nil, error: .noData)
            return
        }
        
        do {
            let key = configure.aesKey; let iv = configure.aesIV
            let decrypt = try data.aesDecrypt(key: key, iv: iv)
            let json = decrypt.clearEndZeroString()
            
            if configure.isCacheEnabled {
                NetworkCacheManager.shared.setCache(json, for: cacheKey)
            }
            
            if configure.isLogEnabled {
                Logger.info("Response: \(json)")
            }
            
            networkRequest.handle(response: json, error: nil)
        } catch {
            let networkError: NetworkError
            if let decryptError = error as? NetworkError {
                networkError = decryptError
            } else {
                networkError = .decryptionError(error.localizedDescription)
            }
            
            if configure.isLogEnabled {
                Logger.error("Error: \(networkError.description)")
            }
            
            handleFinalError(networkError, configure: configure, cacheKey: cacheKey, cachePolicy: cachePolicy)
        }
    }
    
    private func handleExternalResponse(data: Data, configure: RequestConfigure, cacheKey: String, cachePolicy: CachePolicy) {
        guard let json = String(data: data, encoding: .utf8), !json.isEmpty else {
            networkRequest.handle(response: nil, error: .noData)
            return
        }
        
        if configure.isCacheEnabled {
            NetworkCacheManager.shared.setCache(json, for: cacheKey)
        }
        
        if configure.isLogEnabled {
            Logger.info("Response: \(json)")
        }
        
        networkRequest.handle(response: json, error: nil)
    }
    
    private func handleFinalError(_ error: NetworkError, configure: RequestConfigure, cacheKey: String, cachePolicy: CachePolicy) {
        if cachePolicy == .reloadFallingBackToCache, let cachedResponse = getCache(for: cacheKey, configure: configure) {
            networkRequest.handle(response: cachedResponse, error: nil)
        } else {
            networkRequest.handle(response: nil, error: error)
        }
    }
    
    private func convertURLErrorToNetworkError(_ error: Error) -> NetworkError {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut:
                return .timeout
            case .notConnectedToInternet, .networkConnectionLost:
                return .networkUnavailable
            case .cancelled:
                return .cancelled
            default:
                return .requestFailed(urlError.code.rawValue, urlError.localizedDescription)
            }
        } else {
            return .requestFailed(-1, error.localizedDescription)
        }
    }
    
    private func getCache(for cacheKey: String, configure: RequestConfigure) -> String? {
        if let cachedResponse = NetworkCacheManager.shared.getCache(
            for: cacheKey, expiration: configure.cacheTTL) {
            return cachedResponse
        }
        return nil
    }
}
