//
//  APIService.swift
//  NutritrackiOSNative
//
//  Created by Petar Petkov on 06/07/2025.
//  Updated for new API structure - 08/07/2025
//

import Foundation
import Combine

// MARK: - API Response Models
struct APIIngredient: Codable, Identifiable {
    let id: String
    let name: String
    let category: String
    let nutritionPer100g: APINutritionalInfo?
    let createdAt: String
    let updatedAt: String
}

struct APINutritionalInfo: Codable {
    let calories: Double?
    let protein: Double?
    let carbs: Double?
    let fat: Double?
    let fiber: Double?
}

struct APIDish: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let instructions: String?
    let servings: Int
    let userId: String
    let createdAt: String
    let updatedAt: String
    let ingredients: [APIDishIngredient]
}

struct APIDishIngredient: Codable {
    let id: String
    let dishId: String
    let ingredientId: String
    let quantity: Double
    let unit: String
    let ingredient: APIIngredient?
}

struct APIConsumptionLog: Codable, Identifiable {
    let id: String
    let userId: String
    let type: String
    let ingredientId: String?
    let dishId: String?
    let quantity: Double?
    let unit: String?
    let servings: Double?
    let consumedAt: String
    let createdAt: String
    let ingredient: APIIngredient?
    let dish: APIDish?
}

struct APIRecommendation: Codable {
    let dish: APIDish
    let score: Double
    let explanation: String
}

// MARK: - API Error Response Models
struct APIErrorResponse: Codable {
    let error: String?
    let message: String?
}

// MARK: - API Request Models
struct CreateIngredientRequest: Codable {
    let name: String
    let category: String
    let nutritionPer100g: APINutritionalInfo?
}

struct UpdateIngredientRequest: Codable {
    let name: String?
    let category: String?
    let nutritionPer100g: APINutritionalInfo?
}

struct CreateDishRequest: Codable {
    let name: String
    let description: String?
    let instructions: String?
    let servings: Int
    let ingredients: [CreateDishIngredientRequest]
}

struct CreateDishIngredientRequest: Codable {
    let ingredientId: String
    let quantity: Double
    let unit: String
}

struct UpdateDishRequest: Codable {
    let name: String?
    let description: String?
    let instructions: String?
    let servings: Int?
    let ingredients: [CreateDishIngredientRequest]?
}

struct CreateConsumptionLogRequest: Codable {
    let type: String
    let itemId: String
    let quantity: Double?
    let unit: String?
    let servings: Double?
    let consumedAt: String?
}

// MARK: - API Service
@MainActor
class APIService: ObservableObject {
    static let shared = APIService()
    
    private let baseURL: String
    private let session = URLSession.shared
    private let authService = AuthService.shared
    
    private init() {
        // Use new API server
        self.baseURL = "https://api.nerdstips.com/v1"
    }
    
    // MARK: - Helper Methods
    
    private func createAuthenticatedRequest(for url: URL, method: String = "GET") -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authService.getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    private func handleResponse<T: Codable>(_ data: Data, _ response: URLResponse, type: T.Type) throws -> T {
        if let httpResponse = response as? HTTPURLResponse {
            print("🔍 handleResponse: HTTP Status \(httpResponse.statusCode)")
            if httpResponse.statusCode == 401 {
                // Token expired, logout user
                Task { await authService.logout() }
                throw APIError.unauthorized
            }
            if httpResponse.statusCode >= 400 {
                print("❌ handleResponse: Error status \(httpResponse.statusCode)")
                // Try to parse structured error response
                if let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                    print("📋 handleResponse: Structured error - \(errorResponse)")
                    throw APIError.serverErrorWithMessage(httpResponse.statusCode, errorResponse.message ?? errorResponse.error ?? "Unknown error")
                } else if let errorMessage = String(data: data, encoding: .utf8) {
                    print("📋 handleResponse: Raw error - \(errorMessage)")
                    throw APIError.serverErrorWithMessage(httpResponse.statusCode, errorMessage)
                } else {
                    print("📋 handleResponse: No error message available")
                    throw APIError.serverError(httpResponse.statusCode)
                }
            }
        }
        
