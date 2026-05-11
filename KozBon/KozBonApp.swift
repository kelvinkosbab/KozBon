//
//  KozBonApp.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import AppCore

// MARK: - KozBonApp

/// The Xcode app target's `@main` entry point — a thin shim that
/// delegates the entire scene tree, dependency wiring, and macOS
/// commands configuration to the `AppCore` Swift package.
///
/// Every piece of business logic lives in `AppCore`. The
/// executable target only carries what Xcode *requires* to live
/// there: this `@main` shim, `Info.plist`, `Assets.xcassets`, the
/// entitlements file, and the IANA service-name CSV. That keeps
/// the package layout testable in isolation under `swift test`,
/// keeps new contributors out of project-settings churn for
/// behavior changes, and makes the executable's surface a
/// straightforward composition over the package's public API.
@main
struct KozBonApp: App {
    var body: some Scene {
        AppCoreScene()
    }
}
