//
//  FoundationModelsService.swift
//  AIToolCall
//
//  Created by Maximilian Klem on 28.09.25.
//

import Foundation
import Combine
import FoundationModels

/// Service for interacting with Apple Foundation Models
@MainActor
class FoundationModelsService: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let model = SystemLanguageModel.default
    private var session: LanguageModelSession?
    private var tools: [any Tool] = []
    
    init(tools: [any Tool] = []) {
        self.tools = tools
        // Initialize the language model session
        self.session = LanguageModelSession(
            tools: tools,
            instructions: Instructions {
                """
                You are a friendly, helpful AI assistant with access to various tools. Your goal is to be as helpful as possible while maintaining safety and appropriateness.
                
                Guidelines:
                - Always try to help users with their questions and requests
                - Be conversational, friendly, and engaging
                - When you have access to tools (weather, time, memory), use them to provide accurate information
                - If you can't fulfill a request directly, suggest alternatives or explain what you can help with instead
                - Be creative and helpful in your responses
                - Avoid being overly cautious or restrictive unless there's a clear safety concern
                - If a user asks about something you can't do, explain what you can do instead
                
                Available tools: \(tools.map { $0.name }.joined(separator: ", "))
                
                Remember: Your primary goal is to be helpful and assist the user in any way you can.
                """
            }
        )
    }
    
    func updateTools(_ newTools: [any Tool]) {
        self.tools = newTools
        // Recreate session with new tools
        self.session = LanguageModelSession(
            tools: newTools,
            instructions: Instructions {
                """
                You are a friendly, helpful AI assistant with access to various tools. Your goal is to be as helpful as possible while maintaining safety and appropriateness.
                
                Guidelines:
                - Always try to help users with their questions and requests
                - Be conversational, friendly, and engaging
                - When you have access to tools (weather, time, memory), use them to provide accurate information
                - If you can't fulfill a request directly, suggest alternatives or explain what you can help with instead
                - Be creative and helpful in your responses
                - Avoid being overly cautious or restrictive unless there's a clear safety concern
                - If a user asks about something you can't do, explain what you can do instead
                
                Available tools: \(newTools.map { $0.name }.joined(separator: ", "))
                
                Remember: Your primary goal is to be helpful and assist the user in any way you can.
                """
            }
        )
    }
    
    /// Generate a chat response using Apple Foundation Models
    func generateChatResponse(for userMessage: String) async -> String {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let session = session else {
                throw NSError(domain: "FoundationModelsService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Session not initialized"])
            }
            
            let stream = session.streamResponse(
                generating: String.self,
                includeSchemaInPrompt: false
            ) {
                userMessage
            }
            
            var fullResponse = ""
            for try await partialResponse in stream {
                fullResponse = partialResponse.content
            }
            
            isLoading = false
            
            if !fullResponse.isEmpty {
                return fullResponse
            } else {
                errorMessage = "The model did not return any text."
                return "I'm sorry, I couldn't generate a response."
            }
            
        } catch {
            isLoading = false
            errorMessage = "Error: \(error.localizedDescription)"
            return "I'm sorry, there was an error generating a response."
        }
    }
    
    /// Check if Foundation Models are available
    func checkAvailability() -> Bool {
        return model.availability == .available
    }
    
    /// Get availability status for detailed error handling
    func getAvailabilityStatus() -> SystemLanguageModel.Availability {
        return model.availability
    }
    
    /// Resets the chat history
    func clearChat() {
        session = LanguageModelSession(
            tools: tools,
            instructions: Instructions {
                """
                You are a friendly, helpful AI assistant with access to various tools. Your goal is to be as helpful as possible while maintaining safety and appropriateness.
                
                Guidelines:
                - Always try to help users with their questions and requests
                - Be conversational, friendly, and engaging
                - When you have access to tools (weather, time, memory), use them to provide accurate information
                - If you can't fulfill a request directly, suggest alternatives or explain what you can help with instead
                - Be creative and helpful in your responses
                - Avoid being overly cautious or restrictive unless there's a clear safety concern
                - If a user asks about something you can't do, explain what you can do instead
                
                Available tools: \(tools.map { $0.name }.joined(separator: ", "))
                
                Remember: Your primary goal is to be helpful and assist the user in any way you can.
                """
            }
        )
    }
    
    /// Prewarm the model for better performance
    func prewarm() {
        session?.prewarm()
    }
}
