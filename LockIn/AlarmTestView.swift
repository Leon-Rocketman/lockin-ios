//
//  AlarmTestView.swift
//  LockIn
//
//  Created by leon on 2026/2/9.
//

import SwiftUI
import UserNotifications

struct AlarmTestView: View {
    var body: some View {
        VStack {
            Button("Schedule Test Alarm") {
                scheduleTestAlarm()
            }
        }
        .padding()
    }

    private func scheduleTestAlarm() {
        let content = UNMutableNotificationContent()
        content.title = "Test Alarm"
        content.body = "This is a test alarm notification."
        content.sound = .default

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
}

#Preview {
    AlarmTestView()
}
