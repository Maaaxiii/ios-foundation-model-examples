//
//  DevView.swift
//  AIToolCall
//
//  Created by Maximilian Klem on 28.09.25.
//

import SwiftUI

#if DEBUG
struct DevView: View {
    @State private var counter = 0
    @State private var colorIndex = 0
    @State private var isAnimating = false
    
    private let colors: [Color] = [.blue, .green, .red, .orange, .purple, .pink]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🔥 Hot Reload Demo")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Edit this file to see hot reload in action!")
                .font(.headline)
                .foregroundColor(.secondary)
            
            // Counter demo
            VStack {
                Text("Counter: \(counter)")
                    .font(.title)
                    .foregroundColor(colors[colorIndex % colors.count])
                
                Button("Increment") {
                    withAnimation(.spring()) {
                        counter += 1
                        colorIndex += 1
                        isAnimating.toggle()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .scaleEffect(isAnimating ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: isAnimating)
            
            // Color demo
            RoundedRectangle(cornerRadius: 20)
                .fill(colors[colorIndex % colors.count])
                .frame(width: 200, height: 100)
                .overlay(
                    Text("Color \(colorIndex + 1)")
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                )
                .rotationEffect(.degrees(isAnimating ? 5 : -5))
                .animation(.easeInOut(duration: 0.5), value: isAnimating)
            
            // Status indicator
            HStack {
                Circle()
                    .fill(.green)
                    .frame(width: 12, height: 12)
                Text("Hot Reload Active")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .hotReload() // Enable hot reload for this view
    }
}

#Preview("Dev View") {
    DevView()
}

#Preview("Dev View Dark") {
    DevView()
        .preferredColorScheme(.dark)
}
#endif