//
//  CoreDataManager.swift
// GameWrapper
//
//  Created by arvin on 2025/5/30.
//

import Foundation
import CoreData
import Combine

// MARK: - CoreData错误类型
internal enum CoreDataError: Error, LocalizedError {
    case initializationFailed(String)
    case saveError(String)
    case fetchError(String)
    case deleteError(String)
    case migrationError(String)
    
    var errorDescription: String? {
        switch self {
        case .initializationFailed(let message):
            return "CoreData初始化失败: \(message)"
        case .saveError(let message):
            return "保存数据失败: \(message)"
        case .fetchError(let message):
            return "查询数据失败: \(message)"
        case .deleteError(let message):
            return "删除数据失败: \(message)"
        case .migrationError(let message):
            return "数据迁移失败: \(message)"
        }
    }
}

// MARK: - CoreData实体协议
internal protocol CoreDataEntity: NSManagedObject {
    static var name: String { get }
}

// MARK: - CoreData管理器
internal final class CoreDataManager: ObservableObject {
    
    // MARK: -
    internal static let shared = CoreDataManager()
    
    private var isStoreLoaded = false
    
    private(set) lazy var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "SmallGame")
        configureContainer(container)
        return container
    }()
    
    var backgroundContext: NSManagedObjectContext {
        return container.newBackgroundContext()
    }
    
    var context: NSManagedObjectContext {
        return container.viewContext
    }
    
    // MARK: - 初始化
    private init() {
        setupNotifications()
    }
    
    // MARK: - 容器配置
    private func configureContainer(_ container: NSPersistentContainer) {
        guard !isStoreLoaded else {
            print("[CoreData] ⚠️ 持久化存储已加载，跳过重复加载")
            return
        }
        guard let storeDescription = container.persistentStoreDescriptions.first else {
            fatalError("未找到持久化存储描述")
        }
        // 启用轻量级迁移
        storeDescription.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        storeDescription.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        // 设置存储类型
        storeDescription.type = NSSQLiteStoreType
        // 加载持久化存储
        container.loadPersistentStores { [weak self] storeDescription, error in
            guard let error = error else {
                let name = storeDescription.url?.lastPathComponent ?? "未知"
                print("[CoreData] ✅ 持久化存储加载成功: \(name)")
                self?.configureContext(container.viewContext)
                self?.isStoreLoaded = true
                return
            }
            self?.handleStoreLoadError(error)
        }
    }
    
    // MARK: - 上下文配置
    private func configureContext(_ context: NSManagedObjectContext) {
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.undoManager = nil // 设置撤销管理器（可选）
    }
    
    // MARK: - 错误处理
    private func handleStoreLoadError(_ error: Error) {
        print("[CoreData] ❌ 存储加载失败: \(error)")
        if let storeURL = container.persistentStoreDescriptions.first?.url {
            try? FileManager.default.removeItem(at: storeURL)
            
            print("[CoreData] 🗑️ 已删除损坏的存储文件，尝试重新创建")
            container.loadPersistentStores { _, error in
                if let error = error {
                    fatalError("CoreData重新初始化失败: \(error)")
                }
            }
        }
    }
    
    // MARK: - 通知设置
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contextDidSave),
            name: .NSManagedObjectContextDidSave,
            object: nil
        )
    }
    
    @objc private func contextDidSave(_ notification: Notification) {
        let object = notification.object as? NSManagedObjectContext
        guard let context = object, context !== self.context else {
            return
        }
        DispatchQueue.main.async { [weak self] in
            self?.context.mergeChanges(
                fromContextDidSave: notification
            )
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}

// MARK: - CRUD操作
internal extension CoreDataManager {
    
    /// 保存上下文
    func save() throws {
        guard context.hasChanges else { return }
        if Thread.isMainThread {
            do {
                try context.save()
                print("[CoreData] ✅ 数据保存成功")
            } catch {
                print("[CoreData] ❌ 保存失败: \(error)")
                throw CoreDataError.saveError(
                    error.localizedDescription
                )
            }
        } else {
            DispatchQueue.main.sync {
                do {
                    try context.save()
                    print("[CoreData] ✅ 数据保存成功")
                } catch {
                    print("[CoreData] ❌ 保存失败: \(error)")
                }
            }
        }
    }
    
    /// 创建实体
    func create<T: CoreDataEntity>(_ entity: T.Type) -> T {
        return T(context: context)
    }
    
    /// 批量创建实体
    func createBatch<T: CoreDataEntity>(_ entity: T.Type, count: Int) -> [T] {
        return (0..<count).map { _ in
            T(context: context)
        }
    }
    
    /// 查询实体
    func fetch<T: CoreDataEntity>(_ entity: T.Type, config: FetchConfig = .default) throws -> [T] {
        let request = NSFetchRequest<T>(entityName: entity.name)
        request.sortDescriptors = config.sortDescriptors
        request.predicate = config.predicate
        if config.limit > 0 {
            request.fetchLimit = config.limit
        }
        do {
            return try context.fetch(request)
        } catch {
            print("[CoreData] ❌ 查询失败: \(error)")
            throw CoreDataError.fetchError(
                error.localizedDescription
            )
        }
    }
    
    /// 查询单个实体
    func fetch<T: CoreDataEntity>(_ entity: T.Type, predicate: NSPredicate? = nil) throws -> T? {
        let config = FetchConfig(predicate: predicate)
        let list = try fetch(entity, config: config)
        return list.first
    }
    
    /// 查询数量
    func count<T: CoreDataEntity>(_ entity: T.Type, predicate: NSPredicate? = nil) throws -> Int {
        let request = NSFetchRequest<T>(entityName: entity.name)
        request.predicate = predicate
        do {
            return try context.count(for: request)
        } catch {
            print("[CoreData] ❌ 计数失败: \(error)")
            throw CoreDataError.fetchError(
                error.localizedDescription
            )
        }
    }
    
    /// 检查实体是否存在
    func exists<T: CoreDataEntity>(_ entity: T.Type, predicate: NSPredicate? = nil) -> Bool {
        do {
            return try count(entity, predicate: predicate) > 0
        } catch {
            return false
        }
    }
    
    /// 批量删除
    func deleteAll<T: CoreDataEntity>(_ entity: T.Type, predicate: NSPredicate? = nil) throws {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entity.name)
        request.predicate = predicate
        
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        deleteRequest.resultType = .resultTypeObjectIDs
        do {
            let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
            let objectIDArray = result?.result as? [NSManagedObjectID] ?? []
            let changes = [NSDeletedObjectsKey: objectIDArray]
            
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
            print("[CoreData] ✅ 批量删除成功，删除了 \(objectIDArray.count) 个对象")
        } catch {
            print("[CoreData] ❌ 批量删除失败: \(error)")
            throw CoreDataError.deleteError(
                error.localizedDescription
            )
        }
    }
    
    /// 删除实体
    func delete<T: CoreDataEntity>(_ entity: T) {
        context.delete(entity)
    }
    
}

