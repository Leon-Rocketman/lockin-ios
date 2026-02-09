//
//  LockInApp.swift
//  LockIn
//
//  Created by leon on 2026/2/9.
//

import SwiftUI
import UserNotifications

@main
struct LockInApp: App {
    private let notificationDelegate = NotificationDelegate.shared

    init() {
        requestNotificationPermission()
        UNUserNotificationCenter.current().delegate = notificationDelegate
    }

    var body: some Scene {
        WindowGroup {
            AlarmTestView()
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in
            // No-op; system handles the prompt on first launch.
        }
    }
}

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .sound]
    }
}
