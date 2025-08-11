//
//  TaskService.swift
//  GrowthSDK
//
//  Created by arvin on 2025/5/30.
//

import Foundation
import CoreData
import Combine

// MARK: - 任务服务
internal final class TaskService: ObservableObject {
    
    internal static let shared = TaskService()
    
    private let dataStore = DataStore.shared
    
    private var lastTaskCompletionTime: Date?
    
    internal private(set) var isInitialized: Bool = false
    
    /// 所有Web任务（包含所有类型）
    @Published var webTasks: [LinkTask] = []
    
    /// 多层WebView容器任务（层级0）
    /// 包含：展示、滑动、功能点击、滑动+功能点击
    @Published var multiLayerTasks: [LinkTask] = []
    
    /// 单层WebView容器任务（层级1）
    /// 包含：广告点击、滑动+广告点击
    @Published var adClickTasks: [LinkTask] = []
    
    @Published var initConfig: InitConfig?
    @Published var jsConfig: JSConfig?
    
    private init() {
        print("[Repository] 初始化任务仓库")
    }
    
    // MARK: - 任务加载与分类
    /// 加载所有任务并按类型分类
    func loadTasks() {
        // 避免重复加载
        guard !isInitialized else {
            print("[Repository] 任务已加载，跳过重复加载")
            return
        }
        isInitialized = true
        
        webTasks = LinkTask.fetchAllTasks()
        initConfig = InitConfig.fetchInitConfig()
        jsConfig = JSConfig.fetchJSConfig()
        
        // 分类任务
        classifyTasks()
        
        print("[Repository] 已加载 \(webTasks.count) 个任务")
        print("[Repository] - 多层WebView任务: \(multiLayerTasks.count) 个")
        print("[Repository] - 广告点击任务: \(adClickTasks.count) 个")
        print("[Repository] 已加载 \(initConfig != nil ? "有效" : "无效") Init 配置")
        print("[Repository] 已加载 \(jsConfig != nil ? "有效" : "无效") JS 配置")
    }
    
    /// 分类任务到不同队列
    private func classifyTasks() {
        guard !webTasks.isEmpty else {
            multiLayerTasks.removeAll()
            adClickTasks.removeAll()
            return
        }
        print("[Repository] 分类任务到不同队列")
        
#warning("先注释掉，主要用来测试多层 webView 的数据处理以及调试")
        // 多层WebView容器任务类型：展示、滑动、功能点击、滑动+功能点击
        multiLayerTasks = webTasks.filter { task in
            switch task.type {
            case .show, .move, .fClick, .mFClick:
                return true
            default:
                return false
            }
        }
        
        // 单层WebView容器任务类型：广告点击、滑动+广告点击
        adClickTasks = webTasks.filter { task in
            switch task.type {
            case .aClick, .mAClick:
                return true
            default:
                return false
            }
        }
        
        //multiLayerTasks = webTasks
        //adClickTasks = webTasks
        
        print("[Repository] 📊 任务分类完成:")
        print("[Repository] - 多层容器任务: \(multiLayerTasks.count) 个")
        print("[Repository] - 广告点击任务: \(adClickTasks.count) 个")
    }
    
    /// 保存H5配置任务
    func saveTasks(from config: H5ConfigModel) {
        webTasks = LinkTask.create(from: config)
        
        // 分类任务
        classifyTasks()
        
        print("[Repository] 已保存 \(webTasks.count) 个新任务")
        print("[Repository] - 多层WebView任务: \(multiLayerTasks.count) 个")
        print("[Repository] - 广告点击任务: \(adClickTasks.count) 个")
        
        if let initConfig = InitConfig.create(from: config) {
            print("[Repository] 已保存 Init 配置 \(initConfig)")
            self.initConfig = initConfig
        }
        if let jsConfig = JSConfig.create(from: config) {
            print("[Repository] 已保存 JS 配置 \(jsConfig)")
            self.jsConfig = jsConfig
        }
    }
    
    /// 根据ID查找任务
    func fetchTask(byID id: String) -> LinkTask? {
        do {
            let predicate = NSPredicate(format: "id == %@", id)
            return try dataStore.fetch(
                LinkTask.self, predicate: predicate
            )
        } catch {
            print("[CoreData] ❌ 查找任务失败: \(error)")
            return nil
        }
    }
    
    /// 根据服务商查找任务
    func fetchTasks(byProvider name: String) -> [LinkTask] {
        do {
            let predicate = NSPredicate(format: "name == %@", name)
            let config = FetchConfig(predicate: predicate)
            return try dataStore.fetch(
                LinkTask.self, config: config
            )
        } catch {
            print("[CoreData] ❌ 根据服务商查找任务失败: \(error)")
            return []
        }
    }
    
    /// 根据任务类型查找任务
    func fetchTasks(byTaskTypes types: [TaskType]) -> [LinkTask] {
        do {
            let typeValues = types.map { $0.rawValue }
            let predicate = NSPredicate(format: "taskType IN %@", typeValues)
            let config = FetchConfig(predicate: predicate)
            return try dataStore.fetch(
                LinkTask.self, config: config
            )
        } catch {
            print("[CoreData] ❌ 根据任务类型查找任务失败: \(error)")
            return []
        }
    }
    
