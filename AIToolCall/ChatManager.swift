//
//  ChatManager.swift
//  AIToolCall
//
//  Created by Maximilian Klem on 28.09.25.
//

import Foundation
import SwiftData
import Combine
import FoundationModels

@MainActor
class ChatManager: ObservableObject {
    @Published var currentChat: Chat?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let modelContext: ModelContext
    private let foundationService: FoundationModelsService
    private let toolManager: ToolManager
    
    init(modelContext: ModelContext, toolManager: ToolManager) {
        self.modelContext = modelContext
        self.toolManager = toolManager
        self.foundationService = FoundationModelsService(tools: toolManager.availableTools)
    }
    
    func updateTools() {
        foundationService.updateTools(toolManager.availableTools)
    }
    
    // MARK: - Chat Management
    
    func createNewChat(title: String? = nil) -> Chat {
        let chatTitle = title ?? "New Chat"
        let newChat = Chat(title: chatTitle)
        modelContext.insert(newChat)
        
        do {
            try modelContext.save()
            currentChat = newChat
            return newChat
        } catch {
            errorMessage = "Failed to create new chat: \(error.localizedDescription)"
            return newChat
        }
    }
    
    func loadChat(_ chat: Chat) {
        currentChat = chat
        foundationService.clearChat() // Clear the AI service state
    }
    
    func deleteChat(_ chat: Chat) {
        if currentChat?.id == chat.id {
            currentChat = nil
        }
        
        modelContext.delete(chat)
        
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to delete chat: \(error.localizedDescription)"
        }
    }
    
    func updateChatTitle(_ chat: Chat, newTitle: String) {
        chat.title = newTitle
        chat.updatedAt = Date()
        
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to update chat title: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Message Management
    
    func sendMessage(_ text: String) async {
        guard let chat = currentChat else { return }
        
        // Add user message
        let userMessage = ChatMessage(text: text, isFromUser: true, chat: chat)
        chat.messages.append(userMessage)
        chat.updatedAt = Date()
        
        // Save user message
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to save message: \(error.localizedDescription)"
            return
        }
        
        // Generate AI response
        isLoading = true
        let aiResponseText = await foundationService.generateChatResponse(for: text)
        isLoading = false
        
        // Add AI response
        let aiMessage = ChatMessage(text: aiResponseText, isFromUser: false, chat: chat)
        chat.messages.append(aiMessage)
        chat.updatedAt = Date()
        
        // Save AI response
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to save AI response: \(error.localizedDescription)"
        }
        
        // Generate title after first exchange (when we have 2 messages: user + AI)
        if chat.messages.count == 2 {
            await generateChatTitle(for: chat)
        }
    }
    
    func clearCurrentChat() {
        guard let chat = currentChat else { return }
        
        chat.messages.removeAll()
        chat.updatedAt = Date()
        foundationService.clearChat()
        
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to clear chat: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Helper Methods
    
    private func generateChatTitle() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return "Chat \(formatter.string(from: Date()))"
    }
    
    private func generateChatTitle(for chat: Chat) async {
        // Only generate title if we have exactly 2 messages (user + AI response)
        guard chat.messages.count == 2 else { return }
        
        let userMessage = chat.messages.first { $0.isFromUser }?.text ?? ""
        let aiMessage = chat.messages.first { !$0.isFromUser }?.text ?? ""
        
        // Create a prompt for title generation
        let titlePrompt = """
        Based on this conversation, create a short, descriptive title (maximum 4-5 words) that captures the main topic or question:
        
        User: \(userMessage)
        Assistant: \(aiMessage)
        
        Return only the title, nothing else.
        """
        
        // Generate title using Foundation Model
        let generatedTitle = await foundationService.generateChatResponse(for: titlePrompt)
        
        // Clean up the title (remove quotes, extra whitespace, etc.)
        let cleanTitle = generatedTitle
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "'", with: "")
        
        // Update the chat title if we got a valid response
        if !cleanTitle.isEmpty && cleanTitle.count <= 50 {
            chat.title = cleanTitle
            chat.updatedAt = Date()
            
            do {
                try modelContext.save()
            } catch {
                errorMessage = "Failed to update chat title: \(error.localizedDescription)"
            }
        }
    }
    
    func getAvailabilityStatus() -> SystemLanguageModel.Availability {
        return foundationService.getAvailabilityStatus()
    }
}