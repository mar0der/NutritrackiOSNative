//
//  HomeView.swift
//  NutritrackiOSNative
//
//  Created by Petar Petkov on 06/07/2025.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var apiService: APIService
    @EnvironmentObject private var healthKitManager: HealthKitManager
    @Query private var consumptionLogs: [ConsumptionLog]
    @Query private var ingredients: [Ingredient]
    @Query private var dishes: [Dish]
    
    @StateObject private var viewModel: HomeViewModel
    
    init() {
        self._viewModel = StateObject(wrappedValue: HomeViewModel(
            authService: AuthService.shared,
            apiService: APIService.shared,
            healthKitManager: HealthKitManager()
        ))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome Section
                    WelcomeSection(
                        userName: authService.currentUser?.name ?? "User",
                        onLogout: {
                            Task {
                                await viewModel.logout()
                            }
                        }
                    )
                    
                    // Summary Cards
                    SummarySection(
                        ingredientsCount: ingredients.count,
                        dishesCount: dishes.count,
                        todaysLogs: viewModel.todaysConsumptionCount,
                        varietyScore: viewModel.varietyScore
                    )
                    
                    // Health Integration
                    HealthIntegrationCard()
                        .padding(.horizontal)
                    
                    // Quick Actions
                    QuickActionsSection()
                    
                    Spacer()
                }
            }
            .navigationTitle("Home")
            .onAppear {
                viewModel.calculateTodaysLogs(from: consumptionLogs)
                Task {
                    await viewModel.calculateVarietyScore(from: consumptionLogs)
                }
            }
        }
    }
}

// MARK: - Welcome Section
struct WelcomeSection: View {
    let userName: String
    let onLogout: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Welcome, \(userName)!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Track your nutrition and discover variety")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onLogout) {
                    Image(systemName: "person.crop.circle.fill.badge.minus")
                        .font(.title2)
                        .foregroundColor(.red)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}

// MARK: - Summary Section
struct SummarySection: View {
    let ingredientsCount: Int
    let dishesCount: Int
    let todaysLogs: Int
    let varietyScore: Double
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                SummaryCard(
                    title: "Ingredients",
                    value: "\(ingredientsCount)",
                    icon: "carrot",
                    color: .green
                )
                
                SummaryCard(
                    title: "Dishes",
                    value: "\(dishesCount)",
                    icon: "forkandknife",
                    color: .blue
                )
            }
            
            HStack(spacing: 16) {
                SummaryCard(
                    title: "Today's Logs",
                    value: "\(todaysLogs)",
                    icon: "chart.bar",
                    color: .orange
                )
                
                SummaryCard(
                    title: "Variety Score",
                    value: "\(Int(varietyScore * 100))%",
                    icon: "sparkles",
                    color: .purple
                )
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Quick Actions Section
struct QuickActionsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .padding(.horizontal)
            
            HStack(spacing: 16) {
                QuickActionButton(
                    title: "Log Meal",
                    icon: "plus.circle",
                    color: .green
                ) {
                    // TODO: Navigate to track screen
                }
                
                QuickActionButton(
                    title: "Add Recipe",
                    icon: "book",
                    color: .blue
                ) {
                    // TODO: Navigate to dishes screen
                }
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthService.shared)
        .environmentObject(APIService.shared)
        .environmentObject(HealthKitManager())
        .modelContainer(for: Ingredient.self, inMemory: true)
}