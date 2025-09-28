//
//  MemoryTool.swift
//  AIToolCall
//
//  Created by Maximilian Klem on 28.09.25.
//

import Foundation
import FoundationModels

struct MemoryTool: Tool {
    let name = "memory"
    
    let description = """
        Store, retrieve, or search through user memories and notes.
        Can save important information for future reference.
        """
    
    @Generable
    struct Arguments {
        let action: MemoryAction
        let key: String?
        let value: String?
        let searchTerm: String?
    }
    
    @Generable
    enum MemoryAction: String, CaseIterable {
        case store = "store"
        case retrieve = "retrieve"
        case search = "search"
        case list = "list"
        case delete = "delete"
    }
    
    func call(arguments: Arguments) async -> String {
        switch arguments.action {
        case .store:
            return await storeMemory(key: arguments.key ?? "", value: arguments.value ?? "")
        case .retrieve:
            return await retrieveMemory(key: arguments.key ?? "")
        case .search:
            return await searchMemories(term: arguments.searchTerm ?? "")
        case .list:
            return await listMemories()
        case .delete:
            return await deleteMemory(key: arguments.key ?? "")
        }
    }
    
    private func storeMemory(key: String, value: String) async -> String {
        guard !key.isEmpty && !value.isEmpty else {
            return "Error: Both key and value are required to store a memory."
        }
        
        // In a real app, you'd store this in a database or UserDefaults
        UserDefaults.standard.set(value, forKey: "memory_\(key)")
        
        return """
        Memory stored successfully!
        Key: \(key)
        Value: \(value)
        Timestamp: \(Date().formatted(date: .complete, time: .complete))
        """
    }
    
    private func retrieveMemory(key: String) async -> String {
        guard !key.isEmpty else {
            return "Error: Key is required to retrieve a memory."
        }
        
        if let value = UserDefaults.standard.string(forKey: "memory_\(key)") {
            return """
            Retrieved memory:
            Key: \(key)
            Value: \(value)
            """
        } else {
            return "No memory found with key: \(key)"
        }
    }
    
    private func searchMemories(term: String) async -> String {
        guard !term.isEmpty else {
            return "Error: Search term is required."
        }
        
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        let memoryKeys = allKeys.filter { $0.hasPrefix("memory_") }
        
        var foundMemories: [(String, String)] = []
        
        for key in memoryKeys {
            if let value = UserDefaults.standard.string(forKey: key) {
                if value.localizedCaseInsensitiveContains(term) || key.localizedCaseInsensitiveContains(term) {
                    let cleanKey = String(key.dropFirst(7)) // Remove "memory_" prefix
                    foundMemories.append((cleanKey, value))
                }
            }
        }
        
        if foundMemories.isEmpty {
            return "No memories found containing: \(term)"
        } else {
            var result = "Found \(foundMemories.count) memories containing '\(term)':\n\n"
            for (key, value) in foundMemories {
                result += "• \(key): \(value)\n"
            }
            return result
        }
    }
    
    private func listMemories() async -> String {
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        let memoryKeys = allKeys.filter { $0.hasPrefix("memory_") }
        
        if memoryKeys.isEmpty {
            return "No memories stored."
        }
        
        var result = "All stored memories (\(memoryKeys.count)):\n\n"
        
        for key in memoryKeys.sorted() {
            if let value = UserDefaults.standard.string(forKey: key) {
                let cleanKey = String(key.dropFirst(7)) // Remove "memory_" prefix
                result += "• \(cleanKey): \(value)\n"
            }
        }
        
        return result
    }
    
    private func deleteMemory(key: String) async -> String {
        guard !key.isEmpty else {
            return "Error: Key is required to delete a memory."
        }
        
        if UserDefaults.standard.string(forKey: "memory_\(key)") != nil {
            UserDefaults.standard.removeObject(forKey: "memory_\(key)")
            return "Memory deleted successfully: \(key)"
        } else {
            return "No memory found with key: \(key)"
        }
    }
}