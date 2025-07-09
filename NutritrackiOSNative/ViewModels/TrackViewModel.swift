//
//  TrackViewModel.swift
//  NutritrackiOSNative
//
//  Created by Petar Petkov on 06/07/2025.
//

import Foundation
import SwiftData
import SwiftUI
import Combine

@MainActor
class TrackViewModel: ObservableObject {
    @Published var consumptionLogs: [APIConsumptionLog] = []
    @Published var availableIngredients: [APIIngredient] = []
    @Published var availableDishes: [APIDish] = []
    @Published var selectedDate = Date()
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService: APIService
    private let authService: AuthService
    private let healthKitManager: HealthKitManager
    
    init(apiService: APIService, authService: AuthService, healthKitManager: HealthKitManager) {
        self.apiService = apiService
        self.authService = authService
        self.healthKitManager = healthKitManager
    }
    
    var filteredLogs: [APIConsumptionLog] {
        let calendar = Calendar.current
        return consumptionLogs.filter { log in
            let logDate = ISO8601DateFormatter().date(from: log.consumedAt) ?? Date()
            return calendar.isDate(logDate, inSameDayAs: selectedDate)
        }
    }
    
    func loadData() async {
        isLoading = true
        
        async let logsTask = loadConsumptionLogs()
        async let ingredientsTask = loadIngredients()
        async let dishesTask = loadDishes()
        
        await logsTask
        await ingredientsTask
        await dishesTask
        
        isLoading = false
    }
    
    func loadConsumptionLogs() async {
        do {
            consumptionLogs = try await apiService.getConsumptionLogs(days: 30)
        } catch {
            errorMessage = "Failed to load consumption logs: \(error.localizedDescription)"
        }
    }
    
    func loadIngredients() async {
        do {
            availableIngredients = try await apiService.getIngredients()
        } catch {
            errorMessage = "Failed to load ingredients: \(error.localizedDescription)"
        }
    }
    
    func loadDishes() async {
        do {
            availableDishes = try await apiService.getDishes()
        } catch {
            errorMessage = "Failed to load dishes: \(error.localizedDescription)"
        }
    }
    
    func createConsumptionLog(_ request: CreateConsumptionLogRequest, modelContext: ModelContext) async {
        do {
            let newLog = try await apiService.logConsumption(request)
            consumptionLogs.append(newLog)
            
            // Also save to local SwiftData
            let localLog = ConsumptionLog(
                id: newLog.id,
                userId: authService.currentUser?.id,
                type: newLog.type,
                consumedAt: ISO8601DateFormatter().date(from: newLog.consumedAt) ?? Date(),
                quantity: newLog.quantity,
                unit: newLog.unit,
                servings: newLog.servings,
                ingredient: availableIngredients.first(where: { $0.id == newLog.ingredientId })?.toLocal(),
                dish: availableDishes.first(where: { $0.id == newLog.dishId })?.toLocal(userId: authService.currentUser?.id)
            )
            modelContext.insert(localLog)
            
            // Sync nutrition data to HealthKit
            await syncToHealthKit(consumptionLog: newLog)
            
        } catch {
            errorMessage = "Failed to log consumption: \(error.localizedDescription)"
        }
    }
    
    private func syncToHealthKit(consumptionLog: APIConsumptionLog) async {
        guard healthKitManager.isAuthorized else { return }
        
        let logDate = ISO8601DateFormatter().date(from: consumptionLog.consumedAt) ?? Date()
        var nutritionData: [String: Double] = [:]
        
        if let ingredient = consumptionLog.ingredient,
           let nutritionalInfo = ingredient.nutritionPer100g {
            
            // Calculate nutrition values based on quantity consumed
            let quantityMultiplier = (consumptionLog.quantity ?? 0) / 100.0
            
            if let calories = nutritionalInfo.calories {
                nutritionData["calories"] = calories * quantityMultiplier
            }
            if let protein = nutritionalInfo.protein {
                nutritionData["protein"] = protein * quantityMultiplier
            }
            if let carbs = nutritionalInfo.carbs {
                nutritionData["carbs"] = carbs * quantityMultiplier
            }
            if let fat = nutritionalInfo.fat {
                nutritionData["fat"] = fat * quantityMultiplier
            }
            if let fiber = nutritionalInfo.fiber {
                nutritionData["fiber"] = fiber * quantityMultiplier
            }
            nutritionData["sodium"] = 0
            
        } else if let dish = consumptionLog.dish {
            
            // Calculate total nutrition for dish
            var totalCalories: Double = 0
            var totalProtein: Double = 0
            var totalCarbs: Double = 0
            var totalFat: Double = 0
            var totalFiber: Double = 0
            
            for dishIngredient in dish.ingredients {
                if let nutritionalInfo = dishIngredient.ingredient.nutritionPer100g {
                    let ingredientMultiplier = dishIngredient.quantity / 100.0
                    
                    totalCalories += (nutritionalInfo.calories ?? 0) * ingredientMultiplier
                    totalProtein += (nutritionalInfo.protein ?? 0) * ingredientMultiplier
                    totalCarbs += (nutritionalInfo.carbs ?? 0) * ingredientMultiplier
                    totalFat += (nutritionalInfo.fat ?? 0) * ingredientMultiplier
                    totalFiber += (nutritionalInfo.fiber ?? 0) * ingredientMultiplier
                }
            }
            
            // Apply dish serving size
            let servingMultiplier = consumptionLog.servings ?? 1.0
            nutritionData["calories"] = totalCalories * servingMultiplier
            nutritionData["protein"] = totalProtein * servingMultiplier
            nutritionData["carbs"] = totalCarbs * servingMultiplier
            nutritionData["fat"] = totalFat * servingMultiplier
            nutritionData["fiber"] = totalFiber * servingMultiplier
            nutritionData["sodium"] = 0
        }
        
        // Save to HealthKit
        await healthKitManager.saveNutritionData(
            calories: nutritionData["calories"],
            protein: nutritionData["protein"],
            carbs: nutritionData["carbs"],
            fat: nutritionData["fat"],
            fiber: nutritionData["fiber"],
            sodium: nutritionData["sodium"],
            date: logDate
        )
    }
}