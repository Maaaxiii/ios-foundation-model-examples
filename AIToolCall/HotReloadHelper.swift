//
//  HotReloadHelper.swift
//  AIToolCall
//
//  Created by Maximilian Klem on 28.09.25.
//

import SwiftUI
import Foundation
import Combine

#if DEBUG
/// Hot Reload Helper for SwiftUI Development
/// This enables live updates during development
@available(iOS 17.0, *)
class HotReloadHelper: ObservableObject {
    @Published var reloadTrigger = 0
    
    private var fileWatcher: FileWatcher?
    
    init() {
        setupFileWatcher()
    }
    
    private func setupFileWatcher() {
        // Watch for changes in Swift files
        let projectPath = Bundle.main.bundlePath
        let swiftFiles = findSwiftFiles(in: projectPath)
        
        fileWatcher = FileWatcher(paths: swiftFiles) { [weak self] in
            DispatchQueue.main.async {
                self?.reloadTrigger += 1
                print("🔥 Hot Reload: Files changed, triggering reload...")
            }
        }
    }
    
    private func findSwiftFiles(in path: String) -> [String] {
        // In a real implementation, you'd scan for .swift files
        // For now, return the main source directory
        return [path]
    }
    
    deinit {
        fileWatcher?.stopWatching()
    }
}

/// Simple file watcher for development
class FileWatcher {
    private let paths: [String]
    private let onChange: () -> Void
    private var isWatching = false
    
    init(paths: [String], onChange: @escaping () -> Void) {
        self.paths = paths
        self.onChange = onChange
        startWatching()
    }
    
    private func startWatching() {
        isWatching = true
        // In a real implementation, you'd use DispatchSource or FileSystemEvents
        // For now, this is a placeholder for the concept
    }
    
    func stopWatching() {
        isWatching = false
    }
}

/// View modifier for hot reloading
struct HotReloadModifier: ViewModifier {
    @StateObject private var hotReloadHelper = HotReloadHelper()
    
    func body(content: Content) -> some View {
        content
            .id(hotReloadHelper.reloadTrigger)
    }
}

extension View {
    /// Enables hot reloading for this view
    func hotReload() -> some View {
        modifier(HotReloadModifier())
    }
}
#endif