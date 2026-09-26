//
//  ServiceBadgeTitle.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourLocalization

// MARK: - ServiceBadgeTitle

/// Pairs a Bonjour service type with the host it was discovered on —
/// "AirPlay – Living Room" on screen, "AirPlay, Living Room" aloud.
///
/// Deliberately not a member of ``ServiceTypeBadge``: SwiftUI infers
/// `@MainActor` for types conforming to `View`, which propagates to
/// their static members and makes plain string maths main-actor-bound.
/// Callers then need `nonisolated` annotations, and a test calling one
/// synchronously gets a concurrency warning — or, in the worst case,
/// a runtime isolation trap. A free-standing type has no isolation to
/// inherit.
enum ServiceBadgeTitle {

    /// The visible pairing, composed through a format string rather
    /// than concatenated so translators control the order and the
    /// separator.
    ///
    /// - Parameters:
    ///   - serviceType: Localized service-type name ("AirPlay").
    ///   - host: The host the service was discovered on, or `nil`.
    /// - Returns: The pairing, or the service type alone when the
    ///   host would add nothing.
    static func visible(serviceType: String, host: String?) -> String {
        guard let host = usableHost(serviceType: serviceType, host: host) else { return serviceType }
        return Strings.DetailRows.serviceTypeAndHost(serviceType, host)
    }

    /// The spoken pairing, which uses the locale's comma instead of
    /// the visible en dash — VoiceOver announces punctuation, and a
    /// braille display renders a dash as literal cells.
    static func spoken(serviceType: String, host: String?) -> String {
        guard let host = usableHost(serviceType: serviceType, host: host) else { return serviceType }
        return Strings.Accessibility.serviceTypeAndHost(serviceType, host)
    }

    /// The host, or `nil` when pairing it with the type would add
    /// nothing: an unresolved service reports an empty name, and
    /// plenty of devices advertise a name identical to their type,
    /// where "AirPlay – AirPlay" is noise.
    private static func usableHost(serviceType: String, host: String?) -> String? {
        guard let host, !host.isEmpty, host != serviceType else { return nil }
        return host
    }
}
