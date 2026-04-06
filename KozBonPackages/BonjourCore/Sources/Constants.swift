//
//  Constants.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - Constants

/// Centralized app-wide constants to avoid scattered magic numbers.
public enum Constants {

    // MARK: - Network

    /// Constants related to Bonjour network service configuration.
    public enum Network {

        /// The default mDNS domain for local network discovery.
        public static let defaultDomain = "local."

        /// The minimum port number allowed when publishing a Bonjour service.
        public static let minimumPort = 3001

        /// The maximum valid port number (TCP/UDP limit).
        public static let maximumPort = 65535

        /// Timeout in seconds for resolving a Bonjour service's addresses.
        public static let resolveTimeout: TimeInterval = 10.0

        /// Delay in milliseconds to work around NetService publish callback bug.
        public static let publishDelayMilliseconds = 500
    }

    // MARK: - Refresh

    /// Constants controlling automatic refresh behavior.
    public enum Refresh {

        /// The minimum time interval (in seconds) between automatic foreground refreshes.
        public static let foregroundRefreshInterval: TimeInterval = 300
    }
}
