import Foundation

final class SpeechPreferences: ObservableObject {
    @Published var preferredVoiceIdentifier: String? {
        didSet { UserDefaults.standard.set(preferredVoiceIdentifier, forKey: Keys.voiceId) }
    }

    @Published var rate: Float {
        didSet { UserDefaults.standard.set(rate, forKey: Keys.rate) }
    }

    @Published var pitch: Float {
        didSet { UserDefaults.standard.set(pitch, forKey: Keys.pitch) }
    }

    @Published var volume: Float {
        didSet { UserDefaults.standard.set(volume, forKey: Keys.volume) }
    }

    init() {
        self.preferredVoiceIdentifier = UserDefaults.standard.string(forKey: Keys.voiceId)

        let savedRate = UserDefaults.standard.object(forKey: Keys.rate) as? Float
        let savedPitch = UserDefaults.standard.object(forKey: Keys.pitch) as? Float
        let savedVolume = UserDefaults.standard.object(forKey: Keys.volume) as? Float

        // Default "Siri-ish" comfort tuning (can be adjusted)
        self.rate = savedRate ?? 0.48
        self.pitch = savedPitch ?? 1.0
        self.volume = savedVolume ?? 0.90
    }

    private enum Keys {
        static let voiceId = "speech.preferredVoiceIdentifier"
        static let rate = "speech.rate"
        static let pitch = "speech.pitch"
        static let volume = "speech.volume"
    }
}
