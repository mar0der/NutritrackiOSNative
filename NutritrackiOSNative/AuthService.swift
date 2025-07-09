//
//  AuthService.swift
//  NutritrackiOSNative
//
//  Created by Petar Petkov on 08/07/2025.
//

import Foundation
import SwiftUI
import Security
import Combine

// MARK: - Authentication Models
struct AuthResponse: Codable {
    let user: User
    let token: String
}

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let name: String
    let avatar: String?
    let provider: String
    let emailVerified: Bool
    let preferences: UserPreferences?
}

struct UserPreferences: Codable {
    let id: String
    let userId: String
    let avoidPeriodDays: Int
    let dietaryRestrictions: [String]
    let createdAt: String
    let updatedAt: String
}

// MARK: - Authentication Requests
struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct SignupRequest: Codable {
    let email: String
    let password: String
    let name: String
}

// MARK: - Keychain Helper
class KeychainHelper {
    static let shared = KeychainHelper()
    
    private let service = "com.nutritrack.tokens"
    private let tokenKey = "jwt_token"
    
    func saveToken(_ token: String) {
        let data = token.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenKey,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func getToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess, let data = result as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    func deleteToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenKey
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Authentication Service
@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    
    private let baseURL = "https://api.nerdstips.com/v1"
    private let session = URLSession.shared
    private let keychain = KeychainHelper.shared
    
    private init() {
        checkAuthStatus()
    }
    
    func checkAuthStatus() {
        if let token = keychain.getToken() {
            Task {
                await getCurrentUser()
            }
        }
    }
    
    // MARK: - Authentication Methods
    
    func login(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let url = URL(string: "\(baseURL)/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let loginRequest = LoginRequest(email: email, password: password)
        request.httpBody = try JSONEncoder().encode(loginRequest)
        
        let (data, response) = try await session.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 200 {
                let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                keychain.saveToken(authResponse.token)
                currentUser = authResponse.user
                isAuthenticated = true
            } else {
                throw AuthError.invalidCredentials
            }
        }
    }
    
    func signup(email: String, password: String, name: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let url = URL(string: "\(baseURL)/auth/signup")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let signupRequest = SignupRequest(email: email, password: password, name: name)
        request.httpBody = try JSONEncoder().encode(signupRequest)
        
        let (data, response) = try await session.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 201 {
                let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                keychain.saveToken(authResponse.token)
                currentUser = authResponse.user
                isAuthenticated = true
            } else {
                throw AuthError.signupFailed
            }
        }
    }
    
    func loginWithGoogle() async throws {
        let googleOAuth = GoogleOAuthService.shared
        try await googleOAuth.signInWithGoogle()
    }
    
    func getCurrentUser() async {
        guard let token = keychain.getToken() else {
            isAuthenticated = false
            return
        }
        
        do {
            let url = URL(string: "\(baseURL)/auth/me")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    let user = try JSONDecoder().decode(User.self, from: data)
                    currentUser = user
                    isAuthenticated = true
                } else {
                    // Token is invalid
                    await logout()
                }
            }
        } catch {
            await logout()
        }
    }
    
    func logout() async {
        keychain.deleteToken()
        currentUser = nil
        isAuthenticated = false
        
        // Optional: Call API logout endpoint
        if let token = keychain.getToken() {
            do {
                let url = URL(string: "\(baseURL)/auth/logout")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                
                let (_, _) = try await session.data(for: request)
            } catch {
                // Ignore logout API errors
            }
        }
    }
    
    func getAuthToken() -> String? {
        return keychain.getToken()
    }
}

// MARK: - Authentication Errors
enum AuthError: Error, LocalizedError {
    case invalidCredentials
    case signupFailed
    case networkError
    case notImplemented
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .signupFailed:
            return "Failed to create account"
        case .networkError:
            return "Network error occurred"
        case .notImplemented:
            return "Feature not implemented yet"
        }
    }
}