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
    @StateObject private var apiService = APIService.shared
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

// MARK: - Home View
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var consumptionLogs: [ConsumptionLog]
    @Query private var ingredients: [Ingredient]
    @Query private var dishes: [Dish]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome to NutriTrack")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Track your nutrition and discover variety")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    
                    // Summary Cards
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        SummaryCard(
                            title: "Ingredients",
                            value: "\(ingredients.count)",
                            icon: "carrot",
                            color: .green
                        )
                        
                        SummaryCard(
                            title: "Dishes",
                            value: "\(dishes.count)",
                            icon: "forkandknife",
                            color: .blue
                        )
                        
                        SummaryCard(
                            title: "Today's Logs",
                            value: "\(todaysLogs)",
                            icon: "chart.bar",
                            color: .orange
                        )
                        
                        SummaryCard(
                            title: "Variety Score",
                            value: "85%",
                            icon: "sparkles",
                            color: .purple
                        )
                    }
                    .padding(.horizontal)
                    
                    // Quick Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Actions")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        HStack(spacing: 16) {
                            QuickActionButton(
                                title: "Log Meal",
                                icon: "plus.circle",
                                color: .green
                            ) {
                                // TODO: Navigate to track screen
                            }
                            
                            QuickActionButton(
                                title: "Add Recipe",
                                icon: "book",
                                color: .blue
                            ) {
                                // TODO: Navigate to dishes screen
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Home")
        }
    }
    
    private var todaysLogs: Int {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        return consumptionLogs.filter { log in
            log.consumedAt >= today && log.consumedAt < tomorrow
        }.count
    }
}

// MARK: - Summary Card
struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                
                Text(title)
                    .fontWeight(.medium)
                
                Spacer()
            }
            .foregroundColor(.white)
            .padding()
            .background(color)
            .cornerRadius(12)
        }
    }
}

// MARK: - Placeholder Views (IngredientsView and DishesView moved to separate files)

struct TrackView: View {
    let preselectedDish: APIDish?
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var apiService: APIService
    @Query private var localLogs: [ConsumptionLog]
    
    @State private var consumptionLogs: [APIConsumptionLog] = []
    @State private var availableIngredients: [APIIngredient] = []
    @State private var availableDishes: [APIDish] = []
    @State private var isLoading = false
    @State private var showingAddSheet = false
    @State private var errorMessage: String?
    @State private var selectedDate = Date()
    
