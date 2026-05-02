//
//  AppVersionTests.swift
//  BonjourCore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourCore

// MARK: - AppVersionTests

/// Pin the contract `Settings · About` and any future bug-report
/// payloads rely on: the lookup must surface the `Info.plist` value
/// when present and fall back to a stable placeholder when missing,
/// without ever crashing the caller.
@Suite("AppVersion")
struct AppVersionTests {

    // MARK: - Info Dictionary Lookup

    @Test("Marketing reads `CFBundleShortVersionString` from a populated info dictionary")
    func marketingReturnsBundleShortVersion() {
        let info: [String: Any] = ["CFBundleShortVersionString": "4.2"]
        #expect(AppVersion.marketing(infoDictionary: info) == "4.2")
    }

    @Test("Build reads `CFBundleVersion` from a populated info dictionary")
    func buildReturnsBundleVersion() {
        let info: [String: Any] = ["CFBundleVersion": "114"]
        #expect(AppVersion.build(infoDictionary: info) == "114")
    }

    // MARK: - Fallback to Placeholder

    @Test("Marketing falls back to the placeholder when the key is missing")
    func marketingFallsBackWhenKeyMissing() {
        let info: [String: Any] = ["UnrelatedKey": "value"]
        #expect(AppVersion.marketing(infoDictionary: info) == AppVersion.unknownPlaceholder)
    }

    @Test("Build falls back to the placeholder when the key is missing")
    func buildFallsBackWhenKeyMissing() {
        let info: [String: Any] = ["UnrelatedKey": "value"]
        #expect(AppVersion.build(infoDictionary: info) == AppVersion.unknownPlaceholder)
    }

    @Test("Both accessors fall back when the entire info dictionary is nil")
    func bothFallBackOnNilInfoDictionary() {
        // Mirrors the SwiftUI-preview / SPM-tests path where
        // `Bundle.module.infoDictionary` returns `nil` because the
        // module has no embedded plist. The accessors must not
        // crash and must return a stable placeholder so an About
        // row rendered against this bundle still has a value to
        // display.
        #expect(AppVersion.marketing(infoDictionary: nil) == AppVersion.unknownPlaceholder)
        #expect(AppVersion.build(infoDictionary: nil) == AppVersion.unknownPlaceholder)
    }

    @Test("Both accessors fall back when the value is the wrong type")
    func bothFallBackOnNonStringValue() {
        // Defends the cast: an Info.plist that somehow stored the
        // version key as a number or a dictionary shouldn't take
        // down the About section. The lookup uses `as? String`,
        // so a wrong-type value falls through to the placeholder.
        let info: [String: Any] = [
            "CFBundleShortVersionString": 4.2,
            "CFBundleVersion": ["nested": "thing"]
        ]
        #expect(AppVersion.marketing(infoDictionary: info) == AppVersion.unknownPlaceholder)
        #expect(AppVersion.build(infoDictionary: info) == AppVersion.unknownPlaceholder)
    }

    // MARK: - Placeholder

    @Test("Placeholder is the em-dash glyph so it reads as missing data in any locale")
    func placeholderIsEmDash() {
        // Em dash, not a hyphen — the visual signal "this row has no
        // value yet" is universal across locales without spawning a
        // translation burden. The exact codepoint matters because
        // tests downstream of the About section (and any bug-report
        // payload) match on this string.
        #expect(AppVersion.unknownPlaceholder == "—")
    }

    // MARK: - Combined Form

    @Test("`formatted` joins marketing and build with a `(...)` wrapper")
    func formattedJoinsMarketingAndBuild() {
        // The combined accessor reads from `Bundle.main`, so the
        // exact strings depend on the test host. We can still
        // pin the *shape* — non-empty, contains a parenthesis,
        // contains the marketing and build values verbatim.
        let formatted = AppVersion.formatted
        #expect(!formatted.isEmpty)
        #expect(formatted.contains("("))
        #expect(formatted.contains(")"))
        #expect(formatted.contains(AppVersion.marketing))
        #expect(formatted.contains(AppVersion.build))
    }

    // MARK: - Bundle Convenience

    @Test("`marketing(in:)` and `build(in:)` route through the info-dictionary accessors")
    func bundleAccessorsRouteThroughInfoDictionaryPath() {
        // Use any bundle — `Bundle.main` for the test runner. The
        // contract is: whatever `bundle.infoDictionary` contains
        // (or nil), the bundle accessor and the info-dictionary
        // accessor agree.
        let bundle = Bundle.main
        #expect(
            AppVersion.marketing(in: bundle) == AppVersion.marketing(infoDictionary: bundle.infoDictionary)
        )
        #expect(
            AppVersion.build(in: bundle) == AppVersion.build(infoDictionary: bundle.infoDictionary)
        )
    }
}
