//
//  TrackView.swift
//  NutritrackiOSNative
//
//  Created by Petar Petkov on 06/07/2025.
//

import SwiftUI
import SwiftData

struct TrackView: View {
    let preselectedDish: APIDish?
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var apiService: APIService
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var healthKitManager: HealthKitManager
    @Query private var localLogs: [ConsumptionLog]
    
    @StateObject private var viewModel: TrackViewModel
    @State private var showingAddSheet = false
    
    init(preselectedDish: APIDish? = nil) {
        self.preselectedDish = preselectedDish
        self._viewModel = StateObject(wrappedValue: TrackViewModel(
            apiService: APIService.shared,
            authService: AuthService.shared,
            healthKitManager: HealthKitManager()
        ))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Date Picker
                DatePicker("Select Date", selection: $viewModel.selectedDate, displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
                    .padding(.horizontal)
                    .onChange(of: viewModel.selectedDate) { _ in
                        Task { await viewModel.loadConsumptionLogs() }
                    }
                
                // Content Section
                if viewModel.isLoading {
                    LoadingView(message: "Loading consumption logs...")
                } else if viewModel.filteredLogs.isEmpty {
                    EmptyStateView(
                        icon: "chart.bar.doc.horizontal",
                        title: "No Consumption Logged",
                        subtitle: "Start tracking what you eat today"
                    ) {
                        showingAddSheet = true
                    }
                } else {
                    // Consumption Logs List
                    List {
                        ForEach(viewModel.filteredLogs, id: \.id) { log in
                            ConsumptionLogRow(log: log)
                        }
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        await viewModel.loadConsumptionLogs()
                    }
                }
            }
            .navigationTitle("Track Consumption")
            .overlay(
                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FloatingActionButton(icon: "plus", color: .green) {
                            showingAddSheet = true
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            )
            .sheet(isPresented: $showingAddSheet) {
                AddConsumptionLogSheet(
                    availableIngredients: viewModel.availableIngredients,
                    availableDishes: viewModel.availableDishes,
                    preselectedDish: preselectedDish
                ) { request in
                    await viewModel.createConsumptionLog(request, modelContext: modelContext)
                }
            }
            .customErrorAlert(errorMessage: $viewModel.errorMessage)
            .task {
                await viewModel.loadData()
            }
            .onAppear {
                if preselectedDish != nil {
                    showingAddSheet = true
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct ConsumptionLogRow: View {
    let log: APIConsumptionLog
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let ingredient = log.ingredient {
                    Text(ingredient.name)
                        .font(.headline)
                    Text("Ingredient • \(ingredient.category)")
                        .font(.caption)
                        .foregroundColor(.blue)
                } else if let dish = log.dish {
                    Text(dish.name)
                        .font(.headline)
                    Text("Recipe • \(dish.ingredients.count) ingredients")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                if let consumedAt = DateHelpers.parseISO8601(log.consumedAt) {
                    Text(consumedAt, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(log.quantity ?? 0))")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if let unit = log.unit {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddConsumptionLogSheet: View {
    let availableIngredients: [APIIngredient]
    let availableDishes: [APIDish]
    let preselectedDish: APIDish?
    let onSave: (CreateConsumptionLogRequest) async -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedType: ConsumptionType = .ingredient
    @State private var selectedIngredientId: String?
    @State private var selectedDishId: String?
    @State private var quantity: Double = 100
    @State private var selectedUnit = "g"
    @State private var consumedAt = Date()
    
    init(availableIngredients: [APIIngredient], availableDishes: [APIDish], preselectedDish: APIDish? = nil, onSave: @escaping (CreateConsumptionLogRequest) async -> Void) {
        self.availableIngredients = availableIngredients
        self.availableDishes = availableDishes
        self.preselectedDish = preselectedDish
        self.onSave = onSave
        
        // Initialize state based on preselected dish
        if let dish = preselectedDish {
            _selectedType = State(initialValue: .dish)
            _selectedDishId = State(initialValue: dish.id)
            _quantity = State(initialValue: 1)
            _selectedUnit = State(initialValue: "serving")
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("What did you consume?") {
                    if preselectedDish == nil {
                        Picker("Type", selection: $selectedType) {
                            Text("Ingredient").tag(ConsumptionType.ingredient)
                            Text("Recipe").tag(ConsumptionType.dish)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    } else {
                        HStack {
                            Text("Type")
                            Spacer()
                            Text("Recipe")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if selectedType == .ingredient {
                        Picker("Ingredient", selection: $selectedIngredientId) {
                            Text("Select ingredient").tag(String?.none)
                            ForEach(availableIngredients, id: \.id) { ingredient in
                                Text(ingredient.name).tag(String?.some(ingredient.id))
                            }
                        }
                    } else {
                        if let preselectedDish = preselectedDish {
                            HStack {
                                Text("Recipe")
                                Spacer()
                                Text(preselectedDish.name)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Picker("Recipe", selection: $selectedDishId) {
                                Text("Select recipe").tag(String?.none)
                                ForEach(availableDishes, id: \.id) { dish in
                                    Text(dish.name).tag(String?.some(dish.id))
                                }
                            }
                        }
                    }
                }
                
                Section("Quantity") {
                    HStack {
                        TextField("Quantity", value: $quantity, format: .number)
                            .keyboardType(.decimalPad)
                        
                        Picker("Unit", selection: $selectedUnit) {
                            ForEach(Constants.Units.all, id: \.self) { unit in
                                Text(unit).tag(unit)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 80)
                    }
                }
                
                Section("When") {
                    DatePicker("Consumed At", selection: $consumedAt)
                }
            }
            .navigationTitle("Log Consumption")
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
                            await saveConsumptionLog()
                        }
                    }
                    .disabled(!isValidInput)
                }
            }
        }
    }
    
    private var isValidInput: Bool {
        if selectedType == .ingredient {
            return selectedIngredientId != nil && quantity > 0
        } else {
            return selectedDishId != nil && quantity > 0
        }
    }
    
    private func saveConsumptionLog() async {
        let request = CreateConsumptionLogRequest(
            ingredientId: selectedType == .ingredient ? selectedIngredientId : nil,
            dishId: selectedType == .dish ? selectedDishId : nil,
            quantity: quantity,
            unit: selectedType == .ingredient ? selectedUnit : "serving",
            consumedAt: DateHelpers.formatToISO8601(consumedAt)
        )
        
        await onSave(request)
        dismiss()
    }
}

enum ConsumptionType {
    case ingredient
    case dish
}

#Preview {
    TrackView()
        .environmentObject(APIService.shared)
        .environmentObject(AuthService.shared)
        .environmentObject(HealthKitManager())
        .modelContainer(for: Ingredient.self, inMemory: true)
}