//
//  ChatView.swift
//  AIToolCall
//
//  Created by Maximilian Klem on 28.09.25.
//

import SwiftUI
import SwiftData
import FoundationModels

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var chatManager = ChatManager(modelContext: ModelContext(try! ModelContainer(for: Chat.self, ChatMessage.self)))
    @State private var messageText = ""
    @State private var availabilityStatus: SystemLanguageModel.Availability = .unavailable(.modelNotReady)
    @State private var showingNewChatAlert = false
    @State private var newChatTitle = ""
    
    var body: some View {
        NavigationView {
            switch availabilityStatus {
            case .available:
                if let currentChat = chatManager.currentChat {
                    chatInterface(for: currentChat)
                } else {
                    noChatSelectedView
                }
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
        }
        .alert("New Chat", isPresented: $showingNewChatAlert) {
            TextField("Chat Title", text: $newChatTitle)
            Button("Create") {
                createNewChat()
            }
            Button("Cancel", role: .cancel) {
                newChatTitle = ""
            }
        } message: {
            Text("Enter a title for your new chat")
        }
    }
    
    private func chatInterface(for chat: Chat) -> some View {
        VStack {
            // Chat Header
            HStack {
                VStack(alignment: .leading) {
                    Text(chat.title)
                        .font(.headline)
                    Text("\(chat.messages.count) messages")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("New Chat") {
                    showingNewChatAlert = true
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            Divider()
            
            // Messages List
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(chat.messages.sorted(by: { $0.timestamp < $1.timestamp })) { message in
                        MessageBubble(message: message)
                    }
                    
                    // Loading indicator
                    if chatManager.isLoading {
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
                if let errorMessage = chatManager.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Dismiss") {
                            chatManager.errorMessage = nil
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
                        .disabled(chatManager.isLoading)
                    
                    Button(action: sendMessage) {
                        Image(systemName: chatManager.isLoading ? "stop.circle.fill" : "paperplane.fill")
                            .foregroundColor(chatManager.isLoading ? .red : .blue)
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !chatManager.isLoading)
                }
            }
            .padding()
        }
        .navigationTitle("AI Chat")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button(action: clearChat) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .disabled(chat.messages.isEmpty)
                    
                    Button(action: { showingNewChatAlert = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
    
    private var noChatSelectedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "message.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Chat Selected")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start a new conversation or select an existing chat from the History tab")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Start New Chat") {
                showingNewChatAlert = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle("AI Chat")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingNewChatAlert = true }) {
                    Image(systemName: "plus")
                }
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
        availabilityStatus = chatManager.getAvailabilityStatus()
    }
    
    private func createNewChat() {
        let title = newChatTitle.isEmpty ? nil : newChatTitle
        let _ = chatManager.createNewChat(title: title)
        newChatTitle = ""
    }
    
    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        messageText = ""
        
        Task {
            await chatManager.sendMessage(text)
        }
    }
    
    private func clearChat() {
        chatManager.clearCurrentChat()
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
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
        .modelContainer(for: [Chat.self, ChatMessage.self], inMemory: true)
}