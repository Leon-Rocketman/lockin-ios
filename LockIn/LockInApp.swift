//
//  LockInApp.swift
//  LockIn
//
//  Created by leon on 2026/2/9.
//

import SwiftUI
import SwiftData
import UserNotifications

final class NotificationRouterDelegate: NSObject, UNUserNotificationCenterDelegate {
    private let router: AppRouter

    init(router: AppRouter) {
        self.router = router
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let route = userInfo["route"] as? String

        if route == "wakeflow" {
            DispatchQueue.main.async {
                self.router.pendingIntent = .alarm(notificationID: response.notification.request.identifier)
            }
        }

        completionHandler()
    }
}

@main
struct LockInApp: App {
    @StateObject private var router: AppRouter
    @StateObject private var speech = SystemSpeechService()
    private let notifDelegate: NotificationRouterDelegate

    init() {
        let r = AppRouter()
        _router = StateObject(wrappedValue: r)
        notifDelegate = NotificationRouterDelegate(router: r)

        requestNotificationPermission()
        UNUserNotificationCenter.current().delegate = notifDelegate
    }

    var body: some Scene {
        WindowGroup {
            Group {
                switch router.root {
                case .todo:
                    SingleCardTodoView()
                case .wakeFlow:
                    WakeFlowView()
                }
            }
            .environmentObject(router)
            .environmentObject(speech)
        }
        .modelContainer(for: [TodoItem.self, SleepJournal.self])
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in
            // No-op; system handles the prompt on first launch.
        }
    }
}
