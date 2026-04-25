//
//  BonjourServiceCategoryTests.swift
//  BonjourModels
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourModels
import BonjourCore

// MARK: - BonjourServiceCategoryTests

/// Pin the membership and presentation contract of
/// `BonjourServiceCategory`. The enum is consumed by three
/// surfaces — Discover filter, Library filter, AI prompt — so
/// regressions here ripple out broadly.
@Suite("BonjourServiceCategory")
@MainActor
struct BonjourServiceCategoryTests {

    // MARK: - Helpers

    private func makeType(_ type: String, transportLayer: TransportLayer = .tcp) -> BonjourServiceType {
        BonjourServiceType(name: type.uppercased(), type: type, transportLayer: transportLayer)
    }

    // MARK: - Membership — Smart Home

    @Test("Smart-home category recognises core HomeKit/Matter/Thread types")
    func smartHomeMatchesCoreTypes() {
        let category = BonjourServiceCategory.smartHome
        #expect(category.matches(makeType("matter")))
        #expect(category.matches(makeType("hap")))
        #expect(category.matches(makeType("homekit")))
        #expect(category.matches(makeType("meshcop", transportLayer: .udp)))
    }

    @Test("Smart-home category recognises modern third-party hubs (Hue, LIFX, Ecobee)")
    func smartHomeMatchesThirdPartyHubs() {
        let category = BonjourServiceCategory.smartHome
        #expect(category.matches(makeType("hue")))
        #expect(category.matches(makeType("lifx", transportLayer: .udp)))
        #expect(category.matches(makeType("ecobee")))
    }

    // MARK: - Membership — Apple Devices

    @Test("Apple-devices category recognises every Apple TV variant (v1 through v4)")
    func appleDevicesMatchesAllAppleTVVariants() {
        let category = BonjourServiceCategory.appleDevices
        #expect(category.matches(makeType("appletv")))
        #expect(category.matches(makeType("appletv-v2")))
        #expect(category.matches(makeType("appletv-v3")))
        #expect(category.matches(makeType("appletv-v4")))
        #expect(category.matches(makeType("appletv-itunes")))
        #expect(category.matches(makeType("appletv-pair")))
    }

    @Test("Apple-devices category recognises every Apple Mobile Device sync variant (v1, v2, v3)")
    func appleDevicesMatchesAllMobDevVariants() {
        let category = BonjourServiceCategory.appleDevices
        #expect(category.matches(makeType("apple-mobdev")))
        #expect(category.matches(makeType("apple-mobdev2")))
        #expect(category.matches(makeType("apple-mobdev3")))
    }

    // MARK: - Membership — Media & Streaming

    @Test("Media-and-streaming category recognises self-hosted media servers (Plex, Jellyfin, Emby, Kodi)")
    func mediaAndStreamingMatchesSelfHostedServers() {
        let category = BonjourServiceCategory.mediaAndStreaming
        #expect(category.matches(makeType("plex")))
        #expect(category.matches(makeType("jellyfin")))
        #expect(category.matches(makeType("emby")))
        #expect(category.matches(makeType("xbmc")))
    }

    @Test("Media-and-streaming category recognises mainstream casting/streaming protocols")
    func mediaAndStreamingMatchesCastingProtocols() {
        let category = BonjourServiceCategory.mediaAndStreaming
        #expect(category.matches(makeType("airplay")))
        #expect(category.matches(makeType("googlecast")))
        #expect(category.matches(makeType("spotify-connect")))
        #expect(category.matches(makeType("daap")))
    }

    // MARK: - Membership — Printers & Scanners

    @Test("Printers-and-scanners category recognises every IPP and AirScan variant")
    func printersMatchesIppAndScanVariants() {
        let category = BonjourServiceCategory.printersAndScanners
        #expect(category.matches(makeType("ipp")))
        #expect(category.matches(makeType("ipps")))
        #expect(category.matches(makeType("printer")))
        #expect(category.matches(makeType("uscan")))
        #expect(category.matches(makeType("uscans")))
        #expect(category.matches(makeType("scanner")))
    }

    // MARK: - Membership — Remote Access

    @Test("Remote-access category recognises shell, screen-sharing, and ARD protocols")
    func remoteAccessMatchesShellAndDesktopProtocols() {
        let category = BonjourServiceCategory.remoteAccess
        #expect(category.matches(makeType("ssh")))
        #expect(category.matches(makeType("vnc")))
        #expect(category.matches(makeType("rdp")))
        #expect(category.matches(makeType("net-assistant")))
    }

    @Test("Remote-access category does NOT include Kerberos (auth, not access)")
    func remoteAccessExcludesKerberos() {
        // Removed during the category-extraction refactor — Kerberos
        // is authentication infrastructure, not a remote-access tool.
        // Pin the exclusion so it doesn't drift back.
        let category = BonjourServiceCategory.remoteAccess
        #expect(!category.matches(makeType("kerberos")))
    }

