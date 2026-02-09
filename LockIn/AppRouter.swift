//
//  AppRouter.swift
//  LockIn
//
//  Created by leon on 2026/2/10.
//

import SwiftUI

enum RootRoute {
    case wakeFlow
    case todo
}

enum LaunchIntent {
    case none
    case alarm(notificationID: String?)
}

@MainActor
final class AppRouter: ObservableObject {
    @Published var root: RootRoute = .todo
    @Published var pendingIntent: LaunchIntent = .none {
        didSet {
            if case .alarm = pendingIntent {
                root = .wakeFlow
            }
        }
    }

    func completeWakeFlow() {
        pendingIntent = .none
        root = .todo
    }
}
