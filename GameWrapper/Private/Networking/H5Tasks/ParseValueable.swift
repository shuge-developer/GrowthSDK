//
//  ParseValueable.swift
// GameWrapper
//
//  Created by arvin on 2025/6/5.
//

import Foundation

// MARK: -
internal protocol ParseableNumeric: Numeric, Comparable, LosslessStringConvertible {
    static func random(in range: ClosedRange<Self>) -> Self
    static var zero: Self { get }
}

// MARK: -
extension Int: ParseableNumeric {
    static var zero: Int { 0 }
}

extension Int16: ParseableNumeric {
    static var zero: Int16 { 0 }
}

extension Int32: ParseableNumeric {
    static var zero: Int32 { 0 }
}

extension Int64: ParseableNumeric {
    static var zero: Int64 { 0 }
}

extension Float: ParseableNumeric {
    static var zero: Float { 0.0 }
}

extension Double: ParseableNumeric {
    static var zero: Double { 0.0 }
}

// MARK: -
internal protocol ParseValueable {}
internal extension ParseValueable {
    
    /// 解析数值字符串，生成随机数值（泛型版本）
    /// - Parameter valueString: 数值字符串，格式如 "1800-2400" 或 "3600" 或 "0.5-0.8"
    /// - Returns: 随机生成的数值
    func parseRandomValue<T: ParseableNumeric>(from valueString: String?) -> T {
        guard let valueString = valueString, !valueString.isEmpty else {
            return T.zero
        }
        let values = valueString.components(separatedBy: "-").compactMap {
            T($0.trimmingCharacters(in: .whitespaces))
        }
        switch values.count {
        case 1:
            return values[0]
        case 2:
            let minValue = min(values[0], values[1])
            let maxValue = max(values[0], values[1])
            return T.random(in: minValue...maxValue)
        default:
            return T.zero
        }
    }
    
    // MARK: -
    /// 解析整数范围字符串
    /// - Parameter valueString: 整数字符串，格式如 "100-200" 或 "150"
    /// - Returns: 随机生成的整数
    func parseRandomInt(from valueString: String?) -> Int {
        return parseRandomValue(from: valueString)
    }
    
    /// 解析16位整数范围字符串
    /// - Parameter valueString: 整数字符串，格式如 "100-200" 或 "150"
    /// - Returns: 随机生成的16位整数
    func parseRandomInt16(from valueString: String?) -> Int16 {
        return parseRandomValue(from: valueString)
    }
    
    /// 解析32位整数范围字符串
    /// - Parameter valueString: 整数字符串，格式如 "100-200" 或 "150"
    /// - Returns: 随机生成的32位整数
    func parseRandomInt32(from valueString: String?) -> Int32 {
        return parseRandomValue(from: valueString)
    }
    
    /// 解析64位整数范围字符串
    /// - Parameter valueString: 整数字符串，格式如 "100-200" 或 "150"
    /// - Returns: 随机生成的64位整数
    func parseRandomInt64(from valueString: String?) -> Int64 {
        return parseRandomValue(from: valueString)
    }
    
    /// 解析浮点数范围字符串
    /// - Parameter valueString: 浮点数字符串，格式如 "0.5-0.8" 或 "0.6"
    /// - Returns: 随机生成的浮点数
    func parseRandomFloat(from valueString: String?) -> Float {
        return parseRandomValue(from: valueString)
    }
    
    /// 解析双精度浮点数范围字符串
    /// - Parameter valueString: 双精度浮点数字符串，格式如 "0.5-0.8" 或 "0.6"
    /// - Returns: 随机生成的双精度浮点数
    func parseRandomDouble(from valueString: String?) -> Double {
        return parseRandomValue(from: valueString)
    }
    
}
