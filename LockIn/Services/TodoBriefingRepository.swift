import Foundation
import SwiftData

@MainActor
struct TodoBriefingRepository {

    static func fetchUnfinishedTodoTitles(
        in context: ModelContext,
        limit: Int = 7
    ) -> [String] {
        var descriptor = FetchDescriptor<TodoItem>(
            predicate: #Predicate { $0.isDone == false },
            sortBy: [SortDescriptor(\TodoItem.orderIndex, order: .forward)]
        )
        descriptor.fetchLimit = max(0, limit)

        do {
            let items = try context.fetch(descriptor)
            return items.map { $0.title.trimmingCharacters(in: .whitespacesAndNewlines) }
        } catch {
            print("TodoBriefingRepository fetch error:", error)
            return []
        }
    }
}
