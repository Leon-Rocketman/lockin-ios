import Foundation
import AVFoundation

struct SpeechVoiceSelector {

    static func bestChineseVoiceIdentifier(preferred: String?) -> String? {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        let zh = voices.filter { $0.language == "zh-CN" }

        // 1) If user manually selected an identifier and it still exists, use it
        if let preferred, zh.contains(where: { $0.identifier == preferred }) {
            return preferred
        }

        // 2) Try Siri voices (if exposed by system)
        if let siri = zh.first(where: { $0.identifier.localizedCaseInsensitiveContains("siri") }) {
            return siri.identifier
        }

        // 3) Fallback: score voices and pick best
        // Heuristics: prefer voices whose identifier/name implies higher quality.
        // NOTE: Apple doesn't provide a formal "quality" field; this is best-effort.
        let scored = zh.map { v -> (AVSpeechSynthesisVoice, Int) in
            let id = v.identifier.lowercased()
            let name = v.name.lowercased()

            var score = 0

            // prefer "premium/enhanced" signals (varies by iOS version / vendors)
            if id.contains("premium") || name.contains("premium") { score += 30 }
            if id.contains("enhanced") || name.contains("enhanced") { score += 25 }

            // prefer compact/modern system voices (heuristic)
            if id.contains("com.apple") { score += 10 }

            // penalize old/novelty voices
            if name.contains("novelty") { score -= 10 }

            // slight preference for voices with longer identifier (often newer internal variants)
            score += min(10, id.count / 10)

            return (v, score)
        }
        .sorted { $0.1 > $1.1 }

        return scored.first?.0.identifier
    }

    static func dumpChineseVoices() -> String {
        let zh = AVSpeechSynthesisVoice.speechVoices().filter { $0.language == "zh-CN" }
        if zh.isEmpty { return "No zh-CN voices available on this device." }

        return zh.map { v in
            "name=\(v.name) | id=\(v.identifier)"
        }.joined(separator: "\n")
    }
}
