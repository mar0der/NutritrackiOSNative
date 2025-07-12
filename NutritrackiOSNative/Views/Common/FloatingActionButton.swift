//
//  FloatingActionButton.swift
//  NutritrackiOSNative
//
//  Created by Petar Petkov on 09/07/2025.
//

import SwiftUI

struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    let color: Color
    
    init(icon: String = "plus", color: Color = .blue, action: @escaping () -> Void) {
        self.icon = icon
        self.action = action
        self.color = color
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(color)
                .clipShape(Circle())
                .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.2), value: false)
    }
}

#Preview {
    VStack {
        Spacer()
        HStack {
            Spacer()
            FloatingActionButton(icon: "plus", color: .blue) {
                print("Floating button tapped")
            }
            .padding()
        }
    }
    .background(Color(.systemBackground))
}