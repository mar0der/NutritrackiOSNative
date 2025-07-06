//
//  IngredientsView.swift
//  NutritrackiOSNative
//
//  Created by Petar Petkov on 06/07/2025.
//

import SwiftUI
import SwiftData

struct IngredientsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var apiService: APIService
    @Query private var localIngredients: [Ingredient]
    
    @State private var ingredients: [APIIngredient] = []
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var isLoading = false
    @State private var showingAddSheet = false
    @State private var errorMessage: String?
    
    private let categories = ["All", "Vegetables", "Fruits", "Grains", "Proteins", "Dairy", "Oils", "Spices", "Other"]
    
    var body: some View {
        NavigationView {
            VStack {
                // Search and Filter Section
                VStack(spacing: 12) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search ingredients...", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onSubmit {
                                Task { await loadIngredients() }
                            }
                    }
                    .padding(.horizontal)
                    
                    // Category Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(categories, id: \.self) { category in
                                CategoryChip(
                                    title: category,
                                    isSelected: selectedCategory == category
                                ) {
                                    selectedCategory = category
                                    Task { await loadIngredients() }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
                
                // Content Section
                if isLoading {
                    Spacer()
                    ProgressView("Loading ingredients...")
                    Spacer()
                } else if ingredients.isEmpty {
                    EmptyStateView(
                        icon: "carrot",
                        title: "No Ingredients Found",
                        subtitle: "Add your first ingredient to get started"
                    ) {
                        showingAddSheet = true
                    }
                } else {
                    // Ingredients List
                    List {
                        ForEach(ingredients, id: \.id) { ingredient in
                            IngredientRow(ingredient: ingredient) {
                                // TODO: Edit action
                            } deleteAction: {
                                await deleteIngredient(ingredient)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        await loadIngredients()
                    }
                }
            }
            .navigationTitle("Ingredients")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddIngredientSheet { ingredient in
                    await createIngredient(ingredient)
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .task {
                await loadIngredients()
            }
        }
    }
    
    // MARK: - API Methods
    
    @MainActor
    private func loadIngredients() async {
        isLoading = true
        
        do {
            let searchQuery = searchText.isEmpty ? nil : searchText
            let categoryFilter = selectedCategory == "All" ? nil : selectedCategory
            
            ingredients = try await apiService.getIngredients(
                search: searchQuery,
                category: categoryFilter
            )
        } catch {
            errorMessage = "Failed to load ingredients: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    @MainActor
    private func createIngredient(_ request: CreateIngredientRequest) async {
        do {
            let newIngredient = try await apiService.createIngredient(request)
            ingredients.append(newIngredient)
            
            // Also save to local SwiftData
            let localIngredient = Ingredient(
                id: newIngredient.id,
                name: newIngredient.name,
                category: newIngredient.category,
                nutritionalInfo: newIngredient.nutritionalInfo?.toLocal()
            )
            modelContext.insert(localIngredient)
        } catch {
            errorMessage = "Failed to create ingredient: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    private func deleteIngredient(_ ingredient: APIIngredient) async {
        do {
            try await apiService.deleteIngredient(id: ingredient.id)
            ingredients.removeAll { $0.id == ingredient.id }
            
            // Also delete from local SwiftData
            if let localIngredient = localIngredients.first(where: { $0.id == ingredient.id }) {
                modelContext.delete(localIngredient)
            }
        } catch {
            errorMessage = "Failed to delete ingredient: \(error.localizedDescription)"
        }
    }
}

// MARK: - Category Chip
struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

// MARK: - Ingredient Row
struct IngredientRow: View {
    let ingredient: APIIngredient
    let editAction: () -> Void
    let deleteAction: () async -> Void
    
    @State private var isDeleting = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(ingredient.name)
                    .font(.headline)
                
                Text(ingredient.category)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let nutritionalInfo = ingredient.nutritionalInfo,
                   let calories = nutritionalInfo.calories {
                    Text("\(Int(calories)) cal/100g")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: editAction) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                }
                .buttonStyle(BorderlessButtonStyle())
                
                Button(action: {
                    isDeleting = true
                    Task {
                        await deleteAction()
                        isDeleting = false
                    }
                }) {
                    if isDeleting {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
                .buttonStyle(BorderlessButtonStyle())
                .disabled(isDeleting)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Add Ingredient", action: action)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Add Ingredient Sheet
struct AddIngredientSheet: View {
    let onSave: (CreateIngredientRequest) async -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selectedCategory = "Vegetables"
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    
    private let categories = ["Vegetables", "Fruits", "Grains", "Proteins", "Dairy", "Oils", "Spices", "Other"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    TextField("Ingredient name", text: $name)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                }
                
                Section("Nutritional Information (per 100g)") {
                    HStack {
                        Text("Calories")
                        Spacer()
                        TextField("0", text: $calories)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Protein (g)")
                        Spacer()
                        TextField("0", text: $protein)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Carbs (g)")
                        Spacer()
                        TextField("0", text: $carbs)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Fat (g)")
                        Spacer()
                        TextField("0", text: $fat)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .navigationTitle("Add Ingredient")
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
                            await saveIngredient()
                        }
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveIngredient() async {
        let nutritionalInfo = APINutritionalInfo(
            calories: Double(calories),
            protein: Double(protein),
            carbs: Double(carbs),
            fat: Double(fat),
            fiber: nil,
            sodium: nil
        )
        
        let request = CreateIngredientRequest(
            name: name,
            category: selectedCategory,
            nutritionalInfo: nutritionalInfo
        )
        
        await onSave(request)
        dismiss()
    }
}

// MARK: - Extensions
extension APINutritionalInfo {
    func toLocal() -> NutritionalInfo {
        return NutritionalInfo(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: fiber,
            sodium: sodium
        )
    }
}

#Preview {
    IngredientsView()
        .environmentObject(APIService.shared)
        .modelContainer(for: Ingredient.self, inMemory: true)
}