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
    @EnvironmentObject private var authService: AuthService
    @Query private var localIngredients: [Ingredient]
    
    @State private var ingredients: [APIIngredient] = []
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var isLoading = false
    @State private var showingAddSheet = false
    @State private var showingEditSheet = false
    @State private var selectedIngredientForEdit: APIIngredient?
    @State private var errorMessage: String?
    @State private var loadTask: Task<Void, Never>?
    
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
                                loadIngredientsWithCancellation()
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
                                    loadIngredientsWithCancellation()
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
                            IngredientRow(ingredient: ingredient)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        Task {
                                            await deleteIngredient(ingredient)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    
                                    Button {
                                        selectedIngredientForEdit = ingredient
                                        showingEditSheet = true
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        loadIngredientsWithCancellation()
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
            .sheet(isPresented: $showingEditSheet) {
                if let ingredientToEdit = selectedIngredientForEdit {
                    EditIngredientSheet(ingredient: ingredientToEdit) { updatedIngredient in
                        await updateIngredient(id: ingredientToEdit.id, request: updatedIngredient)
                    }
                }
            }
            .customErrorAlert(errorMessage: $errorMessage)
            .task {
                loadIngredientsWithCancellation()
            }
        }
    }
    
    // MARK: - API Methods
    
    private func loadIngredientsWithCancellation() {
        loadTask?.cancel()
        loadTask = Task {
            await loadIngredients()
        }
    }
    
    @MainActor
    private func loadIngredients() async {
        guard !isLoading else { return }
        
        isLoading = true
        
        do {
            print("🔄 Loading ingredients from API...")
            ingredients = try await apiService.getIngredients()
            print("✅ Successfully loaded \(ingredients.count) ingredients")
            errorMessage = nil
        } catch {
            if Task.isCancelled {
                print("🚫 Ingredients loading cancelled")
                return
            }
            print("❌ Failed to load ingredients: \(error)")
            errorMessage = "Failed to load ingredients: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    @MainActor
    private func createIngredient(_ request: CreateIngredientRequest) async {
        do {
            print("🔄 Creating ingredient: \(request.name)")
            let newIngredient = try await apiService.createIngredient(request)
            print("✅ Successfully created ingredient: \(newIngredient.name) with ID: \(newIngredient.id)")
            
            ingredients.append(newIngredient)
            
            // Also save to local SwiftData
            let localIngredient = Ingredient(
                id: newIngredient.id,
                name: newIngredient.name,
                category: newIngredient.category,
                nutritionalInfo: newIngredient.nutritionPer100g?.toLocal()
            )
            modelContext.insert(localIngredient)
            print("✅ Saved ingredient to local SwiftData")
            
            // Clear any previous error messages
            errorMessage = nil
        } catch {
            print("❌ Failed to create ingredient: \(error)")
            errorMessage = "Failed to create ingredient: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    private func updateIngredient(id: String, request: UpdateIngredientRequest) async {
        do {
            let updatedIngredient = try await apiService.updateIngredient(id: id, request)
            if let index = ingredients.firstIndex(where: { $0.id == id }) {
                ingredients[index] = updatedIngredient
            }
            
            // Also update local SwiftData
            if let localIngredient = localIngredients.first(where: { $0.id == id }) {
                localIngredient.name = updatedIngredient.name
                localIngredient.category = updatedIngredient.category
                localIngredient.nutritionalInfo = updatedIngredient.nutritionPer100g?.toLocal()
            }
            
            selectedIngredientForEdit = nil
        } catch {
            errorMessage = "Failed to update ingredient: \(error.localizedDescription)"
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
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(ingredient.name)
                    .font(.headline)
                
                Text(ingredient.category)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let nutritionalInfo = ingredient.nutritionPer100g,
                   let calories = nutritionalInfo.calories {
                    Text("\(Int(calories)) cal/100g")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
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
            fiber: nil
        )
        
        let request = CreateIngredientRequest(
            name: name,
            category: selectedCategory,
            nutritionPer100g: nutritionalInfo
        )
        
        await onSave(request)
        dismiss()
    }
}

// MARK: - Edit Ingredient Sheet
struct EditIngredientSheet: View {
    let ingredient: APIIngredient
    let onSave: (UpdateIngredientRequest) async -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var selectedCategory: String
    @State private var calories: String
    @State private var protein: String
    @State private var carbs: String
    @State private var fat: String
    
    private let categories = ["Vegetables", "Fruits", "Grains", "Proteins", "Dairy", "Oils", "Spices", "Other"]
    
    init(ingredient: APIIngredient, onSave: @escaping (UpdateIngredientRequest) async -> Void) {
        self.ingredient = ingredient
        self.onSave = onSave
        
        // Initialize state with existing ingredient data
        _name = State(initialValue: ingredient.name)
        _selectedCategory = State(initialValue: ingredient.category)
        _calories = State(initialValue: ingredient.nutritionPer100g?.calories?.description ?? "")
        _protein = State(initialValue: ingredient.nutritionPer100g?.protein?.description ?? "")
        _carbs = State(initialValue: ingredient.nutritionPer100g?.carbs?.description ?? "")
        _fat = State(initialValue: ingredient.nutritionPer100g?.fat?.description ?? "")
    }
    
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
            .navigationTitle("Edit Ingredient")
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
            fiber: nil
        )
        
        let request = UpdateIngredientRequest(
            name: name,
            category: selectedCategory,
            nutritionPer100g: nutritionalInfo
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
            sodium: nil // sodium field removed from new API
        )
    }
}

extension APIIngredient {
    func toLocal() -> Ingredient {
        return Ingredient(
            id: id,
            name: name,
            category: category,
            nutritionalInfo: nutritionPer100g?.toLocal()
        )
    }
}

extension APIDish {
    func toLocal(userId: String? = nil) -> Dish {
        return Dish(
            id: id,
            name: name,
            description: description,
            instructions: instructions,
            servings: servings,
            userId: userId
        )
    }
}

#Preview {
    IngredientsView()
        .environmentObject(APIService.shared)
        .modelContainer(for: Ingredient.self, inMemory: true)
}