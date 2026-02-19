//
//  SpeechService.swift
//  LockIn
//
//  Created by leon on 2026/2/10.
//

import AVFoundation
import Foundation

protocol SpeechService {
    func speak(_ text: String)
}

@MainActor
final class SystemSpeechService: ObservableObject, SpeechService {
    private let synthesizer = AVSpeechSynthesizer()
    let prefs: SpeechPreferences

    init(prefs: SpeechPreferences = SpeechPreferences()) {
        self.prefs = prefs
    }

    func speak(_ text: String) {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers]
            )
            try session.setActive(true)
        } catch {
            // Best-effort configuration; proceed with speaking.
        }

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let voiceID = SpeechVoiceSelector.bestChineseVoiceIdentifier(preferred: prefs.preferredVoiceIdentifier)
        let voice = voiceID.flatMap { AVSpeechSynthesisVoice(identifier: $0) }

        for segment in splitForNaturalSpeech(cleaned) {
            let utterance = AVSpeechUtterance(string: segment)
            utterance.voice = voice ?? AVSpeechSynthesisVoice(language: "zh-CN")
            utterance.rate = prefs.rate
            utterance.pitchMultiplier = prefs.pitch
            utterance.volume = prefs.volume
            synthesizer.speak(utterance)
        }
    }

    private func splitForNaturalSpeech(_ text: String) -> [String] {
        let sentenceSeparators = CharacterSet(charactersIn: "。！？!?；;")
        var raw = text
            .components(separatedBy: sentenceSeparators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if raw.isEmpty {
            raw = [text]
        }

        var refined: [String] = []
        for segment in raw {
            if segment.count <= 22 {
                refined.append(segment)
                continue
            }

            let parts = segment
                .components(separatedBy: CharacterSet(charactersIn: "，、,"))
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            if parts.isEmpty {
                refined.append(segment)
                continue
            }

            var buffer = ""
            for part in parts {
                if buffer.isEmpty {
                    buffer = part
                } else if (buffer.count + 1 + part.count) <= 26 {
                    buffer += "，" + part
                } else {
                    refined.append(buffer)
                    buffer = part
                }
            }
            if !buffer.isEmpty {
                refined.append(buffer)
            }
        }

        return refined.map { $0 + "。" }
    }
}
