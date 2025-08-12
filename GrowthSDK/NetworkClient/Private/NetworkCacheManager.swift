//
//  NetworkCacheManager.swift
//  GrowthSDK
//
//  Created by arvin on 2025/7/18.
//

import Foundation

// MARK: -
internal class NetworkCacheManager {
    
    // MARK: -
    internal static let shared = NetworkCacheManager()
    
    private let cache = NSCache<NSString, CacheItem>()
    private let fileManager = FileManager.default
    private let cacheQueue = DispatchQueue(label: "com.networkclient.cache", attributes: .concurrent)
    private let cacheQueueKey = DispatchSpecificKey<Void>()
    private let cacheQueueContext: () = ()
    private var maxDiskCacheSize: Int64 = 10 * 1024 * 1024
    private let diskCachePath: String
    
    // MARK: -
    private init() {
        let cachesDirectory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
        diskCachePath = (cachesDirectory as NSString).appendingPathComponent("NetworkClientCache")
        if !fileManager.fileExists(atPath: diskCachePath) {
            try? fileManager.createDirectory(atPath: diskCachePath, withIntermediateDirectories: true)
        }
        cacheQueue.setSpecific(key: cacheQueueKey, value: cacheQueueContext)
    }
    
    // MARK: -
    private func safeSync<T>(_ block: () -> T) -> T {
        if DispatchQueue.getSpecific(key: cacheQueueKey) != nil {
            return block()
        } else {
            return cacheQueue.sync { block() }
        }
    }
    
    private func safeAsync(flags: DispatchWorkItemFlags = [], _ block: @escaping () -> Void) {
        if DispatchQueue.getSpecific(key: cacheQueueKey) != nil {
            block()
        } else {
            cacheQueue.async(flags: flags, execute: block)
        }
    }
    
    // MARK: -
    internal func setCache(_ response: String, for key: String) {
        let now = Date().timeIntervalSince1970
        let cacheItem = CacheItem(response: response, timestamp: now, lastAccessTime: now)
        safeAsync(flags: .barrier) {
            self.cache.setObject(cacheItem, forKey: key as NSString)
        }
        safeAsync {
            let filePath = (self.diskCachePath as NSString).appendingPathComponent(key)
            if let data = try? NSKeyedArchiver.archivedData(withRootObject: cacheItem, requiringSecureCoding: true) {
                do {
                    try data.write(to: URL(fileURLWithPath: filePath))
                } catch {
                }
            }
            self.clearLRUCacheIfNeeded()
        }
    }
    
    internal func getCache(for key: String, expiration: TimeInterval? = nil) -> String? {
        let now = Date().timeIntervalSince1970
        let expTime = expiration ?? 300
        var cachedResponse: String?
        safeSync {
            if let cacheItem = cache.object(forKey: key as NSString), !cacheItem.isExpired(expiration: expTime) {
                cacheItem.lastAccessTime = now
                cachedResponse = cacheItem.response
            }
        }
        if cachedResponse == nil {
            var cacheItem: CacheItem?
            safeSync {
                cacheItem = self.loadCacheItem(for: key)
            }
            if let cacheItem = cacheItem, !cacheItem.isExpired(expiration: expTime) {
                cachedResponse = cacheItem.response
                cacheItem.lastAccessTime = now
                safeAsync(flags: .barrier) {
                    self.cache.setObject(cacheItem, forKey: key as NSString)
                }
                safeAsync {
                    let filePath = (self.diskCachePath as NSString).appendingPathComponent(key)
                    if let newData = try? NSKeyedArchiver.archivedData(withRootObject: cacheItem, requiringSecureCoding: false) {
                        do {
                            try newData.write(to: URL(fileURLWithPath: filePath))
                        } catch {
                            
                        }
                    }
                }
            }
        }
        return cachedResponse
    }
    
