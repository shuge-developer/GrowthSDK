//
//  H5UploadParam.swift
//  GrowthKit
//
//  Created by arvin on 2025/5/29.
//

import Foundation

// MARK: - H5UploadParam
/// H5上报接口参数模型
internal struct H5UploadParam: Codable {
    
    /// 链接地址
    let link: String
    
    /// 参数数组
    let params: [AdParam]
    
    /// 广告ID字符串
    let ids: String
    
    /// 初始化方法
    init(link: String, params: [AdParam], ids: String = "") {
        self.link = link
        self.params = params
        self.ids = ids
    }
    
    /// 转换为JSON字符串
    func toJSONString() -> String? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    // MARK: -
    static func refreshParams(_ link: String) -> String? {
        let params = [AdParam(type: 1, adType: "", id: "")]
        let param = H5UploadParam(link: link, params: params)
        return param.toJSONString()
    }
    
    static func loadParams(_ ads: [AdElement], link: String?) -> String? {
        var adParams: [AdParam?] = []
        var typeIds: [String] = []
        ads.forEach { ad in
            var typeId = ad.type.rawValue
            adParams.append(AdParam.loadParam(from: ad))
            adParams.append(AdParam.fillParam(from: ad))
            adParams.append(AdParam.showParam(from: ad))
            if !ad.id.isEmpty {
                typeId += "_\(ad.id)"
            }
            typeIds.append(typeId)
        }
        let params = adParams.compactMap { $0 }.sorted {
            $0.type < $1.type
        }
        let ids = typeIds.separator()
        if let link = link {
            let uploadParams = H5UploadParam(link: link, params: params, ids: ids)
            let json = uploadParams.toJSONString()
            return json
        }
        return nil
    }
    
    static func clickParam(_ ad: AdElement, link: String?) -> String? {
        let params = [AdParam(type: 5, adType: ad.type.rawValue, id: ad.id)]
        let param = H5UploadParam(link: link ?? "", params: params)
        return param.toJSONString()
    }
    
}

// MARK: - AdParam
/// 广告参数
internal struct AdParam: Codable {
    
    /// 类型
    let type: Int
    
    /// 广告类型
    let adType: String
    
    /// ID
    let id: String
    
    /// 初始化方法
    init(type: Int, adType: String, id: String = "") {
        self.type = type
        self.adType = adType
        self.id = id
    }
    
    // MARK: -
    static func loadParam(from ad: AdElement) -> AdParam? {
        return AdParam(type: 2, adType: ad.type.rawValue, id: ad.id)
    }
    
    static func fillParam(from ad: AdElement) -> AdParam? {
        if ad.fillStatus.isfilled {
            return AdParam(type: 3, adType: ad.type.rawValue, id: ad.id)
        } else {
            return nil
        }
    }
    
    static func showParam(from ad: AdElement) -> AdParam? {
        if ad.visible || ad.displayStatus.isVisible {
            return AdParam(type: 4, adType: ad.type.rawValue, id: ad.id)
        } else {
            return nil
        }
    }
    
}
