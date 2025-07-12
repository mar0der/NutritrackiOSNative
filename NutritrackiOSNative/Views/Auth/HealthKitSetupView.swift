//
//  HealthKitSetupView.swift
//  NutritrackiOSNative
//
//  Created by Petar Petkov on 07/07/2025.
//

import SwiftUI
import HealthKit

struct HealthKitSetupView: View {
    @EnvironmentObject private var healthKitManager: HealthKitManager
    @Environment(\.dismiss) private var dismiss
    
    let phase: HealthKitManager.HealthKitPhase
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: phaseIcon)
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(phaseTitle)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text(phaseSubtitle)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Text(phaseDescription)
                            .font(.body)
                    }
                    
                    // Benefits Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What you'll get:")
                            .font(.headline)
                        
                        ForEach(phaseBenefits, id: \.self) { benefit in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.headline)
                                
                                Text(benefit)
                                    .font(.body)
                                
                                Spacer()
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Data Types Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Health data we'll access:")
                            .font(.headline)
                        
                        ForEach(dataTypeGroups, id: \.title) { group in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(group.icon)
                                        .font(.title2)
                                    Text(group.title)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                }
                                
                                ForEach(group.items, id: \.self) { item in
                                    HStack {
                                        Circle()
                                            .fill(Color.blue)
                                            .frame(width: 4, height: 4)
                                        Text(item)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                    }
                                    .padding(.leading, 28)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    
                    // Privacy Note
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "lock.shield")
                                .foregroundColor(.blue)
                            Text("Your Privacy")
                                .font(.headline)
                        }
                        
                        Text("Your health data stays on your device and is only shared with apps you authorize. You can change these permissions anytime in the Health app.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(actionButtonTitle) {
                        Task {
                            await requestPermissions()
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .customErrorAlert(errorMessage: $healthKitManager.errorMessage)
    }
    
    // MARK: - Phase Configuration
    
    private var phaseIcon: String {
        switch phase {
        case .none: return "heart"
        case .core: return "heart.circle"
        case .enhanced: return "heart.circle.fill"
        case .comprehensive: return "brain.head.profile"
        }
    }
    
    private var phaseTitle: String {
        switch phase {
        case .none: return "Connect to Health"
        case .core: return "Basic Health Tracking"
        case .enhanced: return "Enhanced Nutrition"
        case .comprehensive: return "Complete Analysis"
        }
    }
    
    private var phaseSubtitle: String {
        switch phase {
        case .none: return "Get started with health integration"
        case .core: return "Essential nutrition and body metrics"
        case .enhanced: return "Detailed fats and vitamins"
        case .comprehensive: return "Complete micronutrient tracking"
        }
    }
    
    private var phaseDescription: String {
        switch phase {
        case .none:
            return "Connect NutriTrack to the Health app to get personalized nutrition goals and sync your dietary data across all your health apps."
        case .core:
            return "Track your essential nutrition data and body metrics to get personalized calorie goals and basic nutritional insights."
        case .enhanced:
            return "Unlock detailed fat analysis and essential vitamin tracking for better heart health and immune system insights."
        case .comprehensive:
            return "Get complete nutritional analysis with B vitamins and mineral tracking for optimal health monitoring."
        }
    }
    
    private var phaseBenefits: [String] {
        switch phase {
        case .none, .core:
            return [
                "Personalized calorie goals based on your BMR",
                "Track macronutrients (protein, carbs, fats)",
                "Monitor hydration and fiber intake",
                "Sync with other health and fitness apps",
                "Automatic backup of your nutrition data"
            ]
        case .enhanced:
            return [
                "Detailed fat type analysis (saturated, unsaturated)",
                "Essential vitamin tracking (C, D, E, K)",
                "Heart health insights and recommendations",
                "Immune system support monitoring",
                "Advanced dietary pattern analysis"
            ]
        case .comprehensive:
            return [
                "Complete B vitamin tracking (B6, B12)",
                "Essential mineral monitoring (calcium, iron, zinc)",
                "Bone health and energy level optimization",
                "Comprehensive nutritional deficiency alerts",
                "Complete micronutrient profile analysis"
            ]
        }
    }
    
    private var dataTypeGroups: [DataTypeGroup] {
        switch phase {
        case .none, .core:
            return [
                DataTypeGroup(
                    icon: "👤",
                    title: "Profile Data",
                    items: ["Age", "Biological Sex", "Height", "Weight", "BMI"]
                ),
                DataTypeGroup(
                    icon: "🍽️",
                    title: "Basic Nutrition",
                    items: ["Calories", "Protein", "Carbohydrates", "Total Fat", "Fiber", "Sugar", "Sodium", "Water"]
                )
            ]
        case .enhanced:
            return [
                DataTypeGroup(
                    icon: "🥑",
                    title: "Detailed Fats",
                    items: ["Saturated Fat", "Monounsaturated Fat", "Polyunsaturated Fat", "Cholesterol"]
                ),
                DataTypeGroup(
                    icon: "💊",
                    title: "Essential Vitamins",
                    items: ["Vitamin C", "Vitamin D", "Vitamin E", "Vitamin K"]
                )
            ]
        case .comprehensive:
            return [
                DataTypeGroup(
                    icon: "🧬",
                    title: "B Vitamins",
                    items: ["Vitamin B6", "Vitamin B12"]
                ),
                DataTypeGroup(
                    icon: "⚡",
                    title: "Essential Minerals",
                    items: ["Calcium", "Iron", "Potassium", "Zinc"]
                )
            ]
        }
    }
    
    private var actionButtonTitle: String {
        switch phase {
        case .none, .core: return "Connect to Health"
        case .enhanced: return "Enable Enhanced Tracking"
        case .comprehensive: return "Enable Complete Analysis"
        }
    }
    
    // MARK: - Actions
    
    private func requestPermissions() async {
        switch phase {
        case .none, .core:
            await healthKitManager.requestCorePermissions()
        case .enhanced:
            await healthKitManager.requestEnhancedPermissions()
        case .comprehensive:
            await healthKitManager.requestComprehensivePermissions()
        }
        
        if healthKitManager.errorMessage == nil {
            dismiss()
        }
    }
}

