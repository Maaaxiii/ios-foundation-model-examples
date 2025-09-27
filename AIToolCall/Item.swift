//
//  Item.swift
//  AIToolCall
//
//  Created by Maximilian Klem on 28.09.25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
