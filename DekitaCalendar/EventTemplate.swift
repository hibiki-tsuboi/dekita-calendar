//
//  EventTemplate.swift
//  DekitaCalendar
//
//  Created by Hibiki Tsuboi on 2025/11/20.
//

import Foundation
import SwiftData

@Model
final class EventTemplate {
    var title: String
    var emoji: String
    var createdAt: Date
    var lastUsedAt: Date?
    var usageCount: Int

    init(title: String, emoji: String = "📝") {
        self.title = title
        self.emoji = emoji
        self.createdAt = Date()
        self.lastUsedAt = nil
        self.usageCount = 0
    }
}
