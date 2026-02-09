//
//  TodoOverviewView.swift
//  LockIn
//
//  Created by leon on 2026/2/10.
//

import SwiftUI
import SwiftData

struct TodoOverviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TodoItem.orderIndex) private var todos: [TodoItem]

    var body: some View {
        List {
            ForEach(todos) { todo in
                HStack(spacing: 12) {
                    TextField(
                        "Todo title",
                        text: Binding(
                            get: { todo.title },
                            set: { todo.title = $0 }
                        )
                    )
                    .textInputAutocapitalization(.sentences)
                    .onSubmit {
                        try? modelContext.save()
                    }

                    if todo.isDone {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
            .onMove(perform: move)
        }
        .navigationTitle("All Todos")
        .toolbar {
            EditButton()
        }
        .task {
            TodoStore.seedIfNeeded(in: modelContext)
        }
    }

    private func move(from offsets: IndexSet, to destination: Int) {
        var reordered = todos
        reordered.move(fromOffsets: offsets, toOffset: destination)
        for (index, item) in reordered.enumerated() {
            item.orderIndex = index
        }
        try? modelContext.save()
    }
}

#Preview {
    TodoOverviewView()
        .modelContainer(for: TodoItem.self, inMemory: true)
}