    // MARK: - Negative — Unrelated Types

    @Test("Categories don't false-positive on unrelated types (e.g. plain `http`)")
    func categoriesExcludeUnrelatedTypes() {
        let httpType = makeType("http")
        for category in BonjourServiceCategory.allCases {
            #expect(!category.matches(httpType), "\(category) should not match http")
        }
    }

    @Test("Categories don't match an unknown / made-up type")
    func categoriesExcludeUnknownTypes() {
        let unknown = makeType("totally-fake-protocol")
        for category in BonjourServiceCategory.allCases {
            #expect(!category.matches(unknown), "\(category) should not match unknown")
        }
    }

    // MARK: - Cross-Category Overlap

    @Test("AirPlay matches both `appleDevices` and `mediaAndStreaming` — overlap is intentional")
    func airplayMatchesBothAppleAndMedia() {
        // Documented in the type-level comment: categories aren't a
        // strict partition. AirPlay is the canonical case where a
        // user picking either lens reasonably expects to see it.
        let airplay = makeType("airplay")
        #expect(BonjourServiceCategory.appleDevices.matches(airplay))
        #expect(BonjourServiceCategory.mediaAndStreaming.matches(airplay))
    }

    @Test("HomeKit matches both `smartHome` and `appleDevices` — overlap is intentional")
    func homekitMatchesBothSmartHomeAndApple() {
        let homekit = makeType("homekit")
        #expect(BonjourServiceCategory.smartHome.matches(homekit))
        #expect(BonjourServiceCategory.appleDevices.matches(homekit))
    }

    // MARK: - Service-Level Overload

    @Test("`matches(_:)` works on a `BonjourService` (not just `BonjourServiceType`)")
    func matchesAcceptsService() {
        let serviceType = BonjourServiceType(name: "AirPlay", type: "airplay", transportLayer: .tcp)
        let service = BonjourService(
            service: NetService(
                domain: "local.",
                type: serviceType.fullType,
                name: "Test",
                port: 7000
            ),
            serviceType: serviceType
        )
        #expect(BonjourServiceCategory.mediaAndStreaming.matches(service))
        #expect(!BonjourServiceCategory.printersAndScanners.matches(service))
    }

    // MARK: - Identifiable / CaseIterable

    @Test("`allCases` exposes exactly five categories — adding one is a contract change")
    func allCasesHasFiveCategories() {
        // If this fails because a 6th category was added, update the
        // count and add tests for the new bucket. If it fails because
        // a category was *removed*, audit the three consumers
        // (Discover filter, Library filter, AI prompt) for stale
        // references.
        #expect(BonjourServiceCategory.allCases.count == 5)
    }

    @Test("Each category has a unique `id` so SwiftUI list iteration is deterministic")
    func categoryIdsAreUnique() {
        let ids = BonjourServiceCategory.allCases.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    // MARK: - Display

    @Test("Every category has a non-empty localized title — menus never render a blank row")
    func everyCategoryHasNonEmptyTitle() {
        for category in BonjourServiceCategory.allCases {
            #expect(!String(localized: category.title).isEmpty)
        }
    }

    @Test("Every category has a non-empty SF Symbol icon name — menus never render a blank icon")
    func everyCategoryHasIconName() {
        for category in BonjourServiceCategory.allCases {
            #expect(!category.iconName.isEmpty)
        }
    }

    @Test("Every category has a non-empty `promptLabel` so the AI context block is well-formed")
    func everyCategoryHasPromptLabel() {
        for category in BonjourServiceCategory.allCases {
            #expect(!category.promptLabel.isEmpty)
        }
    }

    @Test("`promptLabel` is plain English so the model sees stable category names regardless of UI locale")
    func promptLabelIsEnglish() {
        // Spot-check: the labels are intentionally not localized
        // (the model reasons in English; the response is localized at
        // the very end). If we ever wire `promptLabel` to a localized
        // string by mistake, this test catches it.
        #expect(BonjourServiceCategory.smartHome.promptLabel == "Smart Home")
        #expect(BonjourServiceCategory.appleDevices.promptLabel == "Apple Devices")
        #expect(BonjourServiceCategory.mediaAndStreaming.promptLabel == "Media & Streaming")
        #expect(BonjourServiceCategory.printersAndScanners.promptLabel == "Printers & Scanners")
        #expect(BonjourServiceCategory.remoteAccess.promptLabel == "Remote Access")
    }

    // MARK: - Type Strings

    @Test("`typeStrings` is non-empty for every category — empty would silently break filters")
    func everyCategoryHasNonEmptyTypeStrings() {
        for category in BonjourServiceCategory.allCases {
            #expect(!category.typeStrings.isEmpty, "\(category) has empty typeStrings")
        }
    }
}
