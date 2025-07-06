//
//  NutritionModels.swift
//  NutritrackiOSNative
//
//  Created by Petar Petkov on 06/07/2025.
//

import Foundation
import SwiftData

// MARK: - Nutritional Information
@Model
final class NutritionalInfo {
    var calories: Double?
    var protein: Double?
    var carbs: Double?
    var fat: Double?
    var fiber: Double?
    var sodium: Double?
    
    init(calories: Double? = nil, protein: Double? = nil, carbs: Double? = nil, fat: Double? = nil, fiber: Double? = nil, sodium: Double? = nil) {
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.sodium = sodium
    }
}

// MARK: - Ingredient
@Model
final class Ingredient {
    var id: String
    var name: String
    var category: String
    var nutritionalInfo: NutritionalInfo?
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \DishIngredient.ingredient)
    var dishIngredients: [DishIngredient] = []
    
    @Relationship(deleteRule: .cascade, inverse: \ConsumptionLog.ingredient)
    var consumptionLogs: [ConsumptionLog] = []
    
    init(id: String = UUID().uuidString, name: String, category: String, nutritionalInfo: NutritionalInfo? = nil) {
        self.id = id
        self.name = name
        self.category = category
        self.nutritionalInfo = nutritionalInfo
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Dish Ingredient (Junction Table)
@Model
final class DishIngredient {
    var id: String
    var dish: Dish?
    var ingredient: Ingredient?
    var quantity: Double
    var unit: String
    
    init(id: String = UUID().uuidString, dish: Dish? = nil, ingredient: Ingredient? = nil, quantity: Double, unit: String) {
        self.id = id
        self.dish = dish
        self.ingredient = ingredient
        self.quantity = quantity
        self.unit = unit
    }
}

// MARK: - Dish
@Model
final class Dish {
    var id: String
    var name: String
    var dishDescription: String?
    var instructions: String?
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \DishIngredient.dish)
    var dishIngredients: [DishIngredient] = []
    
    @Relationship(deleteRule: .cascade, inverse: \ConsumptionLog.dish)
    var consumptionLogs: [ConsumptionLog] = []
    
    init(id: String = UUID().uuidString, name: String, description: String? = nil, instructions: String? = nil) {
        self.id = id
        self.name = name
        self.dishDescription = description
        self.instructions = instructions
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Consumption Log
@Model
final class ConsumptionLog {
    var id: String
    var consumedAt: Date
    var quantity: Double
    var unit: String?
    var ingredient: Ingredient?
    var dish: Dish?
    var createdAt: Date
    
    init(id: String = UUID().uuidString, consumedAt: Date = Date(), quantity: Double, unit: String? = nil, ingredient: Ingredient? = nil, dish: Dish? = nil) {
        self.id = id
        self.consumedAt = consumedAt
        self.quantity = quantity
        self.unit = unit
        self.ingredient = ingredient
        self.dish = dish
        self.createdAt = Date()
    }
}

// MARK: - Recommendation (Read-only from API)
struct Recommendation: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let instructions: String?
    let dishIngredients: [RecommendationIngredient]
    let freshnessScore: Double
    let recentIngredients: Int
    let totalIngredients: Int
    let reason: String
}

struct RecommendationIngredient: Codable, Identifiable {
    let id: String
    let ingredient: RecommendationIngredientDetail
    let quantity: Double
    let unit: String
}

struct RecommendationIngredientDetail: Codable, Identifiable {
    let id: String
    let name: String
    let category: String
}
