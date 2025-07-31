//
//  LinkTask.swift
//  GameWrapper
//
//  Created by arvin on 2025/5/30.
//

import Foundation
import CoreData

// MARK: -
extension LinkTask: CoreDataEntity {
    static var name: String { "LinkTask" }
}

@objc(LinkTask)
internal class LinkTask: NSManagedObject {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
    }
    
    public override func awakeFromFetch() {
        super.awakeFromFetch()
    }
    
}

internal extension LinkTask {
    /// 广告ID
    @NSManaged var id: String?
    /// 展示下一条点击的广告的间隔（秒）
    @NSManaged var nextAdGap: Int16
    /// 该链接的任务类型
    @NSManaged var taskType: Int16
    /// 广告类型
    @NSManaged var adType: String?
    /// 链接地址
    @NSManaged var link: String?
    /// 广告服务商
    @NSManaged var name: String?
    /// 检测广告的 JS 代码
    @NSManaged var adJs: String?
    /// 兜底广告区域
    @NSManaged var area: String?
    /// 开始滑动时间(秒)
    @NSManaged var startSlideTime: Float
    /// 点击功能区存活时间(秒)
    @NSManaged var clickFuncTime: Int16
    /// 层级加载间隔(秒)（下发多条链接，各链接加载间隔时间）
    @NSManaged var levelGapTime: Int16
    /// 点击广告存活时间(秒)
    @NSManaged var clickAdTime: Int16
    /// 开始点击时间(秒)
    @NSManaged var startClick: Int16
    /// 不点击存活时间(秒)
    @NSManaged var sleepTime: Int16
    
    var type: TaskType {
        set { taskType = newValue.rawValue }
        get {
            TaskType(
                rawValue: taskType
            ) ?? .show
        }
    }
}

// MARK: -
internal extension LinkTask {
    
    @discardableResult
    static func create(from config: H5ConfigModel) -> [LinkTask] {
        guard let cfg = config.cfg else { return [] }
        do {
            let manager = CoreDataManager.shared
            try manager.deleteAll(LinkTask.self)
            
            let dataList = cfg.compactMapValues { $0 }
                .flatMap { provider, cfgConfig in
                    cfgConfig.data.map { linkData in
                        (
                            provider: provider,
                            linkData: linkData,
                            adJs: cfgConfig.js
                        )
                    }
                }
                .shuffled()
            
            var tasks: [LinkTask] = []
            for (provider, linkData, adJs) in dataList {
                let task = manager.create(LinkTask.self)
                task.id = linkData.id
                task.startSlideTime = linkData._startSlideTime
                task.clickFuncTime = linkData._clickFuncTime
                task.levelGapTime = linkData._levelGapTime
                task.clickAdTime = linkData._clickAdTime
                task.startClick = linkData._startClick
                task.sleepTime = linkData._sleepTime
                task.nextAdGap = linkData._nextAdGap
                task.type = linkData._taskType
                task.adType = linkData.type
                task.link = linkData.link
                task.area = linkData.zone
                task.name = provider
                task.adJs = adJs
                tasks.append(task)
            }
            
            try manager.save()
            print("[CoreData] ✅ 已保存 \(tasks.count) 个任务到数据库")
//            tasks.forEach {
//                print("[CoreData]   - id: \($0.id ?? "nil")")
//                print("[CoreData]   - startSlideTime: \($0.startSlideTime)")
//                print("[CoreData]   - clickFuncTime: \($0.clickFuncTime)")
//                print("[CoreData]   - levelGapTime: \($0.levelGapTime)")
//                print("[CoreData]   - clickAdTime: \($0.clickAdTime)")
//                print("[CoreData]   - startClick: \($0.startClick)")
//                print("[CoreData]   - sleepTime: \($0.sleepTime)")
//                print("[CoreData]   - nextAdGap: \($0.nextAdGap)")
//                print("[CoreData]   - type: \($0.type)")
//                print("[CoreData]   - adType: \($0.adType ?? "nil")")
//                print("[CoreData]   - link: \($0.link ?? "nil")")
//                print("[CoreData]   - area: \($0.area ?? "nil")")
//                print("[CoreData]   - name: \($0.name ?? "nil")")
//                print("[CoreData]   - adJs: \($0.adJs ?? "nil")")
//            }
            return tasks
        } catch {
            print("[CoreData] ❌ 创建任务失败: \(error)")
            return []
        }
    }
    
    static func fetchAllTasks() -> [LinkTask] {
        do {
            let manager = CoreDataManager.shared
            return try manager.fetch(LinkTask.self)
        } catch {
            print("[CoreData] ❌ 获取所有任务失败: \(error)")
            return []
        }
    }
    
}

// MARK: -
internal extension LinkTask {
    
    /// 任务描述
    var taskDescription: String {
        let taskName = name ?? "nil"
        let link = link ?? "nil"
        
        // 优先显示任务名称，如果没有则显示ID
        if let taskId = id, !taskId.isEmpty {
            return "任务[\(taskId)] 服务商:\(taskName) 类型:\(type) link: \(link) 下一条链接展示间隔:\(nextAdGap)秒"
        } else {
            // 当没有ID时，使用链接的一部分作为标识
            return "任务[未知 ID] 服务商:\(taskName) 类型:\(type) link: \(link) 下一条链接展示间隔:\(nextAdGap)秒"
        }
    }
    
    /// 验证任务数据是否有效
    var isValid: Bool {
        guard let link = link else { return false }
        return !link.isEmpty
    }
    
}
