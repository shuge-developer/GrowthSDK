//
//  URLSessionTaskWrapper.swift
//  GrowthSDK
//
//  Created by arvin on 2025/1/16.
//

import Foundation

// MARK: -
internal class URLSessionTaskWrapper {
    
    private let networkRequest: NetworkRequest
    private let session: URLSession
    private var currentTask: URLSessionDataTask?
    private let retryPolicy: RetryPolicy
    private var currentAttempt: UInt = 0
    
    internal init(networkRequest: NetworkRequest, session: URLSession, retryPolicy: RetryPolicy) {
        self.networkRequest = networkRequest
        self.session = session
        self.retryPolicy = retryPolicy
    }
    
    internal func executeRequest(
        url: String,
        method: HTTPMethod,
        parameters: String?,
        headers: HTTPHeaders,
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
        headers: HTTPHeaders,
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
        headers: HTTPHeaders,
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
}

// MARK: -
private extension URLSessionTaskWrapper {
    
    func handleError(
        error: Error,
        method: HTTPMethod,
        url: String,
        parameters: String?,
        headers: HTTPHeaders,
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
    
    func convertURLErrorToNetworkError(_ error: Error) -> NetworkError {
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
    
    func handleFinalError(_ error: NetworkError, configure: RequestConfigure, cacheKey: String, cachePolicy: CachePolicy) {
        if cachePolicy == .reloadFallingBackToCache, let cachedResponse = getCache(for: cacheKey, configure: configure) {
            networkRequest.handle(response: cachedResponse, error: nil)
        } else {
            networkRequest.handle(response: nil, error: error)
        }
    }
}

// MARK: -
private extension URLSessionTaskWrapper {
    
    func handleBusinessResponse(data: Data, configure: RequestConfigure, cacheKey: String, cachePolicy: CachePolicy) {
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
    
    func handleExternalResponse(data: Data, configure: RequestConfigure, cacheKey: String, cachePolicy: CachePolicy) {
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
}

// MARK: -
private extension URLSessionTaskWrapper {
    
    func getCache(for cacheKey: String, configure: RequestConfigure) -> String? {
        if let cachedResponse = NetworkCacheManager.shared.getCache(
            for: cacheKey, expiration: configure.cacheTTL) {
            return cachedResponse
        }
        return nil
    }
}
