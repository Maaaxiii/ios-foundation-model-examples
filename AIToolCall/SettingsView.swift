//
//  SettingsView.swift
//  AIToolCall
//
//  Created by Maximilian Klem on 28.09.25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("userName") private var userName = ""
    @AppStorage("isNotificationsEnabled") private var isNotificationsEnabled = true
    @AppStorage("isDarkModeEnabled") private var isDarkModeEnabled = false
    @AppStorage("selectedLanguage") private var selectedLanguage = "English"
    
    private let languages = ["English", "Spanish", "French", "German", "Italian"]
    
    var body: some View {
        NavigationView {
            List {
                // Profile Section
                Section("Profile") {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            TextField("Your Name", text: $userName)
                                .font(.headline)
                            Text("Tap to edit your name")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Preferences Section
                Section("Preferences") {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.orange)
                        Toggle("Notifications", isOn: $isNotificationsEnabled)
                    }
                    
                    HStack {
                        Image(systemName: "moon.fill")
                            .foregroundColor(.purple)
                        Toggle("Dark Mode", isOn: $isDarkModeEnabled)
                    }
                    
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.green)
                        Picker("Language", selection: $selectedLanguage) {
                            ForEach(languages, id: \.self) { language in
                                Text(language).tag(language)
                            }
                        }
                    }
                }
                
                // App Info Section
                Section("App Information") {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text("AIToolCall")
                                .font(.headline)
                            Text("Version 1.0.0")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    
                    HStack {
                        Image(systemName: "gear")
                            .foregroundColor(.gray)
                        Text("Advanced Settings")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
                
                // Actions Section
                Section("Actions") {
                    Button(action: clearHistory) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                            Text("Clear History")
                                .foregroundColor(.red)
                        }
                    }
                    
                    Button(action: exportData) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.blue)
                            Text("Export Data")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func clearHistory() {
        // Implementation for clearing history
        print("Clear history tapped")
    }
    
    private func exportData() {
        // Implementation for exporting data
        print("Export data tapped")
    }
}

#Preview("Settings View") {
    SettingsView()
}

#Preview("Settings View Dark") {
    SettingsView()
        .preferredColorScheme(.dark)
}