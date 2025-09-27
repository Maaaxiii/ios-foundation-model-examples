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
    
    init() {
        // Initialize the language model session
        self.session = LanguageModelSession(
            instructions: Instructions {
                "You are a helpful AI assistant. Provide clear, concise, and helpful responses to user questions."
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
            instructions: Instructions {
                "You are a helpful AI assistant. Provide clear, concise, and helpful responses to user questions."
            }
        )
    }
    
    /// Prewarm the model for better performance
    func prewarm() {
        session?.prewarm()
    }
}
