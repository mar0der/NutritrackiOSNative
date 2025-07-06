//
//  APIService.swift
//  NutritrackiOSNative
//
//  Created by Petar Petkov on 06/07/2025.
//

import Foundation
import Combine

// MARK: - API Response Models
struct APIIngredient: Codable, Identifiable {
    let id: String
    let name: String
    let category: String
    let nutritionalInfo: APINutritionalInfo?
}

struct APINutritionalInfo: Codable {
    let calories: Double?
    let protein: Double?
    let carbs: Double?
    let fat: Double?
    let fiber: Double?
    let sodium: Double?
}

struct APIDish: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let instructions: String?
    let dishIngredients: [APIDishIngredient]
}

struct APIDishIngredient: Codable {
    let ingredient: APIIngredient
    let quantity: Double
    let unit: String
}

struct APIConsumptionLog: Codable, Identifiable {
    let id: String
    let consumedAt: String
    let quantity: Double
    let unit: String?
    let ingredientId: String?
    let ingredient: APIIngredient?
    let dishId: String?
    let dish: APIDish?
}

// MARK: - API Request Models
struct CreateIngredientRequest: Codable {
    let name: String
    let category: String
    let nutritionalInfo: APINutritionalInfo?
}

struct UpdateIngredientRequest: Codable {
    let name: String?
    let category: String?
    let nutritionalInfo: APINutritionalInfo?
}

struct CreateDishRequest: Codable {
    let name: String
    let description: String?
    let instructions: String?
    let ingredients: [CreateDishIngredientRequest]
}

struct CreateDishIngredientRequest: Codable {
    let ingredientId: String
    let quantity: Double
    let unit: String
}

struct CreateConsumptionLogRequest: Codable {
    let ingredientId: String?
    let dishId: String?
    let quantity: Double
    let unit: String?
    let consumedAt: String?
}

// MARK: - API Service
@MainActor
class APIService: ObservableObject {
    static let shared = APIService()
    
    private let baseURL: String
    private let session = URLSession.shared
    
    private init() {
        // Use secure and trusted API server
        self.baseURL = "https://nutritrackapi.duckdns.org/api"
    }
    
    // MARK: - Ingredients API
    
    func getIngredients(search: String? = nil, category: String? = nil) async throws -> [APIIngredient] {
        var components = URLComponents(string: "\(baseURL)/ingredients")!
        var queryItems: [URLQueryItem] = []
        
        if let search = search, !search.isEmpty {
            queryItems.append(URLQueryItem(name: "search", value: search))
        }
        if let category = category, !category.isEmpty {
            queryItems.append(URLQueryItem(name: "category", value: category))
        }
        
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        
        let request = URLRequest(url: components.url!)
        let (data, _) = try await session.data(for: request)
        
        return try JSONDecoder().decode([APIIngredient].self, from: data)
    }
    
    func getIngredient(id: String) async throws -> APIIngredient {
        let url = URL(string: "\(baseURL)/ingredients/\(id)")!
        let request = URLRequest(url: url)
        let (data, _) = try await session.data(for: request)
        
        return try JSONDecoder().decode(APIIngredient.self, from: data)
    }
    
    func createIngredient(_ ingredient: CreateIngredientRequest) async throws -> APIIngredient {
        let url = URL(string: "\(baseURL)/ingredients")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(ingredient)
        
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(APIIngredient.self, from: data)
    }
    
    func updateIngredient(id: String, _ ingredient: UpdateIngredientRequest) async throws -> APIIngredient {
        let url = URL(string: "\(baseURL)/ingredients/\(id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(ingredient)
        
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(APIIngredient.self, from: data)
    }
    
    func deleteIngredient(id: String) async throws {
        let url = URL(string: "\(baseURL)/ingredients/\(id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let (_, response) = try await session.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode != 204 {
            throw APIError.invalidResponse
        }
    }
    
    // MARK: - Dishes API
    
    func getDishes(search: String? = nil) async throws -> [APIDish] {
        var components = URLComponents(string: "\(baseURL)/dishes")!
        
        if let search = search, !search.isEmpty {
            components.queryItems = [URLQueryItem(name: "search", value: search)]
        }
        
        let request = URLRequest(url: components.url!)
        let (data, _) = try await session.data(for: request)
        
        return try JSONDecoder().decode([APIDish].self, from: data)
    }
    
    func getDish(id: String) async throws -> APIDish {
        let url = URL(string: "\(baseURL)/dishes/\(id)")!
        let request = URLRequest(url: url)
        let (data, _) = try await session.data(for: request)
        
        return try JSONDecoder().decode(APIDish.self, from: data)
    }
    
    func createDish(_ dish: CreateDishRequest) async throws -> APIDish {
        let url = URL(string: "\(baseURL)/dishes")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(dish)
        
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(APIDish.self, from: data)
    }
    
    func deleteDish(id: String) async throws {
        let url = URL(string: "\(baseURL)/dishes/\(id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let (_, response) = try await session.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode != 204 {
            throw APIError.invalidResponse
        }
    }
    
    // MARK: - Consumption API
    
    func getConsumptionLogs(days: Int = 30) async throws -> [APIConsumptionLog] {
        var components = URLComponents(string: "\(baseURL)/consumption")!
        components.queryItems = [URLQueryItem(name: "days", value: String(days))]
        
        let request = URLRequest(url: components.url!)
        let (data, _) = try await session.data(for: request)
        
        let decoder = JSONDecoder()
        return try decoder.decode([APIConsumptionLog].self, from: data)
    }
    
    func logConsumption(_ log: CreateConsumptionLogRequest) async throws -> APIConsumptionLog {
        let url = URL(string: "\(baseURL)/consumption")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(log)
        
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(APIConsumptionLog.self, from: data)
    }
    
    func getRecentIngredients(days: Int = 7) async throws -> [String] {
        var components = URLComponents(string: "\(baseURL)/consumption/recent-ingredients")!
        components.queryItems = [URLQueryItem(name: "days", value: String(days))]
        
        let request = URLRequest(url: components.url!)
        let (data, _) = try await session.data(for: request)
        
        return try JSONDecoder().decode([String].self, from: data)
    }
    
    // MARK: - Recommendations API
    
    func getRecommendations(days: Int = 7, limit: Int = 10) async throws -> [Recommendation] {
        var components = URLComponents(string: "\(baseURL)/recommendations")!
        components.queryItems = [
            URLQueryItem(name: "days", value: String(days)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        let request = URLRequest(url: components.url!)
        let (data, _) = try await session.data(for: request)
        
        return try JSONDecoder().decode([Recommendation].self, from: data)
    }
}

// MARK: - API Error
enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError:
            return "Failed to decode response"
        case .networkError:
            return "Network error occurred"
        }
    }
}