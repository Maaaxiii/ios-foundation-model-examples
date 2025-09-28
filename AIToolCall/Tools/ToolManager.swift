//
//  ToolManager.swift
//  AIToolCall
//
//  Created by Maximilian Klem on 28.09.25.
//

import Foundation
import Combine
import FoundationModels

@MainActor
class ToolManager: ObservableObject {
    @Published var enabledTools: Set<String> = ["getWeather", "getTime", "memory"]
    
    private let allTools: [any Tool] = [
        WeatherTool(),
        TimeTool(),
        MemoryTool()
    ]
    
    var availableTools: [any Tool] {
        allTools.filter { enabledTools.contains($0.name) }
    }
    
    func isToolEnabled(_ toolName: String) -> Bool {
        enabledTools.contains(toolName)
    }
    
    func toggleTool(_ toolName: String) {
        if enabledTools.contains(toolName) {
            enabledTools.remove(toolName)
        } else {
            enabledTools.insert(toolName)
        }
    }
    
    func getToolDescription(_ toolName: String) -> String {
        switch toolName {
        case "getWeather":
            return "Get current weather information for any city"
        case "getTime":
            return "Get current time, date, and timezone information"
        case "memory":
            return "Store, retrieve, and search through personal memories"
        default:
            return "Unknown tool"
        }
    }
    
    func getToolIcon(_ toolName: String) -> String {
        switch toolName {
        case "getWeather":
            return "cloud.sun.fill"
        case "getTime":
            return "clock.fill"
        case "memory":
            return "brain.head.profile"
        default:
            return "wrench.fill"
        }
    }
}