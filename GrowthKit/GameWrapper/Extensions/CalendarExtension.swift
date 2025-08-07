//
//  CalendarExtension.swift
//  GrowthKit
//
//  Created by arvin on 2025/7/30.
//

import Foundation

// MARK: -
internal extension Calendar {
    
    static func add(_ component: Calendar.Component = .day, value: Int, to date: Date = Date()) -> Date {
        return Calendar.current.date(byAdding: component, value: value, to: date) ?? Date()
    }
    
    static func day(from: Date, to: Date = Date()) -> Int {
        return Calendar.current.dateComponents([.day], from: from, to: to).day ?? 0
    }
    
}
