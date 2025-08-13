//
//  DataRequestExtension.swift
//  GrowthSDK
//
//  Created by arvin on 2025/7/22.
//

import Foundation

//#if canImport(Alamofire)
internal import Alamofire
//#endif

//#if canImport(Alamofire)
// MARK: -
internal enum NetworkRawResponse {
    case business(AFDataResponse<NetworkResponse>)
    case external(AFDataResponse<String>)
}

internal extension DataRequest {
    
    func response(_ configure: RequestConfigure, completion: @escaping (NetworkRawResponse) -> Void) -> Self {
        if !configure.isCustomURL {
            return self.responseDecodable(of: NetworkResponse.self) {
                completion(.business($0))
            }
        } else {
            return self.responseString {
                completion(.external($0))
            }
        }
    }
    
}
//#else
//// 当 Alamofire 不可用时的占位符定义
//internal enum NetworkRawResponse {
//    case business(Any)
//    case external(Any)
//}
//#endif
