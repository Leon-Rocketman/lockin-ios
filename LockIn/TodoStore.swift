//
//  TodoStore.swift
//  LockIn
//
//  Created by leon on 2026/2/10.
//

import SwiftData
import Foundation



enum TodoStore {
    static func seedIfNeeded(in context: ModelContext) {
        let descriptor = FetchDescriptor<TodoItem>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        insertSampleTodos(in: context)
        try? context.save()
    }

    static func resetSampleTodos(in context: ModelContext) {
        let descriptor = FetchDescriptor<TodoItem>()
        let existing = (try? context.fetch(descriptor)) ?? []
        for item in existing {
            context.delete(item)
        }

        insertSampleTodos(in: context)
        try? context.save()
    }

    private static func insertSampleTodos(in context: ModelContext) {
        let titles = [
            "Todo #1: Review today's plan",
            "Todo #2: Start first 25-min lock-in",
            "Todo #3: Drink water and stretch"
        ]

        for (index, title) in titles.enumerated() {
            let item = TodoItem(title: title, orderIndex: index)
            context.insert(item)
        }
    }
}
