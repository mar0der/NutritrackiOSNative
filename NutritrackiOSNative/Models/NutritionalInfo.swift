//
//  NutritionalInfo.swift
//  NutritrackiOSNative
//
//  Created by Petar Petkov on 06/07/2025.
//

import Foundation
import SwiftData

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