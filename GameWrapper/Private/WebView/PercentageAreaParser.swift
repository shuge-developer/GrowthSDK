//
//  PercentageAreaParser.swift
// GameWrapper
//
//  Created by arvin on 2025/6/13.
//

import Foundation

// MARK: - 百分比区域解析器
/// 解析百分比格式的区域字符串
/// 格式: [minX%,minY%,maxX%,maxY%]
/// 例如: [0%,20%,100%,50%] 表示从屏幕左上角(0%,20%)到右下角(100%,50%)的矩形区域
internal class PercentageAreaParser {
    
    /// 解析百分比格式的区域字符串
    /// - Parameters:
    ///   - percentageString: 百分比格式的区域字符串，如 "[0%,20%,100%,50%]"
    ///   - screenSize: 屏幕尺寸
    /// - Returns: 解析后的广告区域，如果解析失败则返回nil
    static func parseArea(from percentageString: String, screenSize: CGSize) -> AdArea? {
        // 去除括号和空格
        var cleanString = percentageString.trimmingCharacters(in: .whitespacesAndNewlines)
        cleanString = cleanString.replacingOccurrences(of: "[", with: "")
        cleanString = cleanString.replacingOccurrences(of: "]", with: "")
        
        // 分割成数组
        let components = cleanString.components(separatedBy: ",")
        
        // 验证格式
        guard components.count == 4 else {
            print("[H5] [PercentageAreaParser] ❌ 格式错误: 需要4个值，实际有\(components.count)个")
            return nil
        }
        
        // 解析每个百分比值
        var percentages: [CGFloat] = []
        
        for (index, component) in components.enumerated() {
            var value = component.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 移除百分号
            if value.hasSuffix("%") {
                value = String(value.dropLast())
            }
            
            // 转换为浮点数
            guard let percentage = Float(value) else {
                print("[H5] [PercentageAreaParser] ❌ 无法解析百分比值: \(component)")
                return nil
            }
            
            // 转换为0-1范围的小数
            let normalizedPercentage = CGFloat(percentage / 100.0)
            percentages.append(normalizedPercentage)
            
            print("[H5] [PercentageAreaParser] 解析第\(index)个值: \(component) -> \(normalizedPercentage)")
        }
        
        // 计算实际像素值
        let minX = percentages[0] * screenSize.width
        let minY = percentages[1] * screenSize.height
        let maxX = percentages[2] * screenSize.width
        let maxY = percentages[3] * screenSize.height
        
        // 计算宽度和高度
        let width = maxX - minX
        let height = maxY - minY
        
        // 验证区域有效性
        guard width > 0 && height > 0 else {
            print("[H5] [PercentageAreaParser] ❌ 无效的区域尺寸: 宽度=\(width), 高度=\(height)")
            return nil
        }
        
        print("[H5] [PercentageAreaParser] ✅ 解析成功: [\(minX), \(minY), \(width), \(height)]")
        
        // 创建并返回广告区域
        return AdArea(left: minX, top: minY, width: width, height: height)
    }
}