        print("🔧 handleResponse: Attempting to decode \(type)")
        do {
            let result = try JSONDecoder().decode(T.self, from: data)
            print("✅ handleResponse: Successfully decoded \(type)")
            return result
        } catch {
            print("❌ handleResponse: Decoding failed for \(type): \(error)")
            throw error
        }
    }
    
    // MARK: - Ingredients API
    
    func getIngredients() async throws -> [APIIngredient] {
        let url = URL(string: "\(baseURL)/ingredients")!
        let request = createAuthenticatedRequest(for: url)
        let (data, response) = try await session.data(for: request)
        
        return try handleResponse(data, response, type: [APIIngredient].self)
    }
    
    func getIngredient(id: String) async throws -> APIIngredient {
        let url = URL(string: "\(baseURL)/ingredients/\(id)")!
        let request = createAuthenticatedRequest(for: url)
        let (data, response) = try await session.data(for: request)
        
        return try handleResponse(data, response, type: APIIngredient.self)
    }
    
    func createIngredient(_ ingredient: CreateIngredientRequest) async throws -> APIIngredient {
        let url = URL(string: "\(baseURL)/ingredients")!
        var request = createAuthenticatedRequest(for: url, method: "POST")
        request.httpBody = try JSONEncoder().encode(ingredient)
        
        let (data, response) = try await session.data(for: request)
        return try handleResponse(data, response, type: APIIngredient.self)
    }
    
    func updateIngredient(id: String, _ ingredient: UpdateIngredientRequest) async throws -> APIIngredient {
        let url = URL(string: "\(baseURL)/ingredients/\(id)")!
        var request = createAuthenticatedRequest(for: url, method: "PUT")
        request.httpBody = try JSONEncoder().encode(ingredient)
        
        let (data, response) = try await session.data(for: request)
        return try handleResponse(data, response, type: APIIngredient.self)
    }
    
    func deleteIngredient(id: String) async throws {
        let url = URL(string: "\(baseURL)/ingredients/\(id)")!
        let request = createAuthenticatedRequest(for: url, method: "DELETE")
        
        let (_, response) = try await session.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode != 200 {
            throw APIError.invalidResponse
        }
    }
    
    // MARK: - Dishes API
    
    func getDishes() async throws -> [APIDish] {
        let url = URL(string: "\(baseURL)/dishes")!
        let request = createAuthenticatedRequest(for: url)
        let (data, response) = try await session.data(for: request)
        
        // Debug logging to see what's actually happening
        print("🌐 Dishes API URL: \(url)")
        print("🔐 Auth token present: \(authService.getAuthToken() != nil)")
        print("📊 Response status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        print("📏 Response data size: \(data.count) bytes")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📄 Raw response: \(responseString)")
        }
        
        // Handle empty response
        if data.isEmpty {
            print("⚠️ Empty response, returning empty array")
            return []
        }
        
        // Check HTTP status
        if let httpResponse = response as? HTTPURLResponse {
            print("🔍 HTTP Status: \(httpResponse.statusCode)")
            if httpResponse.statusCode != 200 {
                print("❌ Non-200 status code received")
            }
        }
        
        do {
            let result = try handleResponse(data, response, type: [APIDish].self)
            print("✅ Successfully decoded \(result.count) dishes")
            return result
        } catch {
            print("❌ Decoding failed: \(error)")
            if let decodingError = error as? DecodingError {
                print("📋 Decoding error details:")
                switch decodingError {
                case .dataCorrupted(let context):
                    print("  Data corrupted: \(context)")
                case .keyNotFound(let key, let context):
                    print("  Key '\(key)' not found: \(context)")
                case .typeMismatch(let type, let context):
                    print("  Type mismatch for \(type): \(context)")
                case .valueNotFound(let type, let context):
                    print("  Value not found for \(type): \(context)")
                @unknown default:
                    print("  Unknown decoding error")
                }
            }
            
            // If decoding fails, try to check if it's a null response
            if let responseString = String(data: data, encoding: .utf8) {
                print("🔍 Trying to handle special cases for response: \(responseString)")
                
                // Check if response is null or empty object
                if responseString.trimmingCharacters(in: .whitespacesAndNewlines) == "null" ||
                   responseString.trimmingCharacters(in: .whitespacesAndNewlines) == "{}" {
                    print("⚠️ Server returned null/empty object, treating as empty array")
                    return []
                }
            }
            
            throw error
        }
    }
    
    func getDish(id: String) async throws -> APIDish {
        let url = URL(string: "\(baseURL)/dishes/\(id)")!
        let request = createAuthenticatedRequest(for: url)
        let (data, response) = try await session.data(for: request)
        
        return try handleResponse(data, response, type: APIDish.self)
    }
    
    func createDish(_ dish: CreateDishRequest) async throws -> APIDish {
        let url = URL(string: "\(baseURL)/dishes")!
        var request = createAuthenticatedRequest(for: url, method: "POST")
        request.httpBody = try JSONEncoder().encode(dish)
        
        let (data, response) = try await session.data(for: request)
        return try handleResponse(data, response, type: APIDish.self)
    }
    
    func updateDish(id: String, _ dish: UpdateDishRequest) async throws -> APIDish {
        let url = URL(string: "\(baseURL)/dishes/\(id)")!
        var request = createAuthenticatedRequest(for: url, method: "PUT")
        request.httpBody = try JSONEncoder().encode(dish)
        
        let (data, response) = try await session.data(for: request)
        return try handleResponse(data, response, type: APIDish.self)
    }
    
    func deleteDish(id: String) async throws {
        let url = URL(string: "\(baseURL)/dishes/\(id)")!
        let request = createAuthenticatedRequest(for: url, method: "DELETE")
        
        let (_, response) = try await session.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode != 200 {
            throw APIError.invalidResponse
        }
    }
    
    // MARK: - Consumption API
    
    func getConsumptionLogs(days: Int = 7, startDate: String? = nil, endDate: String? = nil) async throws -> [APIConsumptionLog] {
        var components = URLComponents(string: "\(baseURL)/consumption")!
        var queryItems: [URLQueryItem] = []
        
        if let startDate = startDate, let endDate = endDate {
            queryItems.append(URLQueryItem(name: "startDate", value: startDate))
            queryItems.append(URLQueryItem(name: "endDate", value: endDate))
        } else {
            queryItems.append(URLQueryItem(name: "days", value: String(days)))
        }
        
        components.queryItems = queryItems
        
        let request = createAuthenticatedRequest(for: components.url!)
        let (data, response) = try await session.data(for: request)
        
        return try handleResponse(data, response, type: [APIConsumptionLog].self)
    }
    
    func logConsumption(_ log: CreateConsumptionLogRequest) async throws -> APIConsumptionLog {
        let url = URL(string: "\(baseURL)/consumption")!
        var request = createAuthenticatedRequest(for: url, method: "POST")
        request.httpBody = try JSONEncoder().encode(log)
        
        let (data, response) = try await session.data(for: request)
        return try handleResponse(data, response, type: APIConsumptionLog.self)
    }
    
    func deleteConsumptionLog(id: String) async throws {
        let url = URL(string: "\(baseURL)/consumption/\(id)")!
        let request = createAuthenticatedRequest(for: url, method: "DELETE")
        
        let (_, response) = try await session.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode != 200 {
            throw APIError.invalidResponse
        }
    }
    
    // MARK: - Recommendations API
    
    func getRecommendations(days: Int = 7, limit: Int = 10) async throws -> [APIRecommendation] {
        var components = URLComponents(string: "\(baseURL)/recommendations/dishes")!
        components.queryItems = [
            URLQueryItem(name: "days", value: String(days)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        let request = createAuthenticatedRequest(for: components.url!)
        let (data, response) = try await session.data(for: request)
        
        return try handleResponse(data, response, type: [APIRecommendation].self)
    }
    
    // MARK: - Health Check
    
    func healthCheck() async throws -> Bool {
        let url = URL(string: "\(baseURL)/health")!
        let request = URLRequest(url: url)
        
        let (_, response) = try await session.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            return httpResponse.statusCode == 200
        }
        return false
    }
}

// MARK: - API Error
enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError
    case networkError
    case unauthorized
    case serverError(Int)
    case serverErrorWithMessage(Int, String)
    
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
        case .unauthorized:
            return "Authentication required"
        case .serverError(let code):
            return "Server error: \(code)"
        case .serverErrorWithMessage(let code, let message):
            // Handle common error patterns with user-friendly messages
            if message.contains("Unique constraint failed") || message.contains("already exists") {
                return "An ingredient with this name already exists. Please choose a different name."
            }
            if message.contains("validation") || message.contains("required") {
                return "Please check that all required fields are filled correctly."
            }
            if message.contains("unauthorized") || message.contains("authentication") {
                return "Authentication required. Please log in again."
            }
            if code == 400 {
                return "Invalid request. Please check your input and try again."
            }
            if code == 404 {
                return "Resource not found."
            }
            if code >= 500 {
                return "Server error. Please try again later."
            }
            return "Error: \(message)"
        }
    }
}