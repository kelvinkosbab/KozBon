//
//  SiriServiceNameRendererTests.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourAI
import BonjourCore
import BonjourModels

// MARK: - SiriServiceNameRendererTests

/// Pin the hostname-style detection heuristic and the
/// substitution-decision logic. The renderer is the only
/// surface that changes voice output for individual service
/// names, so its conservative bias (don't substitute unless
/// the original is clearly hostname-style) needs explicit
/// tests so a future "let's be more aggressive" change has to
/// be deliberate.
@Suite("SiriServiceNameRenderer")
struct SiriServiceNameRendererTests {

    // MARK: - Hostname-Style Detection: positive cases

    @Test("`iPhone-1F2A` is recognized as hostname-style — short hex MAC suffix")
    func iPhoneHexSuffixIsHostnameStyle() {
        #expect(SiriServiceNameRenderer.looksHostnameStyle("iPhone-1F2A"))
    }

    @Test("`unknown-1A2B3C4D5E6F` is recognized as hostname-style — full MAC suffix")
    func fullMacSuffixIsHostnameStyle() {
        #expect(SiriServiceNameRenderer.looksHostnameStyle("unknown-1A2B3C4D5E6F"))
    }

    @Test("`AppleTV-AB12CD` (mixed-case hex) is hostname-style — case-insensitive match")
    func mixedCaseHexSuffixIsHostnameStyle() {
        #expect(SiriServiceNameRenderer.looksHostnameStyle("AppleTV-AB12CD"))
        #expect(SiriServiceNameRenderer.looksHostnameStyle("AppleTV-ab12cd"))
    }

    @Test("`Mac-12345678` (8-char hex) is hostname-style")
    func eightCharHexSuffixIsHostnameStyle() {
        #expect(SiriServiceNameRenderer.looksHostnameStyle("Mac-12345678"))
    }

    // MARK: - Hostname-Style Detection: negative cases

    @Test("`Living Room TV` — user-given names with spaces are NOT hostname-style")
    func userNamedDeviceWithSpacesIsNotHostnameStyle() {
        #expect(!SiriServiceNameRenderer.looksHostnameStyle("Living Room TV"))
    }

    @Test("`Kelvin's iPhone` — possessive user-given names are NOT hostname-style")
    func possessiveUserNamedIsNotHostnameStyle() {
        #expect(!SiriServiceNameRenderer.looksHostnameStyle("Kelvin's iPhone"))
    }

    @Test("`Kelvins-MacBook-Pro` — hyphenated readable hostnames are NOT hostname-style (no hex suffix)")
    func hyphenatedReadableHostnameIsNotHostnameStyle() {
        // macOS default sharing name. Reads fine through TTS
        // because the segments are pronounceable words. We
        // intentionally don't substitute these — doing so would
        // strip user intent.
        #expect(!SiriServiceNameRenderer.looksHostnameStyle("Kelvins-MacBook-Pro"))
    }

    @Test("`iPhone` — bare device class names are NOT hostname-style")
    func bareDeviceClassIsNotHostnameStyle() {
        #expect(!SiriServiceNameRenderer.looksHostnameStyle("iPhone"))
    }

    @Test("`Mac-fade` — a 4-char hex word appearing organically still classifies as hostname-style")
    func fourCharHexWordIsHostnameStyle() {
        // Edge case: "fade" is a real word but also valid hex.
        // We accept the false positive — it's vanishingly rare
        // for a user to name a device "Mac-fade", and the
        // identifier substitution will produce a sensible
        // result regardless ("Mac" via hostname pattern).
        #expect(SiriServiceNameRenderer.looksHostnameStyle("Mac-fade"))
    }

    @Test("`Mac-abc` — 3-character suffix is NOT hostname-style (below the 4-char floor)")
    func threeCharSuffixIsNotHostnameStyle() {
        // Three-character suffixes are too short to be MAC-
        // derived (the minimum useful MAC slice is 4 hex
        // chars / 2 bytes). Rejecting them avoids false
        // positives on short readable suffixes.
        #expect(!SiriServiceNameRenderer.looksHostnameStyle("Mac-abc"))
    }

