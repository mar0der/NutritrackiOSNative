//
//  ConsumptionLog.swift
//  NutritrackiOSNative
//
//  Created by Petar Petkov on 06/07/2025.
//

import Foundation
import SwiftData

@Model
final class ConsumptionLog {
    @Attribute(.unique) var id: String
    var userId: String?
    var type: String // "ingredient" or "dish"
    var consumedAt: Date
    var quantity: Double?
    var unit: String?
    var servings: Double?
    var ingredient: Ingredient?
    var dish: Dish?
    var createdAt: Date
    
    init(id: String = UUID().uuidString, userId: String? = nil, type: String, consumedAt: Date = Date(), quantity: Double? = nil, unit: String? = nil, servings: Double? = nil, ingredient: Ingredient? = nil, dish: Dish? = nil) {
        self.id = id
        self.userId = userId
        self.type = type
        self.consumedAt = consumedAt
        self.quantity = quantity
        self.unit = unit
        self.servings = servings
        self.ingredient = ingredient
        self.dish = dish
        self.createdAt = Date()
    }
}