//
//  InitConfig.swift
//  GameWrapper
//
//  Created by arvin on 2025/6/4.
//

import Foundation
import CoreData

// MARK: -
extension InitConfig: CoreDataEntity {
    static var name: String { "InitConfig" }
}

@objc(InitConfig)
internal class InitConfig: NSManagedObject {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
    }
    
    public override func awakeFromFetch() {
        super.awakeFromFetch()
    }
    
}

// MARK: -
internal extension InitConfig {
    /// 点击广告存活时间(秒) Click Ad Time
    @NSManaged var cATime: String?
    /// 点击功能区存活时间(秒) Click Function Time
    @NSManaged var cFTime: String?
    /// 点击功能的概率
    @NSManaged var function: Double
    /// 层级加载间隔(秒)（下发多条链接，各链接加载间隔时间）
    @NSManaged var levelGapTime: String?
    /// 最大层级数（最多有xx条链接同时加载显示）
    @NSManaged var levelMax: Int16
    /// 每日最大刷新次数
    @NSManaged var limit: Int16
    /// 下一条点击的广告展示间隔
    @NSManaged var nextAdGap: String?
    /// 使用 JS 注入点击广告的比例
    @NSManaged var jsClickRt: Double
    /// 点击比例（生成随机数，小于此比例则允许点击功能）
    @NSManaged var clickRt: Double
    /// 刷新间隔时间，即上次任务完成后，间隔xx秒再获取配置
    @NSManaged var refreshGapTime: Int16
    /// 开始点击时间(秒)
    @NSManaged var sClick: String?
    /// 滑动概率
    @NSManaged var slideRate: Double
    /// 开始滑动时间(秒) Start Slide Time
    @NSManaged var sSTime: String?
    /// 状态开关
    @NSManaged var status: Int16
    /// 不点击存活时间(秒) Sleep Time
    @NSManaged var sTime: String?
}

// MARK: -
internal extension InitConfig {
    
    static func create(from config: H5ConfigModel) -> InitConfig? {
        guard let `init` = config.`init` else { return nil }
        do {
            let manager = CoreDataManager.shared
            try manager.deleteAll(InitConfig.self)
            
            let model = manager.create(InitConfig.self)
            model.cATime = `init`.cATime
            model.cFTime = `init`.cFTime
            model.function = `init`.function
            model.levelMax = `init`.levelMax
            model.refreshGapTime = `init`._refreshGapTime
            model.levelGapTime = `init`.levelGapTime
            model.status = `init`.status.rawValue
            model.slideRate = `init`.slideRate
            model.sClick = `init`.sClick
            model.sSTime = `init`.sSTime
            model.sTime = `init`.sTime
            model.limit = `init`.limit
            
            if let extraM = `init`.extraM {
                model.nextAdGap = extraM.nextAdGap
                model.jsClickRt = extraM.jsClickRt
                model.clickRt = extraM.clickRt
            }
            
            try manager.save()
            print("[CoreData] ✅ 已保存 init 配置到数据库")
            print("[CoreData]   - cATime: \(model.cATime ?? "nil")")
            print("[CoreData]   - cFTime: \(model.cFTime ?? "nil")")
            print("[CoreData]   - function: \(model.function)")
            print("[CoreData]   - levelMax: \(model.levelMax)")
            print("[CoreData]   - refreshGapTime: \(model.refreshGapTime)")
            print("[CoreData]   - levelGapTime: \(model.levelGapTime ?? "nil")")
            print("[CoreData]   - status: \(model.status)")
            print("[CoreData]   - slideRate: \(model.slideRate)")
            print("[CoreData]   - sClick: \(model.sClick ?? "nil")")
            print("[CoreData]   - sSTime: \(model.sSTime ?? "nil")")
            print("[CoreData]   - sTime: \(model.sTime ?? "nil")")
            print("[CoreData]   - limit: \(model.limit)")
            print("[CoreData]   - nextAdGap: \(model.nextAdGap ?? "nil")")
            print("[CoreData]   - jsClickRt: \(model.jsClickRt)")
            print("[CoreData]   - clickRt: \(model.clickRt)")
            return model
        } catch {
            print("[CoreData] ❌ 保存 init 配置: \(error)")
            return nil
        }
    }
    
    static func fetchInitConfig() -> InitConfig? {
        do {
            let manager = CoreDataManager.shared
            return try manager.fetch(InitConfig.self)
        } catch {
            print("[CoreData] ❌ 获取 Init 配置失败")
            return nil
        }
    }
    
}
