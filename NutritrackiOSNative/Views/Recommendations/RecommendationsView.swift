//
//  RecommendationsView.swift
//  NutritrackiOSNative
//
//  Created by Petar Petkov on 06/07/2025.
//

import SwiftUI

struct RecommendationsView: View {
    @EnvironmentObject private var apiService: APIService
    @StateObject private var viewModel: RecommendationsViewModel
    
    init() {
        self._viewModel = StateObject(wrappedValue: RecommendationsViewModel(
            apiService: APIService.shared
        ))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Filter Section
                VStack(spacing: 12) {
                    Text("Based on your consumption history")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top)
                    
                    Picker("Days to analyze", selection: $viewModel.selectedDays) {
                        ForEach(viewModel.dayOptions, id: \.self) { days in
                            Text("\(days) days").tag(days)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .onChange(of: viewModel.selectedDays) { _ in
                        viewModel.onDaysSelectionChange()
                    }
                }
                
                // Content Section
                if viewModel.isLoading {
                    LoadingView(message: "Generating recommendations...")
                } else if viewModel.recommendations.isEmpty {
                    EmptyStateView(
                        icon: "sparkles",
                        title: "No Recommendations Yet",
                        subtitle: "Start tracking your meals to get personalized recipe recommendations"
                    ) {
                        Task { await viewModel.loadRecommendations() }
                    }
                } else {
                    // Recommendations List
                    List {
                        ForEach(viewModel.recommendations, id: \.dish.id) { recommendation in
                            RecommendationCard(recommendation: recommendation)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        await viewModel.loadRecommendations()
                    }
                }
            }
            .navigationTitle("Recommendations")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task { await viewModel.loadRecommendations() }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .customErrorAlert(errorMessage: $viewModel.errorMessage)
            .task {
                await viewModel.loadRecommendations()
            }
        }
    }
}

struct RecommendationCard: View {
    let recommendation: APIRecommendation
    @EnvironmentObject private var apiService: APIService
    @EnvironmentObject private var authService: AuthService
    @State private var showingSaveSheet = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.dish.name)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    if let description = recommendation.dish.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(recommendation.score * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(freshnessColor)
                    
                    Text("freshness")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Reason Badge
            HStack {
                Text(recommendation.explanation)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                
                Spacer()
                
                Text("\(recommendation.dish.ingredients.count) ingredients")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Ingredients Preview
            if !recommendation.dish.ingredients.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ingredients:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 4) {
                        ForEach(recommendation.dish.ingredients.prefix(4), id: \.id) { dishIngredient in
                            HStack {
                                if let ingredient = dishIngredient.ingredient {
                                    Text(Constants.Categories.iconForCategory(ingredient.category))
                                        .font(.caption)
                                    
                                    Text(ingredient.name)
                                        .font(.caption)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                } else {
                                    Text("🥄")
                                        .font(.caption)
                                    
                                    Text("Unknown")
                                        .font(.caption)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                }
                                
                                Spacer()
                            }
                        }
                        
                        if recommendation.dish.ingredients.count > 4 {
                            Text("+\(recommendation.dish.ingredients.count - 4) more")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Instructions Preview
            if let instructions = recommendation.dish.instructions, !instructions.isEmpty {
                Text(instructions)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .padding(.top, 4)
            }
            
            // Actions
            HStack {
                Button(action: {
                    showingSaveSheet = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Save as Recipe")
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                Spacer()
                
                // Stats
                HStack {
                    Label("Fresh", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Label("\(recommendation.dish.ingredients.count)", systemImage: "list.bullet")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .sheet(isPresented: $showingSaveSheet) {
            SaveRecommendationSheet(recommendation: recommendation) { request in
                await saveRecommendationAsDish(request)
            }
        }
        .customErrorAlert(errorMessage: $errorMessage)
    }
    
    private var freshnessColor: Color {
        if recommendation.score >= 0.7 {
            return .green
        } else if recommendation.score >= 0.4 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func saveRecommendationAsDish(_ request: CreateDishRequest) async {
        do {
            _ = try await apiService.createDish(request)
            showingSaveSheet = false
        } catch {
            errorMessage = "Failed to create recipe: \(error.localizedDescription)"
        }
    }
}

// MARK: - Save Recommendation Sheet
struct SaveRecommendationSheet: View {
    let recommendation: APIRecommendation
    let onSave: (CreateDishRequest) async -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var description: String
    @State private var instructions: String
    @State private var servings: Int = 4
    
    init(recommendation: APIRecommendation, onSave: @escaping (CreateDishRequest) async -> Void) {
        self.recommendation = recommendation
        self.onSave = onSave
        
        // Initialize with recommendation data
        _name = State(initialValue: recommendation.dish.name)
        _description = State(initialValue: recommendation.dish.description ?? "")
        _instructions = State(initialValue: recommendation.dish.instructions ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Recipe Information") {
                    TextField("Recipe name", text: $name)
                    
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                    
                    HStack {
                        Text("Servings")
                        Spacer()
                        Stepper("\(servings)", value: $servings, in: 1...20)
                    }
                }
                
                Section("Instructions") {
                    TextField("Instructions", text: $instructions, axis: .vertical)
                        .lineLimit(5, reservesSpace: true)
                }
                
                Section("Ingredients") {
                    ForEach(recommendation.dish.ingredients, id: \.id) { dishIngredient in
                        if let ingredient = dishIngredient.ingredient {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(ingredient.name)
                                        .font(.headline)
                                    Text(ingredient.category)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text("\(Int(dishIngredient.quantity)) \(dishIngredient.unit)")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Save as Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveRecommendation()
                        }
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveRecommendation() async {
        let ingredients = recommendation.dish.ingredients.compactMap { dishIngredient -> CreateDishIngredientRequest? in
            guard let ingredient = dishIngredient.ingredient else { return nil }
            return CreateDishIngredientRequest(
                ingredientId: ingredient.id,
                quantity: dishIngredient.quantity,
                unit: dishIngredient.unit
            )
        }
        
        let request = CreateDishRequest(
            name: name,
            description: description.isEmpty ? nil : description,
            instructions: instructions.isEmpty ? nil : instructions,
            servings: servings,
            ingredients: ingredients
        )
        
        await onSave(request)
        dismiss()
    }
}

#Preview {
    RecommendationsView()
        .environmentObject(APIService.shared)
}