struct DataTypeGroup {
    let icon: String
    let title: String
    let items: [String]
}

// MARK: - Health Integration Card

struct HealthIntegrationCard: View {
    @EnvironmentObject private var healthKitManager: HealthKitManager
    @State private var showingSetup = false
    @State private var showingUpgrade = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: healthKitManager.isAuthorized ? "heart.fill" : "heart")
                    .foregroundColor(healthKitManager.isAuthorized ? .red : .gray)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Health Integration")
                        .font(.headline)
                    
                    Text(statusText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if healthKitManager.isAuthorized {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(healthKitManager.currentPhase.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                        
                        if shouldShowUpgradeOption {
                            Text("Upgrade Available")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            
            if healthKitManager.isAuthorized {
                // User profile summary
                if let profile = healthKitManager.userProfile {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            if let bmr = profile.bmr {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("BMR")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text("\(Int(bmr)) cal")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                            }
                            
                            if let weight = profile.weight {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Weight")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text("\(Int(weight)) kg")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                            }
                            
                            if let bmi = profile.bmi {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("BMI")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text(String(format: "%.1f", bmi))
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                            }
                            
                            Spacer()
                        }
                        
                        if shouldShowUpgradeOption {
                            Button(upgradeButtonTitle) {
                                showingUpgrade = true
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }
                } else {
                    ProgressView("Loading profile...")
                        .font(.caption)
                        .task {
                            await healthKitManager.loadUserProfile()
                        }
                }
            } else {
                Button("Connect to Health App") {
                    showingSetup = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .sheet(isPresented: $showingSetup) {
            HealthKitSetupView(phase: .core)
                .environmentObject(healthKitManager)
        }
        .sheet(isPresented: $showingUpgrade) {
            HealthKitSetupView(phase: nextPhase)
                .environmentObject(healthKitManager)
        }
    }
    
    private var statusText: String {
        if healthKitManager.isAuthorized {
            return "Connected • \(healthKitManager.currentPhase.displayName)"
        } else {
            return "Not connected"
        }
    }
    
    private var shouldShowUpgradeOption: Bool {
        switch healthKitManager.currentPhase {
        case .none:
            return false
        case .core:
            return healthKitManager.shouldSuggestEnhancedTracking()
        case .enhanced:
            return healthKitManager.shouldSuggestComprehensiveAnalysis()
        case .comprehensive:
            return false
        }
    }
    
    private var nextPhase: HealthKitManager.HealthKitPhase {
        switch healthKitManager.currentPhase {
        case .none, .core:
            return .enhanced
        case .enhanced:
            return .comprehensive
        case .comprehensive:
            return .comprehensive
        }
    }
    
    private var upgradeButtonTitle: String {
        switch nextPhase {
        case .enhanced:
            return "Enable Enhanced Nutrition →"
        case .comprehensive:
            return "Enable Complete Analysis →"
        default:
            return "Upgrade Available →"
        }
    }
}

#Preview {
    HealthKitSetupView(phase: .core)
        .environmentObject(HealthKitManager())
}