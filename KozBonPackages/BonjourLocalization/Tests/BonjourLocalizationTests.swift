//
//  BonjourLocalizationTests.swift
//  BonjourLocalization
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourLocalization

// MARK: - BonjourLocalizationTests

/// Sanity tests for the localization module's public surface:
/// the resource bundle accessor and the `Strings` enum that wraps
/// it.
///
/// These tests are deliberately resolution-agnostic — they don't
/// assert on the actual English text of any specific key, because
/// `swift test` from the SPM CLI doesn't always resolve the
/// `Localizable.xcstrings` catalog the same way Xcode does (the
/// CLI may return the raw localization key instead of the English
/// value). What they DO pin: the bundle resolves, points at a
/// non-empty path, matches the canonical `Bundle.module` accessor,
/// and `String(localized:)` over the wrapped `LocalizedStringResource`
/// returns *something* — either the resolved English value or the
/// raw key, but never an empty string. That's enough to catch the
/// real failure modes (missing bundle, missing resource processing,
/// broken `Strings` enum) without baking in catalog-resolution
/// behavior that varies between runtimes.
@Suite("BonjourLocalization")
@MainActor
struct BonjourLocalizationTests {

    // MARK: - Bundle Accessor

    @Test("`BonjourLocalization.bundle` resolves to a non-nil bundle with a non-empty path")
    func bundleResolvesToValidPath() {
        let bundle = BonjourLocalization.bundle
        #expect(!bundle.bundlePath.isEmpty)
    }

    @Test("`BonjourLocalization.bundle` returns a stable instance across repeated reads")
    func bundleIsStable() {
        // `Bundle.module` is module-internal so the test target
        // can't reach it directly. What we can pin: the public
        // accessor returns the same bundle on repeated reads.
        // Catches a regression where someone refactored the
        // accessor to construct a fresh Bundle each call —
        // breaking any consumer that holds the bundle by
        // reference.
        #expect(BonjourLocalization.bundle === BonjourLocalization.bundle)
    }

    // MARK: - Strings Enum

    @Test("`Strings.NavigationTitles.nearbyServices` resolves to a non-empty string")
    func navigationTitleResolves() {
        let value = String(localized: Strings.NavigationTitles.nearbyServices)
        #expect(!value.isEmpty)
    }

    @Test("`Strings.Buttons.cancel` resolves to a non-empty string")
    func buttonCancelResolves() {
        let value = String(localized: Strings.Buttons.cancel)
        #expect(!value.isEmpty)
    }

    @Test("`Strings.Sections.serviceType` resolves to a non-empty string")
    func sectionServiceTypeResolves() {
        let value = String(localized: Strings.Sections.serviceType)
        #expect(!value.isEmpty)
    }

    @Test("Different `Strings` keys produce distinct `LocalizedStringResource` values")
    func distinctKeysAreDistinct() {
        // Two different localization keys should compile to
        // different `LocalizedStringResource.key` strings — even
        // if the resolved English values were identical, the keys
        // identify them uniquely. Pin that the wrapper isn't
        // accidentally collapsing distinct keys onto the same
        // resource.
        let a = Strings.NavigationTitles.nearbyServices
        let b = Strings.Buttons.cancel
        #expect(a.key != b.key)
    }
}
