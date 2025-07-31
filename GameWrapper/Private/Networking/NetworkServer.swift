//
//  NetworkProvider.swift
//  GameWrapper
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
    
    var baseURL: BaseURL {
        .global(GameWebWrapper.shared.config.baseUrl)
    }
    
    var rsaPublicKey: String {
        GameWebWrapper.shared.config.publicKey
    }
    
    var aesKey: String {
        GameWebWrapper.shared.config.appKey
    }
    
    var aesIV: String {
        GameWebWrapper.shared.config.appIv
    }
    
    var headerProvider: any HeaderConfigure {
        NetworkHeader()
    }
    
    var version: ServiceVersion {
        return .v2
    }
    
    struct NetworkHeader: HeaderConfigure {
        var packageName: String {
            GameWebWrapper.shared.config.bundleName
        }
        var appId: String! {
            GameWebWrapper.shared.config.appid
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
                if let model, !model.isEmpty {
                    print("[net] ✅ H5配置请求成功: \(model.toJSONString() ?? "nil")")
                    TaskRepository.shared.saveTasks(from: model)
                    TaskPloysManager.shared.record(for: keys)
                    print("[net] 📝 配置数据已保存并记录请求历史")
                    complete(true)
                } else {
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
                print(error.localizedDescription)
            }
        }
    }
    
}
