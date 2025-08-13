//
//  NetworkRequestInternal.swift
//  GrowthSDK
//
//  Created by arvin on 2025/7/18.
//

import Foundation

//#if canImport(Alamofire)
internal import Alamofire
//#endif

//#if canImport(Alamofire)
// MARK: -
internal class NetworkRequestInternal {
    
    internal let networkRequest: NetworkRequest
    internal var alamofireRequest: Alamofire.Request?
    internal init(networkRequest: NetworkRequest) {
        self.networkRequest = networkRequest
    }
    
    // MARK: -
    internal func handle(_ response: NetworkRawResponse, configure: RequestConfigure, cacheKey: String, cachePolicy: CachePolicy) {
        switch response {
        case .business(let aFDataResponse):
            switch aFDataResponse.result {
            case .success(let model):
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
                        logResponse(json)
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
                        logError(networkError)
                    }
                    handle(networkError, configure: configure, cacheKey: cacheKey, cachePolicy: cachePolicy)
                }
            case .failure(let error):
                failure(error, configure: configure, cacheKey: cacheKey, cachePolicy: cachePolicy)
            }
            
        case .external(let aFDataResponse):
            switch aFDataResponse.result {
            case .success(let json):
                if json.isEmpty {
                    networkRequest.handle(response: nil, error: .noData)
                    return
                }
                if configure.isCacheEnabled {
                    NetworkCacheManager.shared.setCache(json, for: cacheKey)
                }
                if configure.isLogEnabled {
                    logResponse(json)
                }
                networkRequest.handle(response: json, error: nil)
                
            case .failure(let error):
                failure(error, configure: configure, cacheKey: cacheKey, cachePolicy: cachePolicy)
            }
        }
    }
    
}

// MARK: -
internal extension NetworkRequestInternal {
    
    // MARK: -
    private func convertAFErrorToNetworkError(_ error: AFError) -> NetworkError {
        if error.isResponseSerializationError {
            return .decodeError
            
        } else if error.isSessionTaskError {
            if let urlError = error.underlyingError as? URLError {
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
                return .requestFailed(error.responseCode ?? -1, error.errorDescription)
            }
        } else {
            return .requestFailed(error.responseCode ?? -1, error.errorDescription)
        }
    }
    
    private func failure(_ error: AFError, configure: RequestConfigure, cacheKey: String, cachePolicy: CachePolicy) {
        let networkError = convertAFErrorToNetworkError(error)
        if configure.isLogEnabled {
            logError(networkError)
        }
        handle(networkError, configure: configure, cacheKey: cacheKey, cachePolicy: cachePolicy)
    }
    
    private func handle(_ error: NetworkError, configure: RequestConfigure, cacheKey: String, cachePolicy: CachePolicy) {
        if cachePolicy == .reloadFallingBackToCache, let cachedResponse = getCache(for: cacheKey, configure: configure) {
            networkRequest.handle(response: cachedResponse, error: nil)
        } else {
            networkRequest.handle(response: nil, error: error)
        }
    }
    
    // MARK: -
    private func getCache(for cacheKey: String, configure: RequestConfigure) -> String? {
        if let cachedResponse = NetworkCacheManager.shared.getCache(
            for: cacheKey, expiration: configure.cacheTTL) {
            return cachedResponse
        }
        return nil
    }
    
}

// MARK: - Logging Helper
internal extension NetworkRequestInternal {
    
    private func logResponse(_ response: String) {
        Logger.info("Response: \(response)")
    }
    
    private func logError(_ error: NetworkError) {
        Logger.error("Error: \(error.description)")
    }
    
}
//#endif
//
//#if !canImport(Alamofire)
//// 当 Alamofire 不可用时的占位符实现
//internal class NetworkRequestInternal {
//    
//    internal let networkRequest: NetworkRequest
//    internal init(networkRequest: NetworkRequest) {
//        self.networkRequest = networkRequest
//    }
//    
//    internal func handle(_ response: NetworkRawResponse, configure: RequestConfigure, cacheKey: String, cachePolicy: CachePolicy) {
//        // 空实现
//    }
//}
//#endif
