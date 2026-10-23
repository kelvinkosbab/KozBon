//
//  ConnectivityFailure.swift
//  InternetConnectivity
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - ConnectivityFailure

/// Classifies errors that mean the request never reached the server
/// because the device has no working internet connection.
///
/// A path monitor can say "online" while a request still fails — a
/// captive portal, a VPN that dropped, a connection lost mid-stream.
/// Callers use this to show the same "you're offline" message for
/// those failures as for a known-offline device.
public enum ConnectivityFailure {

    /// `URLError` codes that indicate missing or lost connectivity
    /// rather than a problem with the server or the request.
    public static let offlineCodes: Set<URLError.Code> = [
        .notConnectedToInternet,
        .networkConnectionLost,
        .dataNotAllowed,
        .internationalRoamingOff,
        .callIsActive,
        .cannotFindHost,
        .cannotConnectToHost,
        .dnsLookupFailed,
        .timedOut
    ]

    /// Whether `error` is a `URLError` caused by missing connectivity.
    public static func isOffline(_ error: any Error) -> Bool {
        guard let urlError = error as? URLError else { return false }
        return offlineCodes.contains(urlError.code)
    }
}
