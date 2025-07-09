//
//  Constants.swift
//  NutritrackiOSNative
//
//  Created by Petar Petkov on 06/07/2025.
//

import Foundation

struct Constants {
    
    // MARK: - API Configuration
    struct API {
        static let baseURL = "https://api.nerdstips.com/v1"
        static let timeoutInterval: TimeInterval = 30.0
    }
    
    // MARK: - Categories
    struct Categories {
        static let all = ["All", "Vegetables", "Fruits", "Grains", "Proteins", "Dairy", "Oils", "Spices", "Other"]
        
        static func iconForCategory(_ category: String) -> String {
            switch category.lowercased() {
            case "vegetables": return "🥕"
            case "fruits": return "🍎"
            case "grains": return "🌾"
            case "proteins": return "🥩"
            case "dairy": return "🥛"
            case "oils": return "🫒"
            case "spices": return "🌶️"
            default: return "🥄"
            }
        }
    }
    
    // MARK: - Units
    struct Units {
        static let all = ["g", "kg", "ml", "l", "cup", "tbsp", "tsp", "piece", "slice", "serving"]
    }
    
    // MARK: - Recommendations
    struct Recommendations {
        static let dayOptions = [3, 7, 14, 30]
        static let defaultLimit = 10
    }
    
    // MARK: - Nutrition
    struct Nutrition {
        static let targetWeeklyVariety = 20.0
        static let nutritionPer100g = 100.0
    }
    
    // MARK: - UI
    struct UI {
        static let cardCornerRadius: CGFloat = 12
        static let chipCornerRadius: CGFloat = 16
        static let standardPadding: CGFloat = 16
        static let standardSpacing: CGFloat = 8
    }
}