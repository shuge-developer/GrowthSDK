//
//  ConfigCache.swift
//  GrowthSDK
//
//  Created by arvin on 2025/1/18.
//

import Foundation

// MARK: -
internal enum CachedPath: String {
    case configs = "GrowthSDK/Configs.dat"
}

internal protocol Readable {
    static func read(at path: String) -> String?
}

// MARK: -
internal struct CacheWriter {
    static func write<T: Codable>(_ value: T, to path: CachedPath) {
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let fullPath = documents.first! + "/" + path.rawValue
        
        let dirPath = (fullPath as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dirPath, withIntermediateDirectories: true)
        
        guard let binaryData = try? JSONEncoder().encode(value) else {
            Logger.info("数据编码失败")
            return
        }
        var secureData = Data()
        secureData.append(contentsOf: [0x47, 0x52, 0x4F, 0x57, 0x54])
        secureData.append(binaryData)
        do {
            try secureData.write(to: URL(fileURLWithPath: fullPath))
            Logger.info("数据已安全保存: \(fullPath)")
        } catch {
            Logger.error("数据保存失败: \(error)")
        }
    }
}

// MARK: -
internal struct CacheReader: Readable {
    static func read(at path: String) -> String? {
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let fullPath = documents.first! + "/" + path; let url = URL(fileURLWithPath: fullPath)
        guard FileManager.default.fileExists(atPath: fullPath) else {
            return nil
        }
        guard let secureData = try? Data(contentsOf: url) else {
            return nil
        }
        let growthHeader = Data([0x47, 0x52, 0x4F, 0x57, 0x54])
        guard secureData.prefix(5) == growthHeader else {
            return nil
        }
        let binaryData = secureData.dropFirst(5)
        let json = String(data: binaryData, encoding: .utf8)
        Logger.info("数据已安全读取: \(json ?? "nil")")
        return json
    }
}

// MARK: -
@propertyWrapper
internal struct DataCached<T: Readable, V: Codable> {
    private let path: CachedPath
    private var value: V?
    
    // MARK: -
    init(path: CachedPath) {
        self.path = path
    }
    
    var wrappedValue: V? {
        mutating get {
            if let value = value {
                return value
            }
            guard let json = T.read(at: path.rawValue) else { return nil }
            guard let decodedValue = V.deserialize(from: json) else {
                return nil
            }
            value = decodedValue
            return value
        }
        set {
            value = newValue
        }
    }
}
