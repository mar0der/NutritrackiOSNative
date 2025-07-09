//
//  HealthKitManager.swift
//  NutritrackiOSNative
//
//  Created by Petar Petkov on 07/07/2025.
//

import Foundation
import HealthKit
import SwiftUI
import Combine

class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var currentPhase: HealthKitPhase = .none
    @Published var userProfile: UserProfile?
    @Published var errorMessage: String?
    
    enum HealthKitPhase: Int, CaseIterable {
        case none = 0
        case core = 1
        case enhanced = 2
        case comprehensive = 3
        
        var displayName: String {
            switch self {
            case .none: return "Not Connected"
            case .core: return "Basic Tracking"
            case .enhanced: return "Enhanced Tracking"
            case .comprehensive: return "Comprehensive Analysis"
            }
        }
    }
    
    struct UserProfile {
        let age: Int?
        let biologicalSex: HKBiologicalSex
        let height: Double? // in meters
        let weight: Double? // in kilograms
        let bmi: Double?
        
        var bmr: Double? {
            guard let height = height,
                  let weight = weight,
                  let age = age else { return nil }
            
            // Mifflin-St Jeor Equation
            let baseCalories = (10 * weight) + (6.25 * (height * 100)) - (5 * Double(age))
            
            switch biologicalSex {
            case .male:
                return baseCalories + 5
            case .female:
                return baseCalories - 161
            default:
                return baseCalories - 78 // Average between male/female
            }
        }
    }
    
    init() {
        loadCurrentPhase()
    }
    
    // MARK: - Availability & Setup
    
    func isHealthKitAvailable() -> Bool {
        return HKHealthStore.isHealthDataAvailable()
    }
    
    private func loadCurrentPhase() {
        let phase = UserDefaults.standard.integer(forKey: "HealthKitPhase")
        currentPhase = HealthKitPhase(rawValue: phase) ?? .none
    }
    
    private func saveCurrentPhase() {
        UserDefaults.standard.set(currentPhase.rawValue, forKey: "HealthKitPhase")
    }
    
    // MARK: - Phase 1: Core Setup
    
    @MainActor
    func requestCorePermissions() async {
        guard isHealthKitAvailable() else {
            errorMessage = "HealthKit is not available on this device"
            return
        }
        
        let typesToRead: Set<HKObjectType> = [
            // Profile data
            HKCharacteristicType.characteristicType(forIdentifier: .dateOfBirth)!,
            HKCharacteristicType.characteristicType(forIdentifier: .biologicalSex)!,
            HKQuantityType.quantityType(forIdentifier: .height)!,
            HKQuantityType.quantityType(forIdentifier: .bodyMass)!,
            HKQuantityType.quantityType(forIdentifier: .bodyMassIndex)!,
            
            // Basic nutrition
            HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryProtein)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryFiber)!,
            HKQuantityType.quantityType(forIdentifier: .dietarySugar)!,
            HKQuantityType.quantityType(forIdentifier: .dietarySodium)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryWater)!
        ]
        
        let typesToShare: Set<HKSampleType> = [
            HKQuantityType.quantityType(forIdentifier: .bodyMass)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryProtein)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryFiber)!,
            HKQuantityType.quantityType(forIdentifier: .dietarySugar)!,
            HKQuantityType.quantityType(forIdentifier: .dietarySodium)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryWater)!
        ]
        
        do {
            try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
            currentPhase = .core
            saveCurrentPhase()
            isAuthorized = true
            await loadUserProfile()
        } catch {
            errorMessage = "Failed to authorize HealthKit: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Phase 2: Enhanced Tracking
    
    @MainActor
    func requestEnhancedPermissions() async {
        let typesToRead: Set<HKObjectType> = [
            // Detailed fats
            HKQuantityType.quantityType(forIdentifier: .dietaryFatSaturated)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryFatMonounsaturated)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryFatPolyunsaturated)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryCholesterol)!,
            
            // Essential vitamins
            HKQuantityType.quantityType(forIdentifier: .dietaryVitaminC)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryVitaminD)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryVitaminE)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryVitaminK)!
        ]
        
        let typesToShare: Set<HKSampleType> = [
            HKQuantityType.quantityType(forIdentifier: .dietaryFatSaturated)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryFatMonounsaturated)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryFatPolyunsaturated)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryCholesterol)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryVitaminC)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryVitaminD)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryVitaminE)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryVitaminK)!
        ]
        
        do {
            try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
            currentPhase = .enhanced
            saveCurrentPhase()
        } catch {
            errorMessage = "Failed to authorize enhanced permissions: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Phase 3: Comprehensive Analysis
    
    @MainActor
    func requestComprehensivePermissions() async {
        let typesToRead: Set<HKObjectType> = [
            // B vitamins
            HKQuantityType.quantityType(forIdentifier: .dietaryVitaminB6)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryVitaminB12)!,
            
            // Essential minerals
            HKQuantityType.quantityType(forIdentifier: .dietaryCalcium)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryIron)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryPotassium)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryZinc)!
        ]
        
        let typesToShare: Set<HKSampleType> = [
            HKQuantityType.quantityType(forIdentifier: .dietaryVitaminB6)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryVitaminB12)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryCalcium)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryIron)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryPotassium)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryZinc)!
        ]
        
        do {
            try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
            currentPhase = .comprehensive
            saveCurrentPhase()
        } catch {
            errorMessage = "Failed to authorize comprehensive permissions: \(error.localizedDescription)"
        }
    }
    
    // MARK: - User Profile Loading
    
    @MainActor
    func loadUserProfile() async {
        do {
            let dateOfBirth = try healthStore.dateOfBirthComponents()
            let biologicalSex = try healthStore.biologicalSex()
            
            let height = await getLatestQuantity(for: .height, unit: HKUnit.meter())
            let weight = await getLatestQuantity(for: .bodyMass, unit: HKUnit.gramUnit(with: .kilo))
            let bmi = await getLatestQuantity(for: .bodyMassIndex, unit: HKUnit.count())
            
            let age = Calendar.current.dateComponents([.year], from: dateOfBirth.date ?? Date(), to: Date()).year
            
            userProfile = UserProfile(
                age: age,
                biologicalSex: biologicalSex.biologicalSex,
                height: height,
                weight: weight,
                bmi: bmi
            )
        } catch {
            errorMessage = "Failed to load user profile: \(error.localizedDescription)"
        }
    }
    
    private func getLatestQuantity(for identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            return nil
        }
        
        return await withCheckedContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(sampleType: quantityType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
                var result: Double?
                if let sample = samples?.first as? HKQuantitySample {
                    result = sample.quantity.doubleValue(for: unit)
                }
                continuation.resume(returning: result)
            }
            healthStore.execute(query)
        }
    }
    
    // MARK: - Nutrition Data Saving
    
    func saveNutritionData(
        calories: Double? = nil,
        protein: Double? = nil,
        carbs: Double? = nil,
        fat: Double? = nil,
        fiber: Double? = nil,
        sugar: Double? = nil,
        sodium: Double? = nil,
        water: Double? = nil,
        // Phase 2 nutrients
        saturatedFat: Double? = nil,
        monounsaturatedFat: Double? = nil,
        polyunsaturatedFat: Double? = nil,
        cholesterol: Double? = nil,
        vitaminC: Double? = nil,
        vitaminD: Double? = nil,
        vitaminE: Double? = nil,
        vitaminK: Double? = nil,
        // Phase 3 nutrients
        vitaminB6: Double? = nil,
        vitaminB12: Double? = nil,
        calcium: Double? = nil,
        iron: Double? = nil,
        potassium: Double? = nil,
        zinc: Double? = nil,
        date: Date = Date()
    ) async {
        guard isAuthorized else { return }
        
        var samples: [HKQuantitySample] = []
        
        // Phase 1 - Core nutrients
        if let calories = calories {
            samples.append(createSample(for: .dietaryEnergyConsumed, value: calories, unit: .kilocalorie(), date: date))
        }
        if let protein = protein {
            samples.append(createSample(for: .dietaryProtein, value: protein, unit: .gram(), date: date))
        }
        if let carbs = carbs {
            samples.append(createSample(for: .dietaryCarbohydrates, value: carbs, unit: .gram(), date: date))
        }
        if let fat = fat {
            samples.append(createSample(for: .dietaryFatTotal, value: fat, unit: .gram(), date: date))
        }
        if let fiber = fiber {
            samples.append(createSample(for: .dietaryFiber, value: fiber, unit: .gram(), date: date))
        }
        if let sugar = sugar {
            samples.append(createSample(for: .dietarySugar, value: sugar, unit: .gram(), date: date))
        }
        if let sodium = sodium {
            samples.append(createSample(for: .dietarySodium, value: sodium, unit: .gramUnit(with: .milli), date: date))
        }
        if let water = water {
            samples.append(createSample(for: .dietaryWater, value: water, unit: .liter(), date: date))
        }
        
        // Phase 2 - Enhanced nutrients
        if currentPhase.rawValue >= HealthKitPhase.enhanced.rawValue {
            if let saturatedFat = saturatedFat {
                samples.append(createSample(for: .dietaryFatSaturated, value: saturatedFat, unit: .gram(), date: date))
            }
            if let monounsaturatedFat = monounsaturatedFat {
                samples.append(createSample(for: .dietaryFatMonounsaturated, value: monounsaturatedFat, unit: .gram(), date: date))
            }
            if let polyunsaturatedFat = polyunsaturatedFat {
                samples.append(createSample(for: .dietaryFatPolyunsaturated, value: polyunsaturatedFat, unit: .gram(), date: date))
            }
            if let cholesterol = cholesterol {
                samples.append(createSample(for: .dietaryCholesterol, value: cholesterol, unit: .gramUnit(with: .milli), date: date))
            }
            if let vitaminC = vitaminC {
                samples.append(createSample(for: .dietaryVitaminC, value: vitaminC, unit: .gramUnit(with: .milli), date: date))
            }
            if let vitaminD = vitaminD {
                samples.append(createSample(for: .dietaryVitaminD, value: vitaminD, unit: .gramUnit(with: .micro), date: date))
            }
            if let vitaminE = vitaminE {
                samples.append(createSample(for: .dietaryVitaminE, value: vitaminE, unit: .gramUnit(with: .milli), date: date))
            }
            if let vitaminK = vitaminK {
                samples.append(createSample(for: .dietaryVitaminK, value: vitaminK, unit: .gramUnit(with: .micro), date: date))
            }
        }
        
        // Phase 3 - Comprehensive nutrients
        if currentPhase.rawValue >= HealthKitPhase.comprehensive.rawValue {
            if let vitaminB6 = vitaminB6 {
                samples.append(createSample(for: .dietaryVitaminB6, value: vitaminB6, unit: .gramUnit(with: .milli), date: date))
            }
            if let vitaminB12 = vitaminB12 {
                samples.append(createSample(for: .dietaryVitaminB12, value: vitaminB12, unit: .gramUnit(with: .micro), date: date))
            }
            if let calcium = calcium {
                samples.append(createSample(for: .dietaryCalcium, value: calcium, unit: .gramUnit(with: .milli), date: date))
            }
            if let iron = iron {
                samples.append(createSample(for: .dietaryIron, value: iron, unit: .gramUnit(with: .milli), date: date))
            }
            if let potassium = potassium {
                samples.append(createSample(for: .dietaryPotassium, value: potassium, unit: .gramUnit(with: .milli), date: date))
            }
            if let zinc = zinc {
                samples.append(createSample(for: .dietaryZinc, value: zinc, unit: .gramUnit(with: .milli), date: date))
            }
        }
        
        // Save all samples
        do {
            try await healthStore.save(samples)
        } catch {
            errorMessage = "Failed to save nutrition data: \(error.localizedDescription)"
        }
    }
    
    private func createSample(for identifier: HKQuantityTypeIdentifier, value: Double, unit: HKUnit, date: Date) -> HKQuantitySample {
        let quantityType = HKQuantityType.quantityType(forIdentifier: identifier)!
        let quantity = HKQuantity(unit: unit, doubleValue: value)
        return HKQuantitySample(type: quantityType, quantity: quantity, start: date, end: date)
    }
    
    // MARK: - Phase Upgrade Suggestions
    
    func shouldSuggestEnhancedTracking() -> Bool {
        guard currentPhase == .core else { return false }
        
        // Check if user has been tracking for 2 weeks
        let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        let lastUpgrade = UserDefaults.standard.object(forKey: "LastPhaseUpgrade") as? Date ?? Date.distantPast
        
        return lastUpgrade < twoWeeksAgo
    }
    
    func shouldSuggestComprehensiveAnalysis() -> Bool {
        guard currentPhase == .enhanced else { return false }
        
        // Check if user has been in enhanced mode for 1 month
        let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        let lastUpgrade = UserDefaults.standard.object(forKey: "LastPhaseUpgrade") as? Date ?? Date.distantPast
        
        return lastUpgrade < oneMonthAgo
    }
    
    func markUpgradeSuggestionShown() {
        UserDefaults.standard.set(Date(), forKey: "LastPhaseUpgrade")
    }
    
    // MARK: - Nutrition Goals
    
    func getRecommendedCalories(activityLevel: ActivityLevel = .moderate) -> Double? {
        guard let bmr = userProfile?.bmr else { return nil }
        return bmr * activityLevel.multiplier
    }
    
    enum ActivityLevel: Double, CaseIterable {
        case sedentary = 1.2
        case light = 1.375
        case moderate = 1.55
        case active = 1.725
        case veryActive = 1.9
        
        var multiplier: Double { rawValue }
        
        var displayName: String {
            switch self {
            case .sedentary: return "Sedentary (little/no exercise)"
            case .light: return "Light (light exercise 1-3 days/week)"
            case .moderate: return "Moderate (moderate exercise 3-5 days/week)"
            case .active: return "Active (hard exercise 6-7 days/week)"
            case .veryActive: return "Very Active (very hard exercise, 2x/day)"
            }
        }
    }
}