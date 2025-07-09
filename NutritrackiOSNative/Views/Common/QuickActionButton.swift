//
//  QuickActionButton.swift
//  NutritrackiOSNative
//
//  Created by Petar Petkov on 06/07/2025.
//

import SwiftUI

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