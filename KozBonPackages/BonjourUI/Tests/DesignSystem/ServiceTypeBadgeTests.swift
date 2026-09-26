//
//  ServiceTypeBadgeTests.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Testing
@testable import BonjourUI

// MARK: - ServiceTypeBadgeTitleTests

/// The badge's title composition — the part that decides whether the
/// wide-layout navigation bar reads "AirPlay" or
/// "AirPlay – Living Room".
///
/// Values aren't pinned to localized output: under the SPM CLI a
/// catalog lookup falls back to the raw key, so the assertions below
/// check the *branching* rather than the rendered separator.
/// Translation correctness is CI's job (`validate-localizations.py`).
@Suite("ServiceTypeBadge · title")
struct ServiceTypeBadgeTitleTests {

    @Test("No host renders the service type alone")
    func noHostIsTypeOnly() {
        #expect(ServiceTypeBadge.title(serviceType: "AirPlay", host: nil) == "AirPlay")
    }

    /// An unresolved service can report an empty name, which would
    /// otherwise render a badge with a dangling separator.
    @Test("An empty host renders the service type alone")
    func emptyHostIsTypeOnly() {
        #expect(ServiceTypeBadge.title(serviceType: "AirPlay", host: "") == "AirPlay")
    }

    /// Plenty of devices advertise a service whose name matches its
    /// type — "AirPlay – AirPlay" is noise, not information.
    @Test("A host identical to the service type doesn't repeat itself")
    func duplicateHostIsCollapsed() {
        #expect(ServiceTypeBadge.title(serviceType: "AirPlay", host: "AirPlay") == "AirPlay")
    }

    @Test("A distinct host produces a combined title")
    func distinctHostIsCombined() {
        let combined = ServiceTypeBadge.title(serviceType: "AirPlay", host: "Living Room")

        #expect(combined != "AirPlay")
        #expect(combined != ServiceTypeBadge.title(serviceType: "AirPlay", host: nil))
    }

    /// Both halves have to reach the format string — a helper that
    /// dropped one would still differ from the type-only case and
    /// pass the test above.
    @Test("Both halves reach the composed title")
    func bothHalvesAreUsed() {
        let first = ServiceTypeBadge.title(serviceType: "AirPlay", host: "Living Room")
        let differentHost = ServiceTypeBadge.title(serviceType: "AirPlay", host: "Kitchen")
        let differentType = ServiceTypeBadge.title(serviceType: "Matter", host: "Living Room")

        #expect(first != differentHost, "the host has to affect the title")
        #expect(first != differentType, "the service type has to affect the title")
    }
}

// MARK: - ServiceTypeBadgeAccessibilityTests

/// The spoken form is deliberately *not* the visible form: VoiceOver
/// announces punctuation, and a braille display renders an en dash
/// as literal cells, so the accessibility label pairs the two halves
/// with the locale's comma instead.
@Suite("ServiceTypeBadge · accessibility text")
struct ServiceTypeBadgeAccessibilityTests {

    @Test("Uses a different separator from the visible title")
    func separatorDiffersFromVisible() {
        let spoken = ServiceTypeBadge.accessibilityText(serviceType: "AirPlay", host: "Living Room")
        let visible = ServiceTypeBadge.title(serviceType: "AirPlay", host: "Living Room")

        #expect(spoken != visible)
    }

    /// The visible title drops the host at accessibility Dynamic Type
    /// sizes; the spoken one never should, so it can't share the
    /// same collapsing rules beyond the empty / duplicate cases.
    @Test("Keeps the host whenever it adds information")
    func keepsUsefulHost() {
        let spoken = ServiceTypeBadge.accessibilityText(serviceType: "AirPlay", host: "Living Room")

        #expect(spoken != "AirPlay")
    }

    @Test("Collapses the same cases the visible title does", arguments: [nil, "", "AirPlay"])
    func collapsesEmptyAndDuplicate(_ host: String?) {
        #expect(ServiceTypeBadge.accessibilityText(serviceType: "AirPlay", host: host) == "AirPlay")
    }
}
