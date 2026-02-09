//
//  TodoItem.swift
//  LockIn
//
//  Created by leon on 2026/2/10.
//

import Foundation
import SwiftData

@Model
final class TodoItem {
    var id: UUID
    var title: String
    var orderIndex: Int
    var isDone: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        orderIndex: Int,
        isDone: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.orderIndex = orderIndex
        self.isDone = isDone
        self.createdAt = createdAt
    }
}
