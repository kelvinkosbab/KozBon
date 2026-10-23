//
//  ConnectivityRequirement.swift
//  InternetConnectivity
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

// MARK: - ConnectivityRequirement

/// What a feature needs from the network to do its job.
///
/// Features declare a requirement instead of checking connectivity
/// ad hoc, so "offline" is handled the same way everywhere: on-device
/// work (`.none`) keeps running, and anything that calls a remote API
/// (`.internet`) is paused with an explanation.
public enum ConnectivityRequirement: Sendable, Equatable, CaseIterable {

    /// Runs entirely on the device or the local network.
    case none

    /// Calls a remote service and fails without internet access.
    case internet

    /// Whether the requirement is met given the current connectivity.
    public func isSatisfied(isConnected: Bool) -> Bool {
        switch self {
        case .none:
            return true
        case .internet:
            return isConnected
        }
    }
}
