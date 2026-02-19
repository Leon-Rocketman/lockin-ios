import Foundation
import Combine

@MainActor
final class AlarmSessionStore: ObservableObject {

    enum State {
        case idle
        case ringing
        case wakeFlowActive
        case completed
    }

    @Published private(set) var state: State = .idle

    func notificationTriggered() {
        state = .ringing
        debugPrint("AlarmSession → ringing")
    }

    func enteredWakeFlow() {
        state = .wakeFlowActive
        debugPrint("AlarmSession → wakeFlowActive")
    }

    func completedWakeFlow() {
        state = .completed
        debugPrint("AlarmSession → completed")
    }

    func reset() {
        state = .idle
        debugPrint("AlarmSession → idle")
    }
}
