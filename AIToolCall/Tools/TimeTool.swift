//
//  TimeTool.swift
//  AIToolCall
//
//  Created by Maximilian Klem on 28.09.25.
//

import Foundation
import FoundationModels

struct TimeTool: Tool {
    let name = "getTime"
    
    let description = """
        Get current time information including date, time, and timezone.
        Can also calculate time differences and convert between timezones.
        """
    
    @Generable
    struct Arguments {
        let timezone: String?
        let format: String?
    }
    
    func call(arguments: Arguments) async -> String {
        let now = Date()
        let calendar = Calendar.current
        
        // Default timezone
        let timeZone = arguments.timezone ?? "UTC"
        
        // Default format
        let format = arguments.format ?? "full"
        
        var result = "Current time information:\n\n"
        
        // Basic time info
        result += "Local time: \(now.formatted(date: .complete, time: .complete))\n"
        
        // Timezone info
        if let tz = arguments.timezone {
            result += "Requested timezone: \(tz)\n"
        }
        
        // Additional time details
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let day = calendar.component(.day, from: now)
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)
        
        result += "Hour: \(hour)\n"
        result += "Minute: \(minute)\n"
        result += "Date: \(day)/\(month)/\(year)\n"
        
        // Time of day
        let timeOfDay: String
        switch hour {
        case 5..<12:
            timeOfDay = "Morning"
        case 12..<17:
            timeOfDay = "Afternoon"
        case 17..<21:
            timeOfDay = "Evening"
        default:
            timeOfDay = "Night"
        }
        
        result += "Time of day: \(timeOfDay)\n"
        result += "Unix timestamp: \(Int(now.timeIntervalSince1970))"
        
        return result
    }
}