// MARK: - 异步操作
internal extension CoreDataManager {
    
    /// 执行后台操作
    func performBackgroundTask<T>(_ operation: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            container.performBackgroundTask { context in
                do {
                    let result = try operation(context)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// 批量操作
    func performBatchOperation(_ operation: @escaping (NSManagedObjectContext) throws -> Void) async throws {
        _ = try await performBackgroundTask { context in
            try operation(context)
            try context.save()
        }
    }
    
}

// MARK: - 数据库维护
internal extension CoreDataManager {
    
    /// 获取数据库文件大小
    func getDatabaseSize() -> String {
        guard let storeURL = container.persistentStoreDescriptions.first?.url else {
            return "未知"
        }
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: storeURL.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            return ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
        } catch {
            return "获取失败"
        }
    }
    
    /// 重置数据库
    func resetDatabase() throws {
        guard let storeURL = container.persistentStoreDescriptions.first?.url else {
            throw CoreDataError.deleteError("未找到数据库文件")
        }
        do {
            try container.persistentStoreCoordinator.destroyPersistentStore(
                at: storeURL, ofType: NSSQLiteStoreType, options: nil
            )
            try FileManager.default.removeItem(at: storeURL)
            container.loadPersistentStores { _, error in
                if let error = error {
                    print("[CoreData] ❌ 重置后重新加载失败: \(error)")
                }
            }
            print("[CoreData] 🔄 数据库重置完成")
        } catch {
            let msg = error.localizedDescription
            throw CoreDataError.deleteError(
                "重置数据库失败: \(msg)"
            )
        }
    }
    
    /// 清理数据库
    func cleanup() throws {
        try save()
        context.refreshAllObjects()
        print("[CoreData] 🧹 数据库清理完成")
    }
    
}

// MARK: -
internal struct FetchConfig {
    var predicate: NSPredicate?
    var sortDescriptors: [NSSortDescriptor]?
    var limit: Int = 0
    
    static var `default`: FetchConfig {
        return FetchConfig()
    }
}