    /// 删除所有任务
    func deleteAllTasks() {
        do {
            try dataStore.deleteAll(LinkTask.self)
            print("[CoreData] ✅ 已删除所有任务")
        } catch {
            print("[CoreData] ❌ 删除所有任务失败: \(error)")
        }
        webTasks.removeAll()
        multiLayerTasks.removeAll()
        adClickTasks.removeAll()
    }
    
    /// 删除单个任务
    func deleteTask(_ task: LinkTask) {
        do {
            dataStore.delete(task)
            try dataStore.save()
            
            // 从所有集合中移除
            webTasks.removeAll { $0.link == task.link }
            multiLayerTasks.removeAll { $0.link == task.link }
            adClickTasks.removeAll { $0.link == task.link }
            
            print("[Repository] ✅ 已删除任务，剩余: \(webTasks.count) 个")
        } catch {
            print("[Repository] ❌ 删除任务失败: \(error)")
        }
    }
    
    // MARK: -
    /// 记录任务完成时间
    func recordTaskCompletion() {
        lastTaskCompletionTime = Date()
        print("[Repository] ⏱️ 记录任务完成时间: \(formatDate(lastTaskCompletionTime))")
    }
    
    /// 获取最后一次任务完成时间
    func getLastTaskCompletionTime() -> Date? {
        return lastTaskCompletionTime
    }
    
    /// 格式化日期用于日志
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "未记录" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
}

// MARK: - 任务统计与获取
internal extension TaskService {
    
    /// 获取任务统计
    func getTaskStatistics() -> (total: Int, valid: Int, invalid: Int, multiLayer: Int, adClick: Int) {
        let total = webTasks.count
        let valid = webTasks.filter { $0.isValid }.count
        let invalid = total - valid
        let multiLayer = multiLayerTasks.count
        let adClick = adClickTasks.count
        return (total: total, valid: valid, invalid: invalid, multiLayer: multiLayer, adClick: adClick)
    }
    
    /// 获取有效任务
    func getValidTasks() -> [LinkTask] {
        return webTasks.filter { $0.isValid }
    }
    
    /// 获取有效的多层WebView任务
    func getValidMultiLayerTasks() -> [LinkTask] {
        return multiLayerTasks.filter { $0.isValid }
    }
    
    /// 获取有效的广告点击任务
    func getValidAdClickTasks() -> [LinkTask] {
        return adClickTasks.filter { $0.isValid }
    }
    
    /// 获取无效任务
    func getInvalidTasks() -> [LinkTask] {
        return webTasks.filter { !$0.isValid }
    }
    
    /// 获取任务数量
    func getTaskCount() -> Int {
        do {
            return try dataStore.count(LinkTask.self)
        } catch {
            print("[CoreData] ❌ 获取任务数量失败: \(error)")
            return 0
        }
    }
}

// MARK: - 便利方法
internal extension TaskService {
    
    /// 按服务商分组任务
    func groupTasksByProvider() -> [String: [LinkTask]] {
        return Dictionary(grouping: webTasks) { task in
            task.name ?? "未知服务商"
        }
    }
    
    /// 按类型分组任务
    func groupTasksByType() -> [String: [LinkTask]] {
        return Dictionary(grouping: webTasks) { task in
            task.adType ?? "未知类型"
        }
    }
    
    /// 按交互类型分组任务
    func groupTasksByInteractionType() -> [TaskType: [LinkTask]] {
        return Dictionary(grouping: webTasks) { task in
            task.type
        }
    }
    
    /// 检查是否存在指定ID的任务
    func hasTask(withID id: String) -> Bool {
        return webTasks.contains { $0.id == id }
    }
    
    /// 获取下一个可用的多层WebView任务
    func getNextAvailableMultiLayerTask() -> LinkTask? {
        let validTasks = getValidMultiLayerTasks()
        if validTasks.isEmpty {
            print("[Repository] ⚠️ 没有可用的多层WebView任务")
            return nil
        }
        let randomIndex = Int.random(in: 0..<validTasks.count)
        let selectedTask = validTasks[randomIndex]
        let task = selectedTask.taskDescription
        print("[Repository] ✅ 获取下一个任务: \(task)")
        return selectedTask
    }
    
    /// 获取下一个可用的广告点击任务
    func getNextAvailableAdClickTask() -> LinkTask? {
        return getValidAdClickTasks().first
    }
    
    /// 标记任务已完成
    func markTaskCompleted(_ task: LinkTask) {
        deleteTask(task)
    }
    
}

// MARK: - 清理数据
internal extension TaskService {
    
    /// 清理所有 CoreData 存储的数据
    func clearAllData() {
        do {
            // 删除所有 LinkTask
            try dataStore.deleteAll(LinkTask.self)
            // 删除所有 InitConfig
            try dataStore.deleteAll(InitConfig.self)
            // 删除所有 JSConfig
            try dataStore.deleteAll(JSConfig.self)
            
            // 清空内存中的数据
            webTasks.removeAll()
            multiLayerTasks.removeAll()
            adClickTasks.removeAll()
            initConfig = nil
            jsConfig = nil
            
            // 重置初始化状态
            isInitialized = false
            
            print("[Repository] ✅ 已清理所有 CoreData 数据")
        } catch {
            print("[Repository] ❌ 清理 CoreData 数据失败: \(error)")
        }
    }
    
}
