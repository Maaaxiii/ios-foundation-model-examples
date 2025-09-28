//
//  WeatherTool.swift
//  AIToolCall
//
//  Created by Maximilian Klem on 28.09.25.
//

import Foundation
import FoundationModels

struct WeatherTool: Tool {
    let name = "getWeather"
    
    let description = """
        Get current weather information for a specific city.
        Returns temperature, conditions, and humidity.
        """
    
    @Generable
    struct Arguments {
        let city: String
    }
    
    func call(arguments: Arguments) async -> String {
        // Simulate weather data (in a real app, you'd call a weather API)
        let weatherData = [
            "New York": "Sunny, 22°C, Humidity: 65%",
            "London": "Cloudy, 15°C, Humidity: 80%",
            "Tokyo": "Rainy, 18°C, Humidity: 90%",
            "Paris": "Partly Cloudy, 20°C, Humidity: 70%",
            "Sydney": "Clear, 25°C, Humidity: 55%",
            "Berlin": "Overcast, 16°C, Humidity: 75%",
            "Moscow": "Snow, -5°C, Humidity: 85%",
            "Dubai": "Hot, 35°C, Humidity: 40%"
        ]
        
        let cityWeather = weatherData[arguments.city] ?? "Weather data not available for \(arguments.city)"
        
        return """
        Current weather in \(arguments.city):
        \(cityWeather)
        Last updated: \(Date().formatted(date: .omitted, time: .shortened))
        """
    }
}