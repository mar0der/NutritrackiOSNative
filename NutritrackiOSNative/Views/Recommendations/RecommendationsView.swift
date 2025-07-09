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
                                Text(Constants.Categories.iconForCategory(dishIngredient.ingredient.category))
                                    .font(.caption)
                                
                                Text(dishIngredient.ingredient.name)
                                    .font(.caption)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                
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
            
            // Stats
            HStack {
                Label("Fresh", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                Spacer()
                
                Label("\(recommendation.dish.ingredients.count)", systemImage: "list.bullet")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
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
}

#Preview {
    RecommendationsView()
        .environmentObject(APIService.shared)
}