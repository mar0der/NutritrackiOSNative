//
//  NutritrackiOSNativeApp.swift
//  NutritrackiOSNative
//
//  Created by Petar Petkov on 06/07/2025.
//

import SwiftUI
import SwiftData

@main
struct NutritrackiOSNativeApp: App {
    @StateObject private var authService = AuthService.shared
    @StateObject private var apiService = APIService.shared
    @StateObject private var healthKitManager = HealthKitManager()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            NutritionalInfo.self,
            Ingredient.self,
            DishIngredient.self,
            Dish.self,
            ConsumptionLog.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("❌ SwiftData ModelContainer error: \(error)")
            // Try to create a fresh container with in-memory storage as fallback
            do {
                let fallbackConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                return try ModelContainer(for: schema, configurations: [fallbackConfiguration])
            } catch {
                fatalError("Could not create ModelContainer even with in-memory storage: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isAuthenticated {
                    ContentView()
                        .environmentObject(authService)
                        .environmentObject(apiService)
                        .environmentObject(healthKitManager)
                } else {
                    LoginView()
                        .environmentObject(authService)
                }
            }
            .onOpenURL { url in
                print("📱 App received URL: \(url)")
                print("📱 URL scheme: \(url.scheme ?? "none")")
                print("📱 URL host: \(url.host ?? "none")")
                print("📱 URL path: \(url.path)")
                print("📱 URL query: \(url.query ?? "none")")
                // The OAuth callback is handled by ASWebAuthenticationSession automatically
                // This is just for debugging to confirm URL scheme is working
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
