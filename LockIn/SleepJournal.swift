//
//  SleepJournal.swift
//  LockIn
//
//  Created by leon on 2026/2/10.
//

import Foundation
import SwiftData

@Model
final class SleepJournal {
    var date: Date
    var content: String
    var createdAt: Date

    init(date: Date, content: String, createdAt: Date = Date()) {
        self.date = date
        self.content = content
        self.createdAt = createdAt
    }
}
