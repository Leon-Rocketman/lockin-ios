import AVFoundation
import Combine

@MainActor
final class AlarmAudioPlayer {

    static let shared = AlarmAudioPlayer()

    private var player: AVAudioPlayer?
    private var cancellable: AnyCancellable?

    private init() {}

    func bind(to session: AlarmSessionStore) {
        cancellable = session.$state.sink { [weak self] state in
            self?.handle(state)
        }
    }

    private func handle(_ state: AlarmSessionStore.State) {
        switch state {

        case .ringing:
            start()

        case .completed, .idle:
            stop()

        default:
            break
        }
    }

    private func start() {
        guard player == nil else { return }

        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                options: [.duckOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)

            guard let url = Bundle.main.url(
                forResource: "alarm",
                withExtension: "mp3"
            ) else {
                print("Alarm sound file missing")
                return
            }

            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1
            player?.prepareToPlay()
            player?.play()

            print("🔔 Alarm started")

        } catch {
            print("Alarm audio error:", error)
        }
    }

    private func stop() {
        guard let player else { return }

        player.stop()
        self.player = nil

        try? AVAudioSession.sharedInstance().setActive(false)

        print("🔕 Alarm stopped")
    }
}
