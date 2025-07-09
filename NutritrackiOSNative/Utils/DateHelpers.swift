//
//  DateHelpers.swift
//  NutritrackiOSNative
//
//  Created by Petar Petkov on 06/07/2025.
//

import Foundation

struct DateHelpers {
    
    static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        return formatter
    }()
    
    static func startOfDay(for date: Date) -> Date {
        return Calendar.current.startOfDay(for: date)
    }
    
    static func endOfDay(for date: Date) -> Date {
        let startOfDay = Calendar.current.startOfDay(for: date)
        return Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
    }
    
    static func isDate(_ date1: Date, sameDayAs date2: Date) -> Bool {
        return Calendar.current.isDate(date1, inSameDayAs: date2)
    }
    
    static func daysAgo(_ days: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
    }
    
    static func weeksAgo(_ weeks: Int) -> Date {
        return Calendar.current.date(byAdding: .weekOfYear, value: -weeks, to: Date()) ?? Date()
    }
    
    static func formatToISO8601(_ date: Date) -> String {
        return iso8601Formatter.string(from: date)
    }
    
    static func parseISO8601(_ string: String) -> Date? {
        return iso8601Formatter.date(from: string)
    }
}