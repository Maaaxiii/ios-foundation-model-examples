//
//  ChatView.swift
//  AIToolCall
//
//  Created by Maximilian Klem on 28.09.25.
//

import SwiftUI
import FoundationModels

struct ChatView: View {
    @State private var messageText = ""
    @State private var messages: [ChatMessageItem] = []
    @StateObject private var foundationService = FoundationModelsService()
    @State private var showingError = false
    @State private var availabilityStatus: SystemLanguageModel.Availability = .unavailable(.modelNotReady)
    
    var body: some View {
        NavigationView {
            switch availabilityStatus {
            case .available:
                chatInterface
            case .unavailable(.deviceNotEligible):
               unavailableView(message: "Sorry, you need an Apple Intelligence capable device") 
            case .unavailable(.appleIntelligenceNotEnabled):
                unavailableView(message: "AI Chat is unavailable because Apple Intelligence has not been turned on.")
            case .unavailable(.modelNotReady):
                unavailableView(message: "AI Chat isn't ready yet. Try again later.")
            default:
                unavailableView(message: "AI Chat is currently unavailable.")
            }
        }
        .onAppear {
            checkAvailability()
            foundationService.prewarm()
        }
    }
    
    private var chatInterface: some View {
        VStack {
            // Messages List
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                    }
                    
                    // Loading indicator
                    if foundationService.isLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("AI is thinking...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                }
                .padding()
            }
            
            // Input Area
            VStack(spacing: 8) {
                // Error message
                if let errorMessage = foundationService.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Dismiss") {
                            foundationService.errorMessage = nil
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                HStack {
                    TextField("Ask me anything...", text: $messageText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            sendMessage()
                        }
                        .disabled(foundationService.isLoading)
                    
                    Button(action: sendMessage) {
                        Image(systemName: foundationService.isLoading ? "stop.circle.fill" : "paperplane.fill")
                            .foregroundColor(foundationService.isLoading ? .red : .blue)
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !foundationService.isLoading)
                }
            }
            .padding()
        }
        .navigationTitle("AI Chat")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: clearChat) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .disabled(messages.isEmpty)
            }
        }
    }
    
    private func unavailableView(message: String) -> some View {
        VStack {
            Spacer()
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("AI Chat Unavailable")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top)
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
        }
        .navigationTitle("AI Chat")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private func checkAvailability() {
        availabilityStatus = foundationService.getAvailabilityStatus()
    }
    
    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        let newMessage = ChatMessageItem(
            text: text,
            isFromUser: true,
            timestamp: Date()
        )
        
        withAnimation(.easeInOut(duration: 0.3)) {
            messages.append(newMessage)
        }
        
        messageText = ""
        
        // Generate AI response using Foundation Models
        Task {
            let aiResponseText = await foundationService.generateChatResponse(for: text)
            
            await MainActor.run {
                let aiResponse = ChatMessageItem(
                    text: aiResponseText,
                    isFromUser: false,
                    timestamp: Date()
                )
                
                withAnimation(.easeInOut(duration: 0.3)) {
                    messages.append(aiResponse)
                }
            }
        }
    }
    
    private func clearChat() {
        withAnimation(.easeInOut(duration: 0.3)) {
            messages.removeAll()
            foundationService.clearChat()
        }
    }
}

struct ChatMessageItem: Identifiable {
    let id = UUID()
    let text: String
    let isFromUser: Bool
    let timestamp: Date
}

struct MessageBubble: View {
    let message: ChatMessageItem
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
            }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(message.isFromUser ? Color.blue : Color.gray.opacity(0.2))
                    )
                    .foregroundColor(message.isFromUser ? .white : .primary)
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if !message.isFromUser {
                Spacer()
            }
        }
    }
}

#Preview("Chat View") {
    ChatView()
}

#Preview("Chat View with Messages") {
    ChatView()
        .onAppear {
            // Add sample messages for preview
        }
}