//
//  RecommendationsViewModel.swift
//  NutritrackiOSNative
//
//  Created by Petar Petkov on 06/07/2025.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class RecommendationsViewModel: ObservableObject {
    @Published var recommendations: [APIRecommendation] = []
    @Published var selectedDays = 7
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService: APIService
    
    let dayOptions = [3, 7, 14, 30]
    
    init(apiService: APIService) {
        self.apiService = apiService
    }
    
    func loadRecommendations() async {
        isLoading = true
        errorMessage = nil
        
        do {
            recommendations = try await apiService.getRecommendations(days: selectedDays, limit: 10)
        } catch {
            errorMessage = "Failed to load recommendations: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func onDaysSelectionChange() {
        Task {
            await loadRecommendations()
        }
    }
    
    func refreshRecommendations() async {
        await loadRecommendations()
    }
}