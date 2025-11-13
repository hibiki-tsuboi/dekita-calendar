//
//  Item.swift
//  DekitaCalendar
//
//  Created by Hibiki Tsuboi on 2025/11/12.
//

import Foundation
import SwiftData

@Model
final class CalendarEvent {
    var title: String
    var date: Date
    var notes: String
    var isCompleted: Bool
    var createdAt: Date

    init(title: String, date: Date, notes: String = "", isCompleted: Bool = false) {
        self.title = title
        self.date = date
        self.notes = notes
        self.isCompleted = isCompleted
        self.createdAt = Date()
    }
}
