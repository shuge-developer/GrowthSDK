//
//  DataRequestExtension.swift
//  GrowthSDK
//
//  Created by arvin on 2025/7/22.
//

import Foundation
internal import Alamofire

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
