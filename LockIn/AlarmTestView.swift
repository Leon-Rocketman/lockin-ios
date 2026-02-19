//
//  AlarmTestView.swift
//  LockIn
//
//  Created by leon on 2026/2/9.
//

import SwiftUI
import SwiftData
import UserNotifications

struct AlarmTestView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack {
            Button("Schedule Test Alarm") {
                scheduleTestAlarm()
            }

            Button("Print Morning Briefing") {
                Task {
                    await debugPrintBriefing()
                }
            }
        }
        .padding()
    }

    private func scheduleTestAlarm() {
        let content = UNMutableNotificationContent()
        content.title = "Test Alarm"
        content.body = "This is a test alarm notification."
        content.sound = UNNotificationSound(named: UNNotificationSoundName("alarm.caf"))
        content.userInfo = ["route": "wakeflow"]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { _ in
            // No-op for test view.
        }
    }

    private func debugPrintBriefing() async {
        let todos = TodoBriefingRepository.fetchUnfinishedTodoTitles(in: modelContext, limit: 7)
        let weather = await PlaceholderWeatherProvider(fixedText: "晴天")
            .fetchWeatherSummary(for: Date())

        let text = MorningBriefingBuilder.build(
            MorningBriefingInput(
                now: Date(),
                weatherText: weather,
                unfinishedTodos: todos,
                userName: "里昂"
            )
        )
        print("MorningBriefing:", text)
    }
}

#Preview {
    AlarmTestView()
}
