//
//  SingleCardTodoView.swift
//  LockIn
//
//  Created by leon on 2026/2/10.
//

import SwiftUI
import SwiftData
import UserNotifications

struct SingleCardTodoView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TodoItem.orderIndex) private var todos: [TodoItem]
    @State private var showOverview = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                if let current = currentTodo {
                    currentTodoCard(current)

                    Button("Complete ✅") {
                        complete(todo: current)
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Overview") {
                        showOverview = true
                    }
                    .buttonStyle(.bordered)
                } else {
                    Text("All done today 🎉")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Button("Reset sample todos") {
                        TodoStore.resetSampleTodos(in: modelContext)
                    }
                    .buttonStyle(.borderedProminent)
                }

                Button("Debug: WakeFlow Notification (3s)") {
                    scheduleDebugWakeFlowNotification()
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .navigationDestination(isPresented: $showOverview) {
                TodoOverviewView()
            }
            .task {
                TodoStore.seedIfNeeded(in: modelContext)
            }
        }
    }

    private var currentTodo: TodoItem? {
        todos.first { !$0.isDone }
    }

    private func currentTodoCard(_ todo: TodoItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Focus")
                .font(.headline)
                .foregroundColor(.secondary)

            Text(todo.title)
                .font(.title2)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }

    private func complete(todo: TodoItem) {
        todo.isDone = true
        try? modelContext.save()
    }

    private func scheduleDebugWakeFlowNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Debug WakeFlow"
        content.body = "Tap to open WakeFlow."
        content.sound = .default
        content.userInfo = ["route": "wakeflow"]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
        let request = UNNotificationRequest(
            identifier: "debug-wakeflow-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { _ in
            // No-op for debug trigger.
        }
    }
}

#Preview {
    SingleCardTodoView()
        .modelContainer(for: TodoItem.self, inMemory: true)
}
