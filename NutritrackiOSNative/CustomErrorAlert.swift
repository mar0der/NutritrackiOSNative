//
//  CustomErrorAlert.swift
//  NutritrackiOSNative
//
//  Created by Claude on 09/07/2025.
//

import SwiftUI

// MARK: - Custom Error Alert
struct CustomErrorAlert: View {
    let message: String
    let onDismiss: () -> Void
    @State private var isVisible = false
    
    // Configuration for message display
    private let maxDisplayLength = 80 // characters for single line display
    
    private var displayMessage: String {
        if message.count > maxDisplayLength {
            // Show first line/sentence that fits
            let truncated = String(message.prefix(maxDisplayLength))
            if let firstSentence = truncated.components(separatedBy: ".").first, firstSentence.count < maxDisplayLength {
                return firstSentence.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return truncated.trimmingCharacters(in: .whitespacesAndNewlines) + "..."
        }
        return message
    }
    
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissAlert()
                }
            
            // Alert content - Consistent size design
            VStack(spacing: 20) {
                // Error icon
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.red)
                }
                
                // Title
                Text("Oops!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                // Message - always single display format
                VStack(spacing: 8) {
                    Text(displayMessage)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    // Small copy button - always visible
                    Button(action: copyErrorToClipboard) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.on.clipboard")
                                .font(.caption)
                            Text("Copy Error")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.blue)
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal)
                
                // Dismiss button
                Button(action: dismissAlert) {
                    Text("Got it")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
            )
            .frame(maxWidth: 320)
            .scaleEffect(isVisible ? 1.0 : 0.8)
            .opacity(isVisible ? 1.0 : 0.0)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isVisible)
        }
        .onAppear {
            withAnimation {
                isVisible = true
            }
        }
    }
    
    private func dismissAlert() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
    
    private func copyErrorToClipboard() {
        UIPasteboard.general.string = message
        // Optional: Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}

// MARK: - View Extension for Easy Error Handling
extension View {
    func customErrorAlert(errorMessage: Binding<String?>) -> some View {
        self.overlay {
            if errorMessage.wrappedValue != nil {
                CustomErrorAlert(
                    message: errorMessage.wrappedValue ?? "",
                    onDismiss: { errorMessage.wrappedValue = nil }
                )
                .zIndex(1000)
            }
        }
    }
}

#Preview("Short Message") {
    VStack {
        Text("Preview Content")
    }
    .customErrorAlert(errorMessage: .constant("This is a short error message."))
}

#Preview("Long Message") {
    VStack {
        Text("Preview Content")
    }
    .customErrorAlert(errorMessage: .constant("This is a very long error message that should demonstrate the expand/collapse functionality. When the message exceeds the maximum character limit or number of lines, users will see a 'Show More' button that allows them to expand the full message. This ensures consistent design while providing access to complete error details when needed. The animation makes the transition smooth and the interface remains clean and professional."))
}