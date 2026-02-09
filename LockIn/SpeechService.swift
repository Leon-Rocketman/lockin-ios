//
//  SpeechService.swift
//  LockIn
//
//  Created by leon on 2026/2/10.
//

import AVFoundation

protocol SpeechService {
    func speak(_ text: String)
}

final class SystemSpeechService: SpeechService {
    private let synthesizer = AVSpeechSynthesizer()

    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())
        synthesizer.speak(utterance)
    }
}
