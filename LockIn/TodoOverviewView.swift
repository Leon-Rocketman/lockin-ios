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
    private let showsNavigationActions: Bool
    @State private var draftTitles: [UUID: String] = [:]
    @State private var editMode: EditMode = .inactive
    @Binding private var commitToken: Int

    init(showsNavigationActions: Bool = true, commitToken: Binding<Int> = .constant(0)) {
        self.showsNavigationActions = showsNavigationActions
        _commitToken = commitToken
    }

    var body: some View {
        VStack(spacing: 0) {
            if !showsNavigationActions {
                HStack {
                    Button(editMode == .active ? "Done" : "Reorder") {
                        editMode = editMode == .active ? .inactive : .active
                    }

                    Spacer()

                    Button {
                        addTodo()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }

            List {
                Section("To do") {
                    ForEach(todoItems) { todo in
                        HStack(spacing: 12) {
                            Button {
                                markDone(todo)
                            } label: {
                                Image(systemName: "circle")
                            }
                            .buttonStyle(.plain)

                            TextField(
                                "Todo title",
                                text: Binding(
                                    get: { draftTitles[todo.id] ?? todo.title },
                                    set: { draftTitles[todo.id] = $0 }
                                )
                            )
                            .textInputAutocapitalization(.sentences)
                            .onSubmit {
                                commitDraftIfNeeded(for: todo)
                            }
                        }
                        .onDisappear {
                            commitDraftIfNeeded(for: todo)
                        }
                    }
                    .onMove(perform: move)
                }

                Section("Done") {
                    ForEach(doneItems) { todo in
                        HStack(spacing: 12) {
                            Button {
                                restore(todo)
                            } label: {
                                Image(systemName: "arrow.uturn.left.circle")
                            }
                            .buttonStyle(.plain)

                            TextField(
                                "Todo title",
                                text: Binding(
                                    get: { draftTitles[todo.id] ?? todo.title },
                                    set: { draftTitles[todo.id] = $0 }
                                )
                            )
                            .textInputAutocapitalization(.sentences)
                            .onSubmit {
                                commitDraftIfNeeded(for: todo)
                            }
                            .foregroundColor(.secondary)
                        }
                        .onDisappear {
                            commitDraftIfNeeded(for: todo)
                        }
                    }
                }
            }
        }
        .navigationTitle("All Todos")
        .toolbar {
            if showsNavigationActions {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink("Sleep Mode") {
                        SleepModeView()
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    addTodo()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .environment(\.editMode, $editMode)
        .task {
            TodoStore.seedIfNeeded(in: modelContext)
        }
        .onAppear {
            syncDrafts()
        }
        .onChange(of: todos) { _ in
            syncDrafts()
        }
        .onChange(of: commitToken) { _ in
            commitAllDrafts()
        }
        .onDisappear {
            commitAllDrafts()
        }
    }

    private func move(from offsets: IndexSet, to destination: Int) {
        var reordered = todoItems
        reordered.move(fromOffsets: offsets, toOffset: destination)
        for (index, item) in reordered.enumerated() {
            item.orderIndex = index
        }
        try? modelContext.save()
    }

    private var todoItems: [TodoItem] {
        todos.filter { !$0.isDone }
    }

    private var doneItems: [TodoItem] {
        todos.filter { $0.isDone }
    }

    private func addTodo() {
        let maxIndex = todos.map(\.orderIndex).max() ?? -1
        let item = TodoItem(title: "New todo", orderIndex: maxIndex + 1, isDone: false)
        modelContext.insert(item)
        try? modelContext.save()
    }

    private func markDone(_ todo: TodoItem) {
        commitDraftIfNeeded(for: todo)
        todo.isDone = true
        try? modelContext.save()
    }

    private func restore(_ todo: TodoItem) {
        commitDraftIfNeeded(for: todo)
        let maxIndex = todoItems.map(\.orderIndex).max() ?? -1
        todo.isDone = false
        todo.orderIndex = maxIndex + 1
        try? modelContext.save()
    }

    private func syncDrafts() {
        var next: [UUID: String] = [:]
        for todo in todos {
            next[todo.id] = draftTitles[todo.id] ?? todo.title
        }
        draftTitles = next
    }

    private func commitDraftIfNeeded(for todo: TodoItem) {
        let draft = draftTitles[todo.id] ?? todo.title
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed != todo.title else { return }
        todo.title = trimmed
        try? modelContext.save()
        draftTitles[todo.id] = trimmed
    }

    private func commitAllDrafts() {
        var didChange = false
        for todo in todos {
            let draft = draftTitles[todo.id] ?? todo.title
            let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed != todo.title else { continue }
            todo.title = trimmed
            draftTitles[todo.id] = trimmed
            didChange = true
        }

        if didChange {
            try? modelContext.save()
        }
    }
}

#Preview {
    TodoOverviewView()
        .modelContainer(for: TodoItem.self, inMemory: true)
}
