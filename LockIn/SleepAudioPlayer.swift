//
//  SleepAudioPlayer.swift
//  LockIn
//
//  Created by leon on 2026/2/10.
//

import AVFoundation

final class SleepAudioPlayer: ObservableObject {
    private var player: AVAudioPlayer?
    private let audioSession = AVAudioSession.sharedInstance()

    init() {
        loadAudio()
    }

    private func loadAudio() {
        guard let url = Bundle.main.url(forResource: "sleep_music", withExtension: "mp3") else {
            return
        }
        player = try? AVAudioPlayer(contentsOf: url)
        player?.prepareToPlay()
    }

    func play() {
        configureSessionForPlayback()
        player?.play()
    }

    func pause() {
        player?.pause()
    }

    func stop() {
        player?.stop()
        player?.currentTime = 0
        try? audioSession.setActive(false, options: [.notifyOthersOnDeactivation])
    }

    private func configureSessionForPlayback() {
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
        } catch {
            print("Sleep audio session error:", error)
        }
    }
}
