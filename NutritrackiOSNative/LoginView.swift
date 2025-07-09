//
//  LoginView.swift
//  NutritrackiOSNative
//
//  Created by Petar Petkov on 08/07/2025.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var authService = AuthService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isSignup = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Logo or App Name
                VStack(spacing: 16) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("NutriTrack")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Track your nutrition, discover variety")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Form
                VStack(spacing: 20) {
                    if isSignup {
                        TextField("Full Name", text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.words)
                    }
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    // Main Action Button
                    Button(action: {
                        Task {
                            await handleAuthentication()
                        }
                    }) {
                        HStack {
                            if authService.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            
                            Text(isSignup ? "Sign Up" : "Sign In")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue)
                        )
                    }
                    .disabled(authService.isLoading || email.isEmpty || password.isEmpty || (isSignup && name.isEmpty))
                    
                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                        
                        Text("or")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                    }
                    
                    // Google Sign In Button
                    Button(action: {
                        Task {
                            await handleGoogleSignIn()
                        }
                    }) {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(.black)
                            
                            Text("Continue with Google")
                                .foregroundColor(.black)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                .fill(Color.white)
                        )
                    }
                    .disabled(authService.isLoading)
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Switch between Sign In and Sign Up
                HStack {
                    Text(isSignup ? "Already have an account?" : "Don't have an account?")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        isSignup.toggle()
                        email = ""
                        password = ""
                        name = ""
                    }) {
                        Text(isSignup ? "Sign In" : "Sign Up")
                            .font(.footnote)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.bottom, 40)
            }
            .navigationBarHidden(true)
            .customErrorAlert(errorMessage: $errorMessage)
        }
    }
    
    private func handleAuthentication() async {
        do {
            if isSignup {
                try await authService.signup(email: email, password: password, name: name)
            } else {
                try await authService.login(email: email, password: password)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func handleGoogleSignIn() async {
        do {
            try await authService.loginWithGoogle()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    LoginView()
}