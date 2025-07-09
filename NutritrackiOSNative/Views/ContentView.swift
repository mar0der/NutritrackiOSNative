//
//  ContentView.swift
//  NutritrackiOSNative
//
//  Created by Petar Petkov on 06/07/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var apiService: APIService
    @State private var selectedTab = 0
    @State private var selectedDishForLogging: APIDish?
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)
            
            IngredientsView()
                .tabItem {
                    Label("Ingredients", systemImage: "carrot")
                }
                .tag(1)
            
            DishesView(onLogDish: logDish)
                .tabItem {
                    Label("Dishes", systemImage: "forkandknife")
                }
                .tag(2)
            
            TrackView(preselectedDish: selectedDishForLogging)
                .tabItem {
                    Label("Track", systemImage: "chart.bar")
                }
                .tag(3)
                .onChange(of: selectedTab) { newTab in
                    if newTab != 3 {
                        selectedDishForLogging = nil
                    }
                }
            
            RecommendationsView()
                .tabItem {
                    Label("Recommendations", systemImage: "sparkles")
                }
                .tag(4)
        }
        .environmentObject(apiService)
    }
    
    private func logDish(_ dish: APIDish) {
        selectedDishForLogging = dish
        selectedTab = 3
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService.shared)
        .environmentObject(APIService.shared)
        .modelContainer(for: Ingredient.self, inMemory: true)
}