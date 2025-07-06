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
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
