//
//  SleepAudioPlayer.swift
//  LockIn
//
//  Created by leon on 2026/2/10.
//

import AVFoundation

final class SleepAudioPlayer: ObservableObject {
    private var player: AVAudioPlayer?

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
        player?.play()
    }

    func pause() {
        player?.pause()
    }

    func stop() {
        player?.stop()
        player?.currentTime = 0
    }
}
