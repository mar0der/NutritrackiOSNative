//
//  Recommendation.swift
//  NutritrackiOSNative
//
//  Created by Petar Petkov on 06/07/2025.
//

import Foundation

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