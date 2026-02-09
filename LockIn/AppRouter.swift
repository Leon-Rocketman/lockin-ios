//
//  AppRouter.swift
//  LockIn
//
//  Created by leon on 2026/2/10.
//

import SwiftUI

enum AppRoute {
    case home
    case wakeflow
}

final class AppRouter: ObservableObject {
    @Published var route: AppRoute = .home
}
