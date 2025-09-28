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
    @ObservedObject var chatManager: ChatManager
    @State private var showingDeleteConfirmation = false
    @State private var chatToDelete: Chat?
    @State private var searchText = ""
    @State private var selectedChats: Set<Chat.ID> = []
    @State private var isEditMode = false
    @Binding var selectedTab: Int

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
    
    var groupedChats: [(String, [Chat])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredChats) { chat in
            if calendar.isDateInToday(chat.updatedAt) {
                return "Today"
            } else if calendar.isDateInYesterday(chat.updatedAt) {
                return "Yesterday"
            } else if calendar.dateInterval(of: .weekOfYear, for: chat.updatedAt)?.contains(Date()) == true {
                return "This Week"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM yyyy"
                return formatter.string(from: chat.updatedAt)
            }
        }
        
        return grouped.sorted { first, second in
            let order = ["Today", "Yesterday", "This Week"]
            let firstIndex = order.firstIndex(of: first.key) ?? Int.max
            let secondIndex = order.firstIndex(of: second.key) ?? Int.max
            
            if firstIndex != Int.max && secondIndex != Int.max {
                return firstIndex < secondIndex
            } else if firstIndex != Int.max {
                return true
            } else if secondIndex != Int.max {
                return false
            } else {
                return first.key > second.key // For month/year sections, newer first
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
                ToolbarItem(placement: .navigationBarLeading) {
                    if !filteredChats.isEmpty {
                        Button(isEditMode ? "Done" : "Edit") {
                            isEditMode.toggle()
                            if !isEditMode {
                                selectedChats.removeAll()
                            }
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditMode {
                        Button("Delete All") {
                            // Delete all selected chats
                            for chatId in selectedChats {
                                if let chat = chats.first(where: { $0.id == chatId }) {
                                    chatManager.deleteChat(chat)
                                }
                            }
                            selectedChats.removeAll()
                            isEditMode = false
                        }
                        .disabled(selectedChats.isEmpty)
                    } else {
                        Button(action: { createNewChat() }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .confirmationDialog("Delete Chat", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
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
                // ChatManager is now passed from ContentView
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
        List(selection: $selectedChats) {
            ForEach(groupedChats, id: \.0) { sectionTitle, chats in
                Section(sectionTitle) {
                    ForEach(chats) { chat in
                        ChatRowView(
                            chat: chat,
                            onTap: { 
                                if isEditMode {
                                    // Toggle selection in edit mode
                                    if selectedChats.contains(chat.id) {
                                        selectedChats.remove(chat.id)
                                    } else {
                                        selectedChats.insert(chat.id)
                                    }
                                } else {
                                    loadChat(chat)
                                }
                            }
                        )
                        .swipeActions(edge: .trailing, allowsFullSwipe: !isEditMode) {
                            Button("Delete", role: .destructive) {
                                chatToDelete = chat
                                showingDeleteConfirmation = true
                            }
                            
                            Button("Rename") {
                                renameChat(chat)
                            }
                            .tint(.blue)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button("Pin") {
                                // TODO: Implement pin functionality
                            }
                            .tint(.orange)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            // Native pull-to-refresh functionality
            // The @Query will automatically refresh when data changes
        }
        .environment(\.editMode, isEditMode ? .constant(.active) : .constant(.inactive))
    }
    
    private func createNewChat() {
        let newChat = chatManager.createNewChat(title: "New Chat")
        loadChat(newChat)
    }
    
    private func loadChat(_ chat: Chat) {
        chatManager.loadChat(chat)
        // Switch to Chat tab
        selectedTab = 0
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
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Chat icon/avatar placeholder
                Circle()
                    .fill(Color.blue.gradient)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: "message.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 18))
                    }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(chat.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(chat.previewText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    Text(chat.updatedAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Native disclosure indicator
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Rename") {
                // This will be handled by the parent view
            }
            
            Button("Delete", role: .destructive) {
                // This will be handled by the parent view
            }
            
            Button("Pin") {
                // TODO: Implement pin functionality
            }
        }
    }
}

#Preview("History View") {
    HistoryView(chatManager: ChatManager(modelContext: ModelContext(try! ModelContainer(for: Chat.self, ChatMessage.self))), selectedTab: .constant(1))
        .modelContainer(for: [Chat.self, ChatMessage.self], inMemory: true)
}