//
//  JSConfig.swift
//  GrowthSDK
//
//  Created by arvin on 2025/5/30.
//

import Foundation
import CoreData

// MARK: -
extension JSConfig: CoreDataEntity {
    static var name: String { "JSConfig" }
}

@objc(JSConfig)
internal class JSConfig: NSManagedObject {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
    }
    
    public override func awakeFromFetch() {
        super.awakeFromFetch()
    }
    
}

// MARK: -
internal extension JSConfig {
    /// 获取功能元素位置的 JS 代码
    @NSManaged var rectJs: String?
    /// 注入点击的 JS 代码
    @NSManaged var clickJs: String?
    /// 是否到底部的 JS 代码
    @NSManaged var bottomJs: String?
    /// 检查 iframe 位置的 js 代码
    @NSManaged var iframeJs: String?
    /// 执行到顶部的 JS 代码
    @NSManaged var topJs: String?
}

// MARK: -
internal extension JSConfig {
    
    @discardableResult
    static func create(from config: H5ConfigModel) -> JSConfig? {
        guard let jsM = config.jsM else { return nil }
        do {
            let manager = DataStore.shared
            try manager.deleteAll(JSConfig.self)
            
            let model = manager.create(JSConfig.self)
            model.rectJs = jsM.rectJs
            model.clickJs = jsM.clickJs
            model.bottomJs = jsM.bottomJs
            model.iframeJs = jsM.iframeJs
            model.topJs = jsM.topJs
            
            try manager.save()
            print("[CoreData] ✅ 已保存 JS 代码到数据库")
//            print("[CoreData]   - rectJs: \(model.rectJs ?? "nil")")
//            print("[CoreData]   - clickJs: \(model.clickJs ?? "nil")")
//            print("[CoreData]   - bottomJs: \(model.bottomJs ?? "nil")")
//            print("[CoreData]   - iframeJs: \(model.iframeJs ?? "nil")")
//            print("[CoreData]   - topJs: \(model.topJs ?? "nil")")
            return model
        } catch {
            print("[CoreData] ❌ 保存 JS 数据: \(error)")
            return nil
        }
    }
    
    static func fetchJSConfig() -> JSConfig? {
        do {
            let manager = DataStore.shared
            return try manager.fetch(JSConfig.self)
        } catch {
            print("[CoreData] ❌ 获取 JS 配置失败")
            return nil
        }
    }
    
}
