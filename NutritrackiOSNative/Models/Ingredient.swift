//
//  Ingredient.swift
//  NutritrackiOSNative
//
//  Created by Petar Petkov on 06/07/2025.
//

import Foundation
import SwiftData

@Model
final class Ingredient {
    @Attribute(.unique) var id: String
    var name: String
    var category: String
    var nutritionalInfo: NutritionalInfo?
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(deleteRule: .cascade)
    var dishIngredients: [DishIngredient] = []
    
    @Relationship(deleteRule: .cascade)
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