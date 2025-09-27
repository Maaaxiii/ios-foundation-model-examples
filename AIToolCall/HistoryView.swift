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
    @Query private var items: [Item]
    @State private var searchText = ""
    
    var filteredItems: [Item] {
        if searchText.isEmpty {
            return items.sorted { $0.timestamp > $1.timestamp }
        } else {
            return items.filter { item in
                item.timestamp.formatted().localizedCaseInsensitiveContains(searchText)
            }.sorted { $0.timestamp > $1.timestamp }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if filteredItems.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No History Yet")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("Your conversation history will appear here")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredItems) { item in
                            HistoryRow(item: item)
                        }
                        .onDelete(perform: deleteItems)
                    }
                    .searchable(text: $searchText, prompt: "Search history...")
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredItems[index])
            }
        }
    }
}

struct HistoryRow: View {
    let item: Item
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Conversation")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(item.timestamp, format: Date.FormatStyle(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Image(systemName: "message.circle")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("View")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview("History View Empty") {
    HistoryView()
        .modelContainer(for: Item.self, inMemory: true)
}

#Preview("History View with Data") {
    HistoryView()
        .modelContainer(for: Item.self, inMemory: true)
        .onAppear {
            // Add sample data for preview
            let context = ModelContext(try! ModelContainer(for: Item.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)))
            for i in 1...10 {
                let item = Item(timestamp: Date().addingTimeInterval(TimeInterval(-i * 3600)))
                context.insert(item)
            }
        }
}