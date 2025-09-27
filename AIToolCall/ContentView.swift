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
    #if DEBUG
    @StateObject private var hotReloadHelper = HotReloadHelper()
    #endif

    var body: some View {
        TabView {
            ChatView()
                .tabItem {
                    Image(systemName: "message")
                    Text("Chat")
                }
            
            HistoryView()
                .tabItem {
                    Image(systemName: "clock.arrow.circlepath")
                    Text("History")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        #if DEBUG
        .id(hotReloadHelper.reloadTrigger)
        #endif
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
