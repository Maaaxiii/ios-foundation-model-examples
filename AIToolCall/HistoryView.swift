//
//  HistoryView.swift
//  AIToolCall
//
//  Created by Maximilian Klem on 28.09.25.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Chat.updatedAt, order: .reverse) private var chats: [Chat]
    @StateObject private var chatManager = ChatManager(modelContext: ModelContext(try! ModelContainer(for: Chat.self, ChatMessage.self)))
    @State private var showingDeleteConfirmation = false
    @State private var chatToDelete: Chat?
    @State private var searchText = ""

    var filteredChats: [Chat] {
        if searchText.isEmpty {
            return chats
        } else {
            return chats.filter { chat in
                chat.title.localizedCaseInsensitiveContains(searchText) ||
                chat.previewText.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                if filteredChats.isEmpty {
                    emptyStateView
                } else {
                    chatListView
                }
            }
            .navigationTitle("Chat History")
            .searchable(text: $searchText, prompt: "Search chats...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { createNewChat() }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .confirmationDialog("Delete Chat", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    if let chat = chatToDelete {
                        deleteChat(chat)
                    }
                }
                Button("Cancel", role: .cancel) {
                    chatToDelete = nil
                }
            } message: {
                Text("Are you sure you want to delete this chat? This action cannot be undone.")
            }
            .onAppear {
                // ChatManager is already initialized
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "message")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Chats Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start a new conversation to see your chat history here")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Start New Chat") {
                createNewChat()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private var chatListView: some View {
        List {
            ForEach(filteredChats) { chat in
                ChatRowView(
                    chat: chat,
                    onTap: { loadChat(chat) },
                    onDelete: { 
                        chatToDelete = chat
                        showingDeleteConfirmation = true
                    },
                    onRename: { renameChat(chat) }
                )
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private func createNewChat() {
        let newChat = chatManager.createNewChat(title: "New Chat")
        loadChat(newChat)
    }
    
    private func loadChat(_ chat: Chat) {
        chatManager.loadChat(chat)
        // Navigate to ChatView - this will be handled by the TabView
        // The ChatView will automatically load the current chat from ChatManager
    }
    
    private func deleteChat(_ chat: Chat) {
        chatManager.deleteChat(chat)
        chatToDelete = nil
    }
    
    private func renameChat(_ chat: Chat) {
        // This could be implemented with another alert or inline editing
        // For now, we'll use a simple approach
        let alert = UIAlertController(title: "Rename Chat", message: "Enter new title", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = chat.title
        }
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            if let newTitle = alert.textFields?.first?.text, !newTitle.isEmpty {
                chatManager.updateChatTitle(chat, newTitle: newTitle)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
}

struct ChatRowView: View {
    let chat: Chat
    let onTap: () -> Void
    let onDelete: () -> Void
    let onRename: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(chat.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(chat.previewText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    Text(chat.updatedAt, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    Button(action: onRename) {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview("History View") {
    HistoryView()
        .modelContainer(for: [Chat.self, ChatMessage.self], inMemory: true)
}