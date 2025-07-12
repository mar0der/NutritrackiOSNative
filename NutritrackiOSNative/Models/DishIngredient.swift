//
//  DishIngredient.swift
//  NutritrackiOSNative
//
//  Created by Petar Petkov on 06/07/2025.
//

import Foundation
import SwiftData

@Model
final class DishIngredient {
    @Attribute(.unique) var id: String
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