    @Test("`Server-1234-Pro` — hex-looking middle segment is NOT hostname-style (anchor requires end-of-string)")
    func hexMiddleSegmentIsNotHostnameStyle() {
        // The pattern is anchored to end-of-string, so a hex
        // segment in the middle of the name doesn't match.
        // This protects names like "Server-1234-Pro" where
        // "1234" might happen to be the year, not a MAC slice.
        #expect(!SiriServiceNameRenderer.looksHostnameStyle("Server-1234-Pro"))
    }

    @Test("Empty string is NOT hostname-style — defensive against bad inputs")
    func emptyStringIsNotHostnameStyle() {
        #expect(!SiriServiceNameRenderer.looksHostnameStyle(""))
    }

    // MARK: - Voice-Friendly Name Substitution

    @Test("Hostname-style name with a resolvable identification is substituted with the friendly form")
    @MainActor
    func hostnameStyleResolvedToFriendlyName() {
        let serviceType = BonjourServiceType(name: "AirPlay", type: "airplay", transportLayer: .tcp)
        let service = BonjourService(
            service: NetService(
                domain: "local.",
                type: serviceType.fullType,
                name: "iPhone-1F2A",
                port: 7000
            ),
            serviceType: serviceType
        )
        // The hostname pattern strategy in
        // `BonjourDeviceIdentifier` matches `iPhone` from the
        // service name and returns the family identification.
        let voiced = SiriServiceNameRenderer.voiceFriendlyName(for: service)
        #expect(voiced == "iPhone")
    }

    @Test("User-given name with spaces is preserved verbatim — no substitution")
    @MainActor
    func userNamedDeviceIsPreserved() {
        let serviceType = BonjourServiceType(name: "AirPlay", type: "airplay", transportLayer: .tcp)
        let service = BonjourService(
            service: NetService(
                domain: "local.",
                type: serviceType.fullType,
                name: "Living Room TV",
                port: 7000
            ),
            serviceType: serviceType
        )
        // Even though the device-identifier could resolve
        // "Apple TV" from the name pattern, the original
        // "Living Room TV" is already voice-friendly and the
        // user explicitly chose it. Don't substitute.
        let voiced = SiriServiceNameRenderer.voiceFriendlyName(for: service)
        #expect(voiced == "Living Room TV")
    }

    @Test("Hostname-style name with NO identification falls back to the original")
    @MainActor
    func unidentifiableHostnameFallsBackToOriginal() {
        // A wholly-unrecognized service type AND service name —
        // the device identifier can't resolve anything, so we
        // return the original verbatim. Better a hex suffix
        // than substituting something inaccurate.
        let serviceType = BonjourServiceType(name: "Custom", type: "custom-thing", transportLayer: .tcp)
        let service = BonjourService(
            service: NetService(
                domain: "local.",
                type: serviceType.fullType,
                name: "unknown-AB12CD",
                port: 7000
            ),
            serviceType: serviceType
        )
        let voiced = SiriServiceNameRenderer.voiceFriendlyName(for: service)
        #expect(voiced == "unknown-AB12CD")
    }

    @Test("Bare device-class name (`iPhone`) is preserved — no improvement to be made")
    @MainActor
    func bareDeviceClassIsPreserved() {
        // Counter-test for the hostname-style detector: a
        // service literally named "iPhone" (no hex suffix)
        // should pass through. The identifier WOULD return
        // "iPhone" from the hostname pattern, but the
        // substitution would be a no-op anyway. Pin the
        // pass-through path so a future regression doesn't
        // double-process clean inputs.
        let serviceType = BonjourServiceType(name: "AirPlay", type: "airplay", transportLayer: .tcp)
        let service = BonjourService(
            service: NetService(
                domain: "local.",
                type: serviceType.fullType,
                name: "iPhone",
                port: 7000
            ),
            serviceType: serviceType
        )
        let voiced = SiriServiceNameRenderer.voiceFriendlyName(for: service)
        #expect(voiced == "iPhone")
    }
}
