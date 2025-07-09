//
//  HomeViewModel.swift
//  NutritrackiOSNative
//
//  Created by Petar Petkov on 06/07/2025.
//

import Foundation
import SwiftData
import SwiftUI
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var todaysConsumptionCount: Int = 0
    @Published var varietyScore: Double = 0.85
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let authService: AuthService
    private let apiService: APIService
    private let healthKitManager: HealthKitManager
    
    init(authService: AuthService, apiService: APIService, healthKitManager: HealthKitManager) {
        self.authService = authService
        self.apiService = apiService
        self.healthKitManager = healthKitManager
    }
    
    func calculateTodaysLogs(from consumptionLogs: [ConsumptionLog]) {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        todaysConsumptionCount = consumptionLogs.filter { log in
            log.consumedAt >= today && log.consumedAt < tomorrow
        }.count
    }
    
    func calculateVarietyScore(from consumptionLogs: [ConsumptionLog]) async {
        let lastWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date())!
        let recentLogs = consumptionLogs.filter { $0.consumedAt >= lastWeek }
        
        let uniqueIngredients = Set(recentLogs.compactMap { $0.ingredient?.id })
        let uniqueDishes = Set(recentLogs.compactMap { $0.dish?.id })
        
        let totalUniqueItems = uniqueIngredients.count + uniqueDishes.count
        let targetVariety = 20.0
        
        varietyScore = min(Double(totalUniqueItems) / targetVariety, 1.0)
    }
    
    func logout() async {
        await authService.logout()
    }
}