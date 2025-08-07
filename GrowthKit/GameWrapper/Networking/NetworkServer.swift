//
//  NetworkProvider.swift
//  GrowthKit
//
//  Created by arvin on 2025/5/29.
//

internal import NetworkService

// MARK: -
internal enum Api: APIProvider {
    case config
    case upload
    
    var path: String {
        switch self {
        case .config:
            return "/iap/h5/config"
        case .upload:
            return "/iap/h5/up"
        }
    }
}


// MARK: -
internal struct NetworkRequester: RequestConfigure {
    struct SDK {
        static let Config = GrowthSDK.shared.config
    }
    
    var baseURL: BaseURL {
        .global(SDK.Config!.baseUrl)
    }
    
    var rsaPublicKey: String {
        SDK.Config!.publicKey
    }
    
    var aesKey: String {
        SDK.Config!.appKey
    }
    
    var aesIV: String {
        SDK.Config!.appIv
    }
    
    var headerProvider: any HeaderConfigure {
        NetworkHeader()
    }
    
    var apiVersion: ServiceVersion {
        return .v2
    }
    
    var isLogEnabled: Bool {
        return true
    }
    
    struct NetworkHeader: HeaderConfigure {
        var packageName: String? {
            SDK.Config!.bundleName
        }
        
        var appId: String! {
            SDK.Config!.appid
        }
    }
    
}

// MARK: -
internal class NetworkServer {
    
    static let shared = NetworkServer()
    
    private let provider: NetworkProvider
    
    private init() {
        let net = NetworkProvider.shared
        net.setup(NetworkRequester())
        self.provider = net
    }
    
    @discardableResult
    static func request(_ api: Api, params: Parameters? = nil, complete: @escaping (Result<String, NetworkError>) -> Void) -> NetworkRequest {
        return NetworkServer.shared.provider.request(api: api, parameters: params)
            .success { complete(.success($0)) }
            .failure { complete(.failure($0)) }
    }
    
    // MARK: -
    static func performConfigRequest(for keys: String, complete: @escaping (Bool) -> Void) {
        print("[net] 🚀 开始配置请求: \(keys)")
        NetworkServer.request(.config, params: ["keys": keys]) { result in
            switch result {
            case .success(let json):
                let model = H5ConfigModel.deserialize(from: json)
                print("[net] ✅ H5配置请求成功: \(model.toJSONString() ?? "nil")")
                if let model, !model.isEmpty {
                    TaskService.shared.saveTasks(from: model)
                    TaskPloysManager.shared.record(for: keys)
                    print("[net] 📝 配置数据已保存并记录请求历史")
                    complete(true)
                } else {
                    print("[net] 📝 配置数据解析失败或者为空")
                    complete(false)
                }
            case .failure(let error):
                print("[net] ❌ H5配置请求失败: \(error)")
                complete(false)
            }
        }
    }
    
    static func uploadH5Params(_ params: String?) {
        print("[H5] [Upload] 数据上报，params: \(params ?? "nil")")
        NetworkServer.request(.upload, params: params) { result in
            switch result {
            case .success(let json):
                print("[net] ✅ 数据上报成功：\(json)")
            case .failure(let error):
                let errMsg = error.localizedDescription
                print("[net] ❌ 数据上报失败：\(errMsg)")
            }
        }
    }
    
}
