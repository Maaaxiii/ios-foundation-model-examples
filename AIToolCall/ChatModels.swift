//
//  ChatModels.swift
//  AIToolCall
//
//  Created by Maximilian Klem on 28.09.25.
//

import Foundation
import SwiftData

@Model
final class Chat {
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var messages: [ChatMessage]
    
    init(title: String) {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.updatedAt = Date()
        self.messages = []
    }
    
    var lastMessage: ChatMessage? {
        messages.sorted(by: { $0.timestamp < $1.timestamp }).last
    }
    
    var previewText: String {
        if let lastMessage = lastMessage {
            return lastMessage.text
        }
        return "No messages yet"
    }
}

@Model
final class ChatMessage {
    var id: UUID
    var text: String
    var isFromUser: Bool
    var timestamp: Date
    var chat: Chat?
    
    init(text: String, isFromUser: Bool, chat: Chat? = nil) {
        self.id = UUID()
        self.text = text
        self.isFromUser = isFromUser
        self.timestamp = Date()
        self.chat = chat
    }
}