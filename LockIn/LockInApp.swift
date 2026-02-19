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
    private let alarmSession: AlarmSessionStore

    init(router: AppRouter, alarmSession: AlarmSessionStore) {
        self.router = router
        self.alarmSession = alarmSession
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
                self.alarmSession.notificationTriggered()
                self.router.pendingIntent = .alarm(notificationID: response.notification.request.identifier)
            }
        }

        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        let route = userInfo["route"] as? String

        if route == "wakeflow" {
            DispatchQueue.main.async {
                self.alarmSession.notificationTriggered()
                self.router.pendingIntent = .alarm(notificationID: notification.request.identifier)
            }
        }

        completionHandler([.banner, .sound])
    }
}

@MainActor
private func adoptDeliveredWakeflowIfNeeded(router: AppRouter, alarmSession: AlarmSessionStore) {
    UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
        let hasWakeflow = notifications.contains { notification in
            (notification.request.content.userInfo["route"] as? String) == "wakeflow"
        }

        guard hasWakeflow else { return }

        DispatchQueue.main.async {
            alarmSession.notificationTriggered()
            router.pendingIntent = .alarm(notificationID: nil)
        }
    }
}

@main
struct LockInApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var router: AppRouter
    @StateObject private var alarmSession: AlarmSessionStore
    @StateObject private var speech = SystemSpeechService()
    private let notifDelegate: NotificationRouterDelegate

    init() {
        let r = AppRouter()
        let a = AlarmSessionStore()
        _router = StateObject(wrappedValue: r)
        _alarmSession = StateObject(wrappedValue: a)
        notifDelegate = NotificationRouterDelegate(router: r, alarmSession: a)
        AlarmAudioPlayer.shared.bind(to: a)

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
            .environmentObject(alarmSession)
            .environmentObject(speech)
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active else { return }
                adoptDeliveredWakeflowIfNeeded(router: router, alarmSession: alarmSession)
            }
        }
        .modelContainer(for: [TodoItem.self, SleepJournal.self])
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in
            // No-op; system handles the prompt on first launch.
        }
    }
}
