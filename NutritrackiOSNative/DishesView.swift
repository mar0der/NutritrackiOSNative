//
//  DishesView.swift
//  NutritrackiOSNative
//
//  Created by Petar Petkov on 06/07/2025.
//

import SwiftUI
import SwiftData

struct DishesView: View {
    let onLogDish: ((APIDish) -> Void)?
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var apiService: APIService
    @Query private var localDishes: [Dish]
    
    init(onLogDish: ((APIDish) -> Void)? = nil) {
        self.onLogDish = onLogDish
    }
    
    @State private var dishes: [APIDish] = []
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var showingAddSheet = false
    @State private var selectedDish: APIDish?
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Section
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search recipes...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            Task { await loadDishes() }
                        }
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Content Section
                if isLoading {
                    Spacer()
                    ProgressView("Loading recipes...")
                    Spacer()
                } else if dishes.isEmpty {
                    EmptyDishesView {
                        showingAddSheet = true
                    }
                } else {
                    // Dishes List
                    List {
                        ForEach(dishes, id: \.id) { dish in
                            DishRow(dish: dish) {
                                selectedDish = dish
                            } deleteAction: {
                                await deleteDish(dish)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        await loadDishes()
                    }
                }
            }
            .navigationTitle("Recipes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddDishSheet { dish in
                    await createDish(dish)
                }
            }
            .sheet(item: $selectedDish) { dish in
                DishDetailView(dish: dish, onLogDish: onLogDish)
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .task {
                await loadDishes()
            }
        }
    }
    
    // MARK: - API Methods
    
    @MainActor
    private func loadDishes() async {
        isLoading = true
        
        do {
            let searchQuery = searchText.isEmpty ? nil : searchText
            dishes = try await apiService.getDishes(search: searchQuery)
        } catch {
            errorMessage = "Failed to load recipes: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    @MainActor
    private func createDish(_ request: CreateDishRequest) async {
        do {
            let newDish = try await apiService.createDish(request)
            dishes.append(newDish)
            
            // Also save to local SwiftData
            let localDish = Dish(
                id: newDish.id,
                name: newDish.name,
                description: newDish.description,
                instructions: newDish.instructions
            )
            modelContext.insert(localDish)
        } catch {
            errorMessage = "Failed to create recipe: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    private func deleteDish(_ dish: APIDish) async {
        do {
            try await apiService.deleteDish(id: dish.id)
            dishes.removeAll { $0.id == dish.id }
            
            // Also delete from local SwiftData
            if let localDish = localDishes.first(where: { $0.id == dish.id }) {
                modelContext.delete(localDish)
            }
        } catch {
            errorMessage = "Failed to delete recipe: \(error.localizedDescription)"
        }
    }
}

// MARK: - Dish Row
struct DishRow: View {
    let dish: APIDish
    let viewAction: () -> Void
    let deleteAction: () async -> Void
    
    @State private var isDeleting = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(dish.name)
                    .font(.headline)
                
                if let description = dish.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    Text("\(dish.dishIngredients.count) ingredients")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    // Ingredient icons preview
                    HStack(spacing: 2) {
                        ForEach(dish.dishIngredients.prefix(4), id: \.ingredient.id) { dishIngredient in
                            Text(iconForCategory(dishIngredient.ingredient.category))
                                .font(.caption)
                        }
                        
                        if dish.dishIngredients.count > 4 {
                            Text("+\(dish.dishIngredients.count - 4)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: viewAction) {
                    Image(systemName: "eye")
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
    
    private func iconForCategory(_ category: String) -> String {
        switch category.lowercased() {
        case "vegetables": return "🥕"
        case "fruits": return "🍎"
        case "grains": return "🌾"
        case "proteins": return "🥩"
        case "dairy": return "🥛"
        case "oils": return "🫒"
        case "spices": return "🌶️"
        default: return "🥄"
        }
    }
}

// MARK: - Empty Dishes View
struct EmptyDishesView: View {
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Recipes Found")
                    .font(.headline)
                
                Text("Create your first recipe to start tracking your meals")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Add Recipe", action: action)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Dish Detail View
struct DishDetailView: View {
    let dish: APIDish
    let onLogDish: ((APIDish) -> Void)?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(dish.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        if let description = dish.description {
                            Text(description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Label("\(dish.dishIngredients.count)", systemImage: "list.bullet")
                            Text("ingredients")
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Ingredients Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ingredients")
                            .font(.headline)
                        
                        LazyVStack(spacing: 8) {
                            ForEach(dish.dishIngredients, id: \.ingredient.id) { dishIngredient in
                                HStack {
                                    Text(iconForCategory(dishIngredient.ingredient.category))
                                        .font(.title2)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(dishIngredient.ingredient.name)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        Text(dishIngredient.ingredient.category)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("\(Int(dishIngredient.quantity)) \(dishIngredient.unit)")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    
                    // Instructions Section
                    if let instructions = dish.instructions, !instructions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Instructions")
                                .font(.headline)
                            
                            Text(instructions)
                                .font(.body)
                        }
                    }
                    
                    // Action Button
                    Button(action: {
                        onLogDish?(dish)
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Log This Dish")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func iconForCategory(_ category: String) -> String {
        switch category.lowercased() {
        case "vegetables": return "🥕"
        case "fruits": return "🍎"
        case "grains": return "🌾"
        case "proteins": return "🥩"
        case "dairy": return "🥛"
        case "oils": return "🫒"
        case "spices": return "🌶️"
        default: return "🥄"
        }
    }
}

// MARK: - Add Dish Sheet
struct AddDishSheet: View {
    let onSave: (CreateDishRequest) async -> Void
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var apiService: APIService
    
    @State private var name = ""
    @State private var description = ""
    @State private var instructions = ""
    @State private var dishIngredients: [DishIngredientInput] = []
    @State private var availableIngredients: [APIIngredient] = []
    @State private var isLoadingIngredients = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Recipe Information") {
                    TextField("Recipe name", text: $name)
                    
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("Ingredients") {
                    ForEach(dishIngredients.indices, id: \.self) { index in
                        DishIngredientInputRow(
                            ingredient: $dishIngredients[index],
                            availableIngredients: availableIngredients
                        ) {
                            dishIngredients.remove(at: index)
                        }
                    }
                    
                    Button("Add Ingredient") {
                        dishIngredients.append(DishIngredientInput())
                    }
                    .disabled(availableIngredients.isEmpty)
                }
                
                Section("Instructions") {
                    TextField("Cooking instructions (optional)", text: $instructions, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .navigationTitle("Add Recipe")
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
                            await saveDish()
                        }
                    }
                    .disabled(name.isEmpty || dishIngredients.isEmpty)
                }
            }
            .task {
                await loadIngredients()
            }
        }
    }
    
    @MainActor
    private func loadIngredients() async {
        isLoadingIngredients = true
        
        do {
            availableIngredients = try await apiService.getIngredients()
        } catch {
            // Handle error
        }
        
        isLoadingIngredients = false
    }
    
    private func saveDish() async {
        let ingredients = dishIngredients.compactMap { input -> CreateDishIngredientRequest? in
            guard let ingredientId = input.selectedIngredientId,
                  input.quantity > 0,
                  !input.unit.isEmpty else { return nil }
            
            return CreateDishIngredientRequest(
                ingredientId: ingredientId,
                quantity: input.quantity,
                unit: input.unit
            )
        }
        
        let request = CreateDishRequest(
            name: name,
            description: description.isEmpty ? nil : description,
            instructions: instructions.isEmpty ? nil : instructions,
            ingredients: ingredients
        )
        
        await onSave(request)
        dismiss()
    }
}

// MARK: - Dish Ingredient Input
struct DishIngredientInput {
    var selectedIngredientId: String?
    var quantity: Double = 0
    var unit: String = "g"
}

struct DishIngredientInputRow: View {
    @Binding var ingredient: DishIngredientInput
    let availableIngredients: [APIIngredient]
    let onDelete: () -> Void
    
    private let units = ["g", "kg", "ml", "l", "cup", "tbsp", "tsp", "piece", "slice"]
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                // Ingredient Picker
                Picker("Ingredient", selection: $ingredient.selectedIngredientId) {
                    Text("Select ingredient").tag(String?.none)
                    ForEach(availableIngredients, id: \.id) { ing in
                        Text(ing.name).tag(String?.some(ing.id))
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
            
            HStack {
                // Quantity
                TextField("Quantity", value: $ingredient.quantity, format: .number)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 80)
                
                // Unit
                Picker("Unit", selection: $ingredient.unit) {
                    ForEach(units, id: \.self) { unit in
                        Text(unit).tag(unit)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 80)
                
                Spacer()
            }
        }
    }
}

#Preview {
    DishesView()
        .environmentObject(APIService.shared)
        .modelContainer(for: Dish.self, inMemory: true)
}