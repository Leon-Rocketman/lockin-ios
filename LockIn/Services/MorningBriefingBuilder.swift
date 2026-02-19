import Foundation

struct MorningBriefingInput {
    let now: Date
    let weatherText: String?      // e.g. "晴天" / "多云" / nil
    let unfinishedTodos: [String] // already trimmed titles
    let userName: String          // e.g. "里昂"
}

struct MorningBriefingBuilder {

    /// Build a short, natural Mandarin briefing line for TTS.
    /// Output example:
    /// "里昂你好，今天是2月19号，晴天，今天的任务为：复盘计划，开始第一个25分钟锁定，喝水拉伸。"
    static func build(_ input: MorningBriefingInput) -> String {
        let dateText = formatChineseDate(input.now)

        let weather = (input.weatherText?.trimmingCharacters(in: .whitespacesAndNewlines))
        let weatherText = (weather?.isEmpty == false) ? weather! : "天气未知"

        let todos = input.unfinishedTodos
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let todoText: String
        if todos.isEmpty {
            todoText = "今天的任务已清空，保持节奏。"
        } else {
            // Use Chinese enumeration style: A，B，C
            let joined = todos.joined(separator: "，")
            todoText = "今天的任务为：\(joined)。"
        }

        return "\(input.userName)你好，今天是\(dateText)，\(weatherText)，\(todoText)"
    }

    private static func formatChineseDate(_ date: Date) -> String {
        // "2月19号"
        let cal = Calendar(identifier: .gregorian)
        let comps = cal.dateComponents([.month, .day], from: date)
        let m = comps.month ?? 0
        let d = comps.day ?? 0
        return "\(m)月\(d)号"
    }
}
