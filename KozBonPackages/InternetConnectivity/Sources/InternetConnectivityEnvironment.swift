//
//  InternetConnectivityEnvironment.swift
//  InternetConnectivity
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - Default Instance

extension MockInternetConnectivityMonitor {

    /// Backs `EnvironmentValues.internetConnectivity` when the app
    /// hasn't injected its live monitor: always connected, so previews
    /// and tests render the normal online UI.
    ///
    /// Allocated once rather than at the `@Entry` site, which is
    /// re-evaluated on every read. `assumeIsolated` covers the
    /// main-actor `init` from the macro's nonisolated default site;
    /// SwiftUI resolves environment defaults on the main actor.
    nonisolated static let environmentDefault = MainActor.assumeIsolated {
        MockInternetConnectivityMonitor(isConnected: true)
    }
}

// MARK: - Environment Values

public extension EnvironmentValues {

    /// The app's internet connectivity monitor.
    @Entry var internetConnectivity: any InternetConnectivityMonitorProtocol =
        MockInternetConnectivityMonitor.environmentDefault
}
