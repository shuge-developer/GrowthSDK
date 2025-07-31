//
//  ColorExtension.swift
//  GameWrapper
//
//  Created by arvin on 2025/7/31.
//

import SwiftUI
import UIKit

// MARK: -
extension Color {
    
    static func random(using generator: inout RandomNumberGenerator, opacity: Double) -> Color {
        let red   = Double.random(in: 0..<1, using: &generator)
        let green = Double.random(in: 0..<1, using: &generator)
        let blue  = Double.random(in: 0..<1, using: &generator)
        return Color(red: red, green: green, blue: blue, opacity: opacity)
    }
    
    static func random(_ opacity: Double = 1) -> Color {
        var generator: RandomNumberGenerator = SystemRandomNumberGenerator()
        return random(using: &generator, opacity: opacity)
    }
    
    static var random: Color {
        return random(1)
    }
    
}

// MARK: -
extension Color {
    
    public init(hex: String, _ opacity: Double = 1) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (r, g, b) = (int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (1, 1, 0)
        }
        self.init(
            .sRGB,
            red:   Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: opacity
        )
    }
    
}

// MARK: -
extension ShapeStyle where Self == Color {
    
    static func hex(_ hex: String, _ opacity: Double = 1) -> Color {
        Color(hex: hex, opacity)
    }
    
}

// MARK: -
extension UIColor {
    
    func opacity(_ opacity: CGFloat) -> UIColor {
        withAlphaComponent(opacity)
    }
    
}