    internal func loadCacheItem(for key: String) -> CacheItem? {
        let filePath = (self.diskCachePath as NSString).appendingPathComponent(key)
        guard fileManager.fileExists(atPath: filePath) else {
            return nil
        }
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
            let allowedClasses: [AnyClass] = [CacheItem.self, NSString.self, NSNumber.self]
            return try NSKeyedUnarchiver.unarchivedObject(ofClasses: allowedClasses, from: data) as? CacheItem
        } catch {
            try? fileManager.removeItem(atPath: filePath)
            return nil
        }
    }
    
    internal func safeLoadCacheItem(for key: String) -> CacheItem? {
        return safeSync { loadCacheItem(for: key) }
    }
    
    internal func setMaxDiskCacheSize(_ size: Int64) {
        safeAsync(flags: .barrier) {
            self.maxDiskCacheSize = size
            self.clearLRUCacheIfNeeded()
        }
    }
    
    internal func currentDiskCacheSize() -> Int64 {
        var total: Int64 = 0
        safeSync {
            if let fileNames = try? self.fileManager.contentsOfDirectory(atPath: self.diskCachePath) {
                for fileName in fileNames {
                    let filePath = (self.diskCachePath as NSString).appendingPathComponent(fileName)
                    if let attrs = try? self.fileManager.attributesOfItem(atPath: filePath),
                       let fileSize = attrs[.size] as? NSNumber {
                        total += fileSize.int64Value
                    }
                }
            }
        }
        return total
    }
    
    // MARK: -
    internal func clearLRUCacheIfNeeded() {
        safeAsync(flags: .barrier) {
            var total = self.currentDiskCacheSize()
            guard total > self.maxDiskCacheSize else { return }
            var items: [(path: String, lastAccess: TimeInterval, size: Int64)] = []
            if let fileNames = try? self.fileManager.contentsOfDirectory(atPath: self.diskCachePath) {
                for fileName in fileNames {
                    let filePath = (self.diskCachePath as NSString).appendingPathComponent(fileName)
                    var cacheItem: CacheItem?
                    self.safeSync {
                        cacheItem = self.loadCacheItem(for: fileName)
                    }
                    if let cacheItem = cacheItem,
                       let attrs = try? self.fileManager.attributesOfItem(atPath: filePath),
                       let fileSize = attrs[.size] as? NSNumber {
                        items.append((filePath, cacheItem.lastAccessTime, fileSize.int64Value))
                    }
                }
            }
            items.sort { $0.lastAccess < $1.lastAccess }
            for item in items {
                try? self.fileManager.removeItem(atPath: item.path)
                total -= item.size
                if total <= self.maxDiskCacheSize { break }
            }
        }
    }
    
    internal func clearExpiredCache(_ expiration: TimeInterval? = nil) {
        let expTime = expiration ?? 300
        safeAsync {
            guard let fileNames = try? self.fileManager.contentsOfDirectory(atPath: self.diskCachePath) else { return }
            for fileName in fileNames {
                var cacheItem: CacheItem?
                self.safeSync {
                    cacheItem = self.loadCacheItem(for: fileName)
                }
                if let cacheItem = cacheItem, cacheItem.isExpired(expiration: expTime) {
                    let filePath = (self.diskCachePath as NSString).appendingPathComponent(fileName)
                    try? self.fileManager.removeItem(atPath: filePath)
                }
            }
        }
    }
    
    internal func removeCache(_ key: String) {
        safeAsync(flags: .barrier) {
            self.cache.removeObject(forKey: key as NSString)
            let filePath = (self.diskCachePath as NSString).appendingPathComponent(key)
            try? self.fileManager.removeItem(atPath: filePath)
        }
    }
    
    internal func clearAllCache() {
        safeAsync(flags: .barrier) {
            self.cache.removeAllObjects()
            try? self.fileManager.removeItem(atPath: self.diskCachePath)
            try? self.fileManager.createDirectory(
                atPath: self.diskCachePath, withIntermediateDirectories: true
            )
        }
    }
    
}

// MARK: -
@objc(NetworkCacheItem)
internal class CacheItem: NSObject, NSSecureCoding {
    
    let response: String
    let timestamp: TimeInterval
    @objc dynamic var lastAccessTime: TimeInterval
    
    var cacheDate: String {
        let cacheDate = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: cacheDate)
    }
    
    static var supportsSecureCoding: Bool {
        return true
    }
    
    // MARK: -
    init(response: String, timestamp: TimeInterval, lastAccessTime: TimeInterval) {
        self.response = response
        self.timestamp = timestamp
        self.lastAccessTime = lastAccessTime
    }
    
    func isExpired(expiration: TimeInterval) -> Bool {
        let currentTime = Date().timeIntervalSince1970
        return currentTime - timestamp > expiration
    }
    
    // MARK: -
    func encode(with coder: NSCoder) {
        coder.encode(response, forKey: "response")
        coder.encode(timestamp, forKey: "timestamp")
        coder.encode(lastAccessTime, forKey: "lastAccessTime")
    }
    
    required init?(coder: NSCoder) {
        response = coder.decodeObject(forKey: "response") as? String ?? ""
        timestamp = coder.decodeDouble(forKey: "timestamp")
        lastAccessTime = coder.decodeDouble(forKey: "lastAccessTime")
    }
    
}

// MARK: -
internal extension String {
    
    func cacheKey(params: Parameters?) -> String {
        var key = self
        if let params = params?.rawValue {
            key += "-" + params
        }
        return key.md5String()
    }
    
}
