//
//  IngredientsViewModel.swift
//  NutritrackiOSNative
//
//  Created by Petar Petkov on 06/07/2025.
//

import Foundation
import SwiftData
import SwiftUI
import Combine

@MainActor
class IngredientsViewModel: ObservableObject {
    @Published var ingredients: [APIIngredient] = []
    @Published var searchText = ""
    @Published var selectedCategory = "All"
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService: APIService
    private let authService: AuthService
    private var loadTask: Task<Void, Never>?
    
    let categories = ["All", "Vegetables", "Fruits", "Grains", "Proteins", "Dairy", "Oils", "Spices", "Other"]
    
    init(apiService: APIService, authService: AuthService) {
        self.apiService = apiService
        self.authService = authService
    }
    
    func loadIngredients() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let allIngredients = try await apiService.getIngredients()
            ingredients = filterIngredients(allIngredients)
        } catch {
            errorMessage = "Failed to load ingredients: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func loadIngredientsWithCancellation() {
        loadTask?.cancel()
        loadTask = Task {
            await loadIngredients()
        }
    }
    
    func deleteIngredient(_ ingredient: APIIngredient) async {
        do {
            try await apiService.deleteIngredient(id: ingredient.id)
            ingredients.removeAll { $0.id == ingredient.id }
        } catch {
            errorMessage = "Failed to delete ingredient: \(error.localizedDescription)"
        }
    }
    
    func createIngredient(_ request: CreateIngredientRequest) async {
        do {
            let newIngredient = try await apiService.createIngredient(request)
            ingredients.append(newIngredient)
        } catch {
            errorMessage = "Failed to create ingredient: \(error.localizedDescription)"
        }
    }
    
    func updateIngredient(_ ingredient: APIIngredient, with request: UpdateIngredientRequest) async {
        do {
            let updatedIngredient = try await apiService.updateIngredient(id: ingredient.id, request)
            if let index = ingredients.firstIndex(where: { $0.id == ingredient.id }) {
                ingredients[index] = updatedIngredient
            }
        } catch {
            errorMessage = "Failed to update ingredient: \(error.localizedDescription)"
        }
    }
    
    private func filterIngredients(_ allIngredients: [APIIngredient]) -> [APIIngredient] {
        var filtered = allIngredients
        
        if selectedCategory != "All" {
            filtered = filtered.filter { $0.category.lowercased() == selectedCategory.lowercased() }
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
        
        return filtered.sorted { $0.name < $1.name }
    }
    
    func onSearchTextChange() {
        loadIngredientsWithCancellation()
    }
    
    func onCategoryChange() {
        loadIngredientsWithCancellation()
    }
}