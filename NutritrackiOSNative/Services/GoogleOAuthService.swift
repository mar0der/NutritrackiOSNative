//
//  GoogleOAuthService.swift
//  NutritrackiOSNative
//
//  Created by Petar Petkov on 08/07/2025.
//

import Foundation
import SwiftUI
import UIKit
import AuthenticationServices
import Combine

// MARK: - Google OAuth Service
class GoogleOAuthService: NSObject, ObservableObject {
    static let shared = GoogleOAuthService()
    
    private let baseURL = "https://api.nerdstips.com/v1"
    private let authService = AuthService.shared
    
    private override init() {
        super.init()
    }
    
    // MARK: - OAuth Methods
    
    func signInWithGoogle() async throws {
        // Create the OAuth URL with mobile parameter and state to preserve mobile flag
        let authURL = URL(string: "\(baseURL)/auth/google?mobile=true&platform=ios&state=mobile_ios")!
        print("📱 Starting OAuth with URL: \(authURL)")
        print("📱 Expected callback scheme: nutritrack://")
        
        // Use ASWebAuthenticationSession for OAuth flow
        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: "nutritrack"
            ) { callbackURL, error in
                Task {
                    if let error = error {
                        print("❌ OAuth error: \(error.localizedDescription)")
                        if let authError = error as? ASWebAuthenticationSessionError {
                            switch authError.code {
                            case .canceledLogin:
                                print("🚫 OAuth was cancelled by user")
                            case .presentationContextNotProvided:
                                print("❌ Presentation context not provided")
                            case .presentationContextInvalid:
                                print("❌ Presentation context invalid")
                            @unknown default:
                                print("❌ Unknown ASWebAuthenticationSessionError: \(authError.code.rawValue)")
                            }
                        }
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    guard let callbackURL = callbackURL else {
                        print("❌ No callback URL received")
                        continuation.resume(throwing: AuthError.networkError)
                        return
                    }
                    
                    print("📱 Received callback URL: \(callbackURL)")
                    
                    // Extract token from callback URL
                    if let token = self.extractTokenFromURL(callbackURL) {
                        print("✅ Successfully extracted token from callback")
                        // Save token and get user info
                        await self.handleGoogleCallback(token: token)
                        continuation.resume()
                    } else {
                        print("❌ Failed to extract token from callback URL")
                        continuation.resume(throwing: AuthError.invalidCredentials)
                    }
                }
            }
            
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            
            print("📱 Starting ASWebAuthenticationSession...")
            if session.start() {
                print("✅ ASWebAuthenticationSession started successfully")
            } else {
                print("❌ Failed to start ASWebAuthenticationSession")
                continuation.resume(throwing: AuthError.networkError)
            }
        }
    }
    
    private func extractTokenFromURL(_ url: URL) -> String? {
        // Parse the callback URL to extract the JWT token
        // Expected format: nutritrack://auth/callback?token=JWT_TOKEN
        print("📱 OAuth Callback URL: \(url)")
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        return components?.queryItems?.first { $0.name == "token" }?.value
    }
    
    private func handleGoogleCallback(token: String) async {
        // Save token to keychain
        KeychainHelper.shared.saveToken(token)
        
        // Get user info
        await authService.getCurrentUser()
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding
extension GoogleOAuthService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Return the key window
        print("📱 Providing presentation anchor for OAuth session")
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            print("❌ No window found for presentation anchor")
            return ASPresentationAnchor()
        }
        print("✅ Using window: \(window)")
        return window
    }
}