//
//  BonjourServiceCategoricalSummaryTests.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourAI
import BonjourCore
import BonjourModels

// MARK: - BonjourServiceCategoricalSummaryTests

/// Pin the categorical-rollup voice summary used by the
/// `Scan…` and `List…` Siri intents. The `BonjourServiceCategory`
/// taxonomy is shared with the in-app filters, so the summary
/// here doubles as a regression suite against the
/// category-membership checks.
@Suite("Array<BonjourService> · voiceCategoricalSummary")
@MainActor
struct BonjourServiceCategoricalSummaryTests {

    // MARK: - Helpers

    private func makeService(type: String, transport: TransportLayer = .tcp) -> BonjourService {
        let serviceType = BonjourServiceType(name: type, type: type, transportLayer: transport)
        return BonjourService(
            service: NetService(
                domain: "local.",
                type: serviceType.fullType,
                name: type,
                port: 8080
            ),
            serviceType: serviceType
        )
    }

    // MARK: - Empty

    @Test("Empty array produces an empty string — caller handles the no-services case explicitly")
    func emptyArrayProducesEmptyString() {
        let services: [BonjourService] = []
        #expect(services.voiceCategoricalSummary().isEmpty)
    }

    // MARK: - Singular Phrasing

    @Test("Single Apple-device service renders as `1 Apple device` (singular)")
    func singleAppleDeviceUsesSingularLabel() {
        let services = [makeService(type: "airplay")]
        #expect(services.voiceCategoricalSummary() == "1 Apple device")
    }

    @Test("Single printer service renders as `1 printer` (singular)")
    func singlePrinterUsesSingularLabel() {
        let services = [makeService(type: "ipp")]
        #expect(services.voiceCategoricalSummary() == "1 printer")
    }

    @Test("Single uncategorized service renders as `1 other` (singular)")
    func singleUncategorizedServiceUsesSingularLabel() {
        let services = [makeService(type: "completely-novel-protocol")]
        #expect(services.voiceCategoricalSummary() == "1 other")
    }

    // MARK: - Plural Phrasing

    @Test("Multiple Apple-device services render as `N Apple devices` (plural)")
    func multipleAppleDevicesUsePluralLabel() {
        let services = [
            makeService(type: "airplay"),
            makeService(type: "raop"),
            makeService(type: "appletv")
        ]
        #expect(services.voiceCategoricalSummary() == "3 Apple devices")
    }

    @Test("Multiple printers render as `N printers` (plural)")
    func multiplePrintersUsePluralLabel() {
        let services = [
            makeService(type: "ipp"),
            makeService(type: "printer")
        ]
        #expect(services.voiceCategoricalSummary() == "2 printers")
    }

    // MARK: - Multi-Category Composition

    @Test("Two-category mix uses `<phrase> and <phrase>` — no Oxford comma")
    func twoCategoriesUseSimpleAnd() {
        let services = [
            makeService(type: "airplay"),
            makeService(type: "ipp")
        ]
        let summary = services.voiceCategoricalSummary()
        #expect(summary == "1 Apple device and 1 printer")
    }

    @Test("Three-or-more categories use `<phrase>, <phrase>, and <phrase>` (Oxford-comma form)")
    func threeCategoriesUseOxfordCommaForm() {
        let services = [
            makeService(type: "airplay"),
            makeService(type: "ipp"),
            makeService(type: "ssh")
        ]
        let summary = services.voiceCategoricalSummary()
        #expect(summary == "1 Apple device, 1 printer, and 1 remote access service")
    }

    // MARK: - Render Order

    @Test("Render order is stable: Apple → media → printers → smart home → remote access → other")
    func renderOrderIsStable() {
        // Build the input in REVERSE category order to verify
        // the output uses the configured order regardless of
        // input ordering. Without the explicit render order,
        // a Dictionary-based grouping would render in
        // hash-iteration order — different across runs.
        //
        // Type choices matter: each service must match EXACTLY
        // ONE category given the bucketing rule (first match in
        // `BonjourServiceCategory.allCases`). `spotify-connect`
        // would land in `smartHome`, not `mediaAndStreaming`,
        // because it appears in both lists and `smartHome`
        // sorts first. `googlecast` is in `mediaAndStreaming`
        // only — the cleanest test fixture.
        let services = [
            makeService(type: "completely-novel-protocol"),  // other
            makeService(type: "ssh"),                        // remoteAccess
            makeService(type: "matter"),                     // smartHome
            makeService(type: "ipp"),                        // printersAndScanners
            makeService(type: "googlecast"),                 // mediaAndStreaming
            makeService(type: "airplay")                     // appleDevices
        ]
        let summary = services.voiceCategoricalSummary()
        // Bind every range up front so the comparisons below
        // don't need force-unwraps. A missing range fails the
        // first `try #require`, naming the absent category in
        // the failure output.
        guard let appleIndex = summary.range(of: "Apple")?.lowerBound,
              let mediaIndex = summary.range(of: "media")?.lowerBound,
              let printerIndex = summary.range(of: "printer")?.lowerBound,
              let smartIndex = summary.range(of: "smart home")?.lowerBound,
              let remoteIndex = summary.range(of: "remote access")?.lowerBound,
              let otherIndex = summary.range(of: "other")?.lowerBound else {
            Issue.record(
                "Expected every category to appear in the summary; got: \(summary)"
            )
            return
        }

        // All categories appear in the documented order.
        #expect(appleIndex < mediaIndex)
        #expect(mediaIndex < printerIndex)
        #expect(printerIndex < smartIndex)
        #expect(smartIndex < remoteIndex)
        #expect(remoteIndex < otherIndex)
    }

    // MARK: - First-Match Rule

    @Test("Each service is counted exactly once — overlapping categories don't double-count")
    func eachServiceCountedOnce() {
        // AirPlay matches BOTH `appleDevices` and
        // `mediaAndStreaming` in the live taxonomy. The
        // first-match rule means a single AirPlay service
        // contributes 1 to `appleDevices` only — never 1 to
        // each. Total counts must always sum to input count
        // for the summary to be honest.
        let services = Array(repeating: makeService(type: "airplay"), count: 5)
        let summary = services.voiceCategoricalSummary()
        // Every count in the summary should sum to 5.
        let digits = summary.compactMap { Int(String($0)) }
        let total = digits.reduce(0, +)
        #expect(total == 5)
    }

    // MARK: - Overflow Bucket

    @Test("Services not matching any predefined category fall into the `other(s)` bucket")
    func uncategorizedServicesFallIntoOtherBucket() {
        let services = [
            makeService(type: "airplay"),
            makeService(type: "completely-novel-protocol"),
            makeService(type: "another-novel-thing")
        ]
        let summary = services.voiceCategoricalSummary()
        #expect(summary.contains("1 Apple device"))
        #expect(summary.contains("2 others"))
    }

    // MARK: - No-Marker Output

    @Test("Output never contains `nil` or other Swift-internal sentinels — defensive against future regressions")
    func outputIsAllNaturalLanguage() {
        let services = [makeService(type: "completely-novel-protocol")]
        let summary = services.voiceCategoricalSummary()
        #expect(!summary.contains("nil"))
        #expect(!summary.contains("Optional"))
        #expect(!summary.contains("BonjourServiceCategory"))
    }
}