    init(preselectedDish: APIDish? = nil) {
        self.preselectedDish = preselectedDish
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Date Picker
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
                    .padding(.horizontal)
                    .onChange(of: selectedDate) { _ in
                        Task { await loadConsumptionLogs() }
                    }
                
                // Content Section
                if isLoading {
                    Spacer()
                    ProgressView("Loading consumption logs...")
                    Spacer()
                } else if filteredLogs.isEmpty {
                    EmptyTrackView {
                        showingAddSheet = true
                    }
                } else {
                    // Consumption Logs List
                    List {
                        ForEach(filteredLogs, id: \.id) { log in
                            ConsumptionLogRow(log: log)
                        }
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        await loadConsumptionLogs()
                    }
                }
            }
            .navigationTitle("Track Consumption")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddConsumptionLogSheet(
                    availableIngredients: availableIngredients,
                    availableDishes: availableDishes,
                    preselectedDish: preselectedDish
                ) { log in
                    await createConsumptionLog(log)
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .task {
                await loadData()
            }
            .onAppear {
                if preselectedDish != nil {
                    showingAddSheet = true
                }
            }
        }
    }
    
    private var filteredLogs: [APIConsumptionLog] {
        let calendar = Calendar.current
        return consumptionLogs.filter { log in
            let logDate = ISO8601DateFormatter().date(from: log.consumedAt) ?? Date()
            return calendar.isDate(logDate, inSameDayAs: selectedDate)
        }
    }
    
    // MARK: - API Methods
    
    @MainActor
    private func loadData() async {
        isLoading = true
        
        async let logsTask = loadConsumptionLogs()
        async let ingredientsTask = loadIngredients()
        async let dishesTask = loadDishes()
        
        await logsTask
        await ingredientsTask
        await dishesTask
        
        isLoading = false
    }
    
    @MainActor
    private func loadConsumptionLogs() async {
        do {
            consumptionLogs = try await apiService.getConsumptionLogs(days: 30)
        } catch {
            errorMessage = "Failed to load consumption logs: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    private func loadIngredients() async {
        do {
            availableIngredients = try await apiService.getIngredients()
        } catch {
            errorMessage = "Failed to load ingredients: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    private func loadDishes() async {
        do {
            availableDishes = try await apiService.getDishes()
        } catch {
            errorMessage = "Failed to load dishes: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    private func createConsumptionLog(_ request: CreateConsumptionLogRequest) async {
        do {
            let newLog = try await apiService.logConsumption(request)
            consumptionLogs.append(newLog)
            
            // Also save to local SwiftData
            let localLog = ConsumptionLog(
                id: newLog.id,
                consumedAt: ISO8601DateFormatter().date(from: newLog.consumedAt) ?? Date(),
                quantity: newLog.quantity,
                unit: newLog.unit,
                ingredient: availableIngredients.first(where: { $0.id == newLog.ingredientId })?.toLocal(),
                dish: availableDishes.first(where: { $0.id == newLog.dishId })?.toLocal()
            )
            modelContext.insert(localLog)
        } catch {
            errorMessage = "Failed to log consumption: \(error.localizedDescription)"
        }
    }
}

struct RecommendationsView: View {
    @EnvironmentObject private var apiService: APIService
    
    @State private var recommendations: [Recommendation] = []
    @State private var isLoading = false
    @State private var selectedDays = 7
    @State private var errorMessage: String?
    
    private let dayOptions = [3, 7, 14, 30]
    
    var body: some View {
        NavigationView {
            VStack {
                // Filter Section
                VStack(spacing: 12) {
                    Text("Based on your consumption history")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top)
                    
                    Picker("Days to analyze", selection: $selectedDays) {
                        ForEach(dayOptions, id: \.self) { days in
                            Text("\(days) days").tag(days)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .onChange(of: selectedDays) { _ in
                        Task { await loadRecommendations() }
                    }
                }
                
                // Content Section
                if isLoading {
                    Spacer()
                    ProgressView("Generating recommendations...")
                    Spacer()
                } else if recommendations.isEmpty {
                    EmptyRecommendationsView {
                        Task { await loadRecommendations() }
                    }
                } else {
                    // Recommendations List
                    List {
                        ForEach(recommendations, id: \.id) { recommendation in
                            RecommendationCard(recommendation: recommendation)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        await loadRecommendations()
                    }
                }
            }
            .navigationTitle("Recommendations")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task { await loadRecommendations() }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .task {
                await loadRecommendations()
            }
        }
    }
    
    // MARK: - API Methods
    
    @MainActor
    private func loadRecommendations() async {
        isLoading = true
        
        do {
            recommendations = try await apiService.getRecommendations(days: selectedDays, limit: 10)
        } catch {
            errorMessage = "Failed to load recommendations: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

// MARK: - Supporting Views for RecommendationsView

struct EmptyRecommendationsView: View {
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Recommendations Yet")
                    .font(.headline)
                
                Text("Start tracking your meals to get personalized recipe recommendations")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button("Refresh", action: action)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct RecommendationCard: View {
    let recommendation: Recommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.name)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    if let description = recommendation.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(recommendation.freshnessScore * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(freshnessColor)
                    
                    Text("freshness")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Reason Badge
            HStack {
                Text(recommendation.reason)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                
                Spacer()
                
                Text("\(recommendation.dishIngredients.count) ingredients")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Ingredients Preview
            if !recommendation.dishIngredients.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ingredients:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 4) {
                        ForEach(recommendation.dishIngredients.prefix(4), id: \.id) { dishIngredient in
                            HStack {
                                Text(iconForCategory(dishIngredient.ingredient.category))
                                    .font(.caption)
                                
                                Text(dishIngredient.ingredient.name)
                                    .font(.caption)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                
                                Spacer()
                            }
                        }
                        
                        if recommendation.dishIngredients.count > 4 {
                            Text("+\(recommendation.dishIngredients.count - 4) more")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Instructions Preview
            if let instructions = recommendation.instructions, !instructions.isEmpty {
                Text(instructions)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .padding(.top, 4)
            }
            
            // Stats
            HStack {
                Label("\(recommendation.recentIngredients)", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                Spacer()
                
                Label("\(recommendation.totalIngredients)", systemImage: "list.bullet")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var freshnessColor: Color {
        if recommendation.freshnessScore >= 0.7 {
            return .green
        } else if recommendation.freshnessScore >= 0.4 {
            return .orange
        } else {
            return .red
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

// MARK: - Supporting Views for TrackView

struct EmptyTrackView: View {
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Consumption Logged")
                    .font(.headline)
                
                Text("Start tracking what you eat today")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Log Consumption", action: action)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

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
                    Text("Recipe • \(dish.dishIngredients.count) ingredients")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                if let consumedAt = ISO8601DateFormatter().date(from: log.consumedAt) {
                    Text(consumedAt, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(log.quantity))")
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
    
    private let units = ["g", "kg", "ml", "l", "cup", "tbsp", "tsp", "piece", "slice", "serving"]
    
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
                            ForEach(units, id: \.self) { unit in
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
        let isoFormatter = ISO8601DateFormatter()
        
        let request = CreateConsumptionLogRequest(
            ingredientId: selectedType == .ingredient ? selectedIngredientId : nil,
            dishId: selectedType == .dish ? selectedDishId : nil,
            quantity: quantity,
            unit: selectedUnit,
            consumedAt: isoFormatter.string(from: consumedAt)
        )
        
        await onSave(request)
        dismiss()
    }
}

enum ConsumptionType {
    case ingredient
    case dish
}

// MARK: - Extensions for TrackView

extension APIIngredient {
    func toLocal() -> Ingredient {
        return Ingredient(
            id: id,
            name: name,
            category: category,
            nutritionalInfo: nutritionalInfo?.toLocal()
        )
    }
}

extension APIDish {
    func toLocal() -> Dish {
        return Dish(
            id: id,
            name: name,
            description: description,
            instructions: instructions
        )
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Ingredient.self, inMemory: true)
}
