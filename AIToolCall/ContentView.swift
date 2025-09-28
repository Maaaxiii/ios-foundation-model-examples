//
//  ContentView.swift
//  AIToolCall
//
//  Created by Maximilian Klem on 28.09.25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    @State private var selectedTab = 0
    @State private var sharedChatManager: ChatManager?
    @StateObject private var sharedToolManager = ToolManager()
    #if DEBUG
    @StateObject private var hotReloadHelper = HotReloadHelper()
    #endif

    var body: some View {
        Group {
            if let chatManager = sharedChatManager {
                TabView(selection: $selectedTab) {
                    ChatView(chatManager: chatManager)
                        .tabItem {
                            Image(systemName: "message")
                            Text("Chat")
                        }
                        .tag(0)
                    
                    HistoryView(chatManager: chatManager, selectedTab: $selectedTab)
                        .tabItem {
                            Image(systemName: "clock.arrow.circlepath")
                            Text("History")
                        }
                        .tag(1)
                    
                    SettingsView(toolManager: sharedToolManager) {
                        chatManager.updateTools()
                    }
                        .tabItem {
                            Image(systemName: "gear")
                            Text("Settings")
                        }
                        .tag(2)
                }
                #if DEBUG
                .id(hotReloadHelper.reloadTrigger)
                #endif
            } else {
                // Loading state while ChatManager is being initialized
                ProgressView("Initializing...")
                    .onAppear {
                        sharedChatManager = ChatManager(modelContext: modelContext, toolManager: sharedToolManager)
                    }
            }
        }
    }
}

#Preview("Main App") {
    ContentView()
        .modelContainer(for: [Item.self, Chat.self, ChatMessage.self], inMemory: true)
}

#Preview("Main App Dark") {
    ContentView()
        .modelContainer(for: [Item.self, Chat.self, ChatMessage.self], inMemory: true)
        .preferredColorScheme(.dark)
}
