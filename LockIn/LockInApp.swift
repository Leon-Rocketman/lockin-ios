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
    @StateObject private var router: AppRouter
    private let notificationDelegate: NotificationDelegate

    init() {
        let router = AppRouter()
        _router = StateObject(wrappedValue: router)
        let delegate = NotificationDelegate()
        delegate.router = router
        notificationDelegate = delegate

        requestNotificationPermission()
        UNUserNotificationCenter.current().delegate = delegate
    }

    var body: some Scene {
        WindowGroup {
            Group {
                switch router.route {
                case .home:
                    AlarmTestView()
                case .wakeflow:
                    WakeFlowView()
                }
            }
            .environmentObject(router)
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in
            // No-op; system handles the prompt on first launch.
        }
    }
}

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    weak var router: AppRouter?

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let routeValue = response.notification.request.content.userInfo["route"] as? String
        if routeValue == "wakeflow" {
            DispatchQueue.main.async { [weak self] in
                self?.router?.route = .wakeflow
            }
        }
        completionHandler()
    }
}
