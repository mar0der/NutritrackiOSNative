//
//  Dish.swift
//  NutritrackiOSNative
//
//  Created by Petar Petkov on 06/07/2025.
//

import Foundation
import SwiftData

@Model
final class Dish {
    @Attribute(.unique) var id: String
    var name: String
    var dishDescription: String?
    var instructions: String?
    var servings: Int
    var userId: String?
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(deleteRule: .cascade)
    var dishIngredients: [DishIngredient] = []
    
    @Relationship(deleteRule: .cascade)
    var consumptionLogs: [ConsumptionLog] = []
    
    init(id: String = UUID().uuidString, name: String, description: String? = nil, instructions: String? = nil, servings: Int = 1, userId: String? = nil) {
        self.id = id
        self.name = name
        self.dishDescription = description
        self.instructions = instructions
        self.servings = servings
        self.userId = userId
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}