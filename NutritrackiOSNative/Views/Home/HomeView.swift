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
    
    let onNavigateToTrack: () -> Void
    let onNavigateToDishes: () -> Void
    
    init(onNavigateToTrack: @escaping () -> Void = {}, onNavigateToDishes: @escaping () -> Void = {}) {
        self.onNavigateToTrack = onNavigateToTrack
        self.onNavigateToDishes = onNavigateToDishes
        self._viewModel = StateObject(wrappedValue: HomeViewModel(
            authService: AuthService.shared,
            apiService: APIService.shared,
            healthKitManager: HealthKitManager()
        ))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom Header
                CustomHeader(
                    user: authService.currentUser,
                    onLogout: {
                        Task {
                            await viewModel.logout()
                        }
                    }
                )
                
                // Main Content
                VStack(spacing: 12) {
                    // Summary Cards
                    SummarySection(
                        ingredientsCount: ingredients.count,
                        dishesCount: dishes.count,
                        todaysLogs: viewModel.todaysConsumptionCount,
                        varietyScore: viewModel.varietyScore
                    )
                    
                    // Health Integration
                    CompactHealthCard()
                        .padding(.horizontal)
                    
                    // Quick Actions
                    QuickActionsSection(
                        onNavigateToTrack: onNavigateToTrack,
                        onNavigateToDishes: onNavigateToDishes
                    )
                    
                    Spacer(minLength: 0)
                }
                .padding(.top, 8)
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.calculateTodaysLogs(from: consumptionLogs)
                Task {
                    await viewModel.calculateVarietyScore(from: consumptionLogs)
                }
            }
        }
    }
}

// MARK: - Custom Header
struct CustomHeader: View {
    let user: User?
    let onLogout: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Image
            ProfileImageView(avatarURL: user?.avatar)
            
            // User Info
            VStack(alignment: .leading, spacing: 2) {
                Text("Welcome, \(user?.name ?? "User")!")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Track your nutrition and discover variety")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Logout Button
            Button(action: onLogout) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.title3)
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

// MARK: - Profile Image View
struct ProfileImageView: View {
    let avatarURL: String?
    
    var body: some View {
        Group {
            if let avatarURL = avatarURL, let url = URL(string: avatarURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                        )
                }
            } else {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.blue)
                    )
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())
    }
}

// MARK: - Summary Section
struct SummarySection: View {
    let ingredientsCount: Int
    let dishesCount: Int
    let todaysLogs: Int
    let varietyScore: Double
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                SummaryCard(
                    title: "Ingredients",
                    value: "\(ingredientsCount)",
                    icon: "carrot",
                    color: .green
                )
                
                SummaryCard(
                    title: "Dishes",
                    value: "\(dishesCount)",
                    icon: "fork.knife",
                    color: .blue
                )
            }
            
            HStack(spacing: 12) {
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
    let onNavigateToTrack: () -> Void
    let onNavigateToDishes: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Actions")
                .font(.headline)
                .padding(.horizontal)
            
            HStack(spacing: 12) {
                QuickActionButton(
                    title: "Log Meal",
                    icon: "plus.circle",
                    color: .green
                ) {
                    onNavigateToTrack()
                }
                
                QuickActionButton(
                    title: "Add Recipe",
                    icon: "book",
                    color: .blue
                ) {
                    onNavigateToDishes()
                }
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    HomeView(
        onNavigateToTrack: { print("Navigate to Track") },
        onNavigateToDishes: { print("Navigate to Dishes") }
    )
        .environmentObject(AuthService.shared)
        .environmentObject(APIService.shared)
        .environmentObject(HealthKitManager())
        .modelContainer(for: Ingredient.self, inMemory: true)
}

// MARK: - Compact Health Card
struct CompactHealthCard: View {
    @EnvironmentObject private var healthKitManager: HealthKitManager
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "heart.fill")
                .font(.title2)
                .foregroundColor(healthKitManager.isAuthorized ? .red : .gray)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Health Integration")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(healthKitManager.isAuthorized ? "Connected" : "Tap to connect")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if healthKitManager.isAuthorized {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.green)
            } else {
                Image(systemName: "arrow.right.circle")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onTapGesture {
            if !healthKitManager.isAuthorized {
                Task {
                    await healthKitManager.requestCorePermissions()
                }
            }
        }
    }
}