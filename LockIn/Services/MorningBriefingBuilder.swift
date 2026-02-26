import Foundation

struct MorningBriefingInput {
    let now: Date
    let weatherText: String?      // e.g. "晴天" / "多云" / nil
    let unfinishedTodos: [String] // already trimmed titles
    let userName: String          // e.g. "里昂"
    let maxTodoSpoken: Int
    let includeClosing: Bool

    init(
        now: Date,
        weatherText: String?,
        unfinishedTodos: [String],
        userName: String,
        maxTodoSpoken: Int = 5,
        includeClosing: Bool = true
    ) {
        self.now = now
        self.weatherText = weatherText
        self.unfinishedTodos = unfinishedTodos
        self.userName = userName
        self.maxTodoSpoken = maxTodoSpoken
        self.includeClosing = includeClosing
    }
}

struct MorningBriefingBuilder {

    static func build(_ input: MorningBriefingInput) -> String {
        let dateText = formatChineseDate(input.now)

        let weather = (input.weatherText?.trimmingCharacters(in: .whitespacesAndNewlines))
        let weatherText = (weather?.isEmpty == false) ? weather! : "天气未知"

        let cleanedTodos = input.unfinishedTodos
            .map { normalizeForSpeech($0) }
            .filter { !$0.isEmpty }

        let s1 = "\(input.userName)，早上好。"
        let s2 = "今天是\(dateText)，\(weatherText)。"

        let s3: String
        if cleanedTodos.isEmpty {
            s3 = input.includeClosing
                ? "今天任务已清空。保持节奏就好。"
                : "今天任务已清空。"
        } else {
            let maxN = max(1, input.maxTodoSpoken)
            let spoken = Array(cleanedTodos.prefix(maxN))
            var taskLine = "你今天的重点是：\(spoken.joined(separator: "，"))。"

            let remaining = cleanedTodos.count - spoken.count
            if remaining > 0 {
                taskLine += "另外还有\(remaining)项未完成。"
            }
            if input.includeClosing {
                taskLine += "我们开始吧。"
            }
            s3 = taskLine
        }

        return "\(s1)\(s2)\(s3)"
    }

    private static func normalizeForSpeech(_ raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.isEmpty { return "" }

        s = s.replacingOccurrences(of: ":", with: "：")
        s = s.replacingOccurrences(of: "-", with: "—")

        let replacements: [(String, String)] = [
            ("Agentic Coding", "智能体编程"),
            ("agentic coding", "智能体编程"),
            ("Codex Hackathon", "Codex 黑客松"),
            ("hackathon", "黑客松"),
            ("Codex", "Codex"),
            ("TTS", "语音播报"),
            ("UI", "界面"),
            ("APP", "应用"),
            ("App", "应用"),
            ("GPT", "GPT")
        ]

        for (from, to) in replacements {
            s = s.replacingOccurrences(of: from, with: to)
        }

        if s.count > 30 {
            let idx = s.index(s.startIndex, offsetBy: 30)
            s = String(s[..<idx]) + "…"
        }

        return s
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
