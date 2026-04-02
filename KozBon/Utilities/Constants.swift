//
//  Constants.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - Constants

/// Centralized app-wide constants to avoid scattered magic numbers.
enum Constants {

    // MARK: - Network

    /// Constants related to Bonjour network service configuration.
    enum Network {

        /// The default mDNS domain for local network discovery.
        static let defaultDomain = "local."

        /// The minimum port number allowed when publishing a Bonjour service.
        static let minimumPort = 3001

        /// The maximum valid port number (TCP/UDP limit).
        static let maximumPort = 65535

        /// Timeout in seconds for resolving a Bonjour service's addresses.
        static let resolveTimeout: TimeInterval = 10.0

        /// Delay in milliseconds to work around NetService publish callback bug.
        static let publishDelayMilliseconds = 500
    }

    // MARK: - Refresh

    /// Constants controlling automatic refresh behavior.
    enum Refresh {

        /// The minimum time interval (in seconds) between automatic foreground refreshes.
        static let foregroundRefreshInterval: TimeInterval = 300
    }
}
