//
//  AIBackendStyleTests.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import Testing
import BonjourAICloud
import BonjourCore
@testable import BonjourUI

// MARK: - AIBackendStyleTests

/// Locks down the design-system extensions on ``AIBackend`` —
/// the per-backend accent color, brand icon, and SF Symbol
/// fallback. Trip-wires for accidental swaps: shipping a build
/// where the Apple Intelligence row is orange and Claude is blue
/// would be a visually loud regression, and the only test that
/// catches it is this file.
@Suite("AIBackend + Style")
struct AIBackendStyleTests {

    // MARK: - Accent Color

    @Test("Apple Intelligence uses `kozBonBlue`")
    func appleIntelligenceAccentIsBlue() {
        #expect(AIBackend.appleIntelligence.accentColor == Color.kozBonBlue)
    }

    @Test("Anthropic uses `kozBonAnthropic` (Cara orange)")
    func anthropicAccentIsOrange() {
        #expect(AIBackend.anthropic.accentColor == Color.kozBonAnthropic)
    }

    @Test("The two backends have distinct accents — never accidentally swap")
    func accentsAreDistinct() {
        // Belt-and-suspenders trip-wire: a refactor that swapped
        // the two case branches inside `accentColor` would still
        // pass the per-case assertions above if the swap was
        // symmetric. This catches the case where both ended up
        // pointing at the same value.
        #expect(AIBackend.appleIntelligence.accentColor != AIBackend.anthropic.accentColor)
    }

    // MARK: - Icon (Image)

    @Test("`icon` resolves to `Image.appleIntelligence` for Apple")
    func appleIconIsAppleIntelligence() {
        // SwiftUI's `Image` doesn't conform to Equatable, so we
        // can't compare instances directly. Instead, assert
        // through the SF-Symbol-name fallback (`iconSystemName`)
        // which IS a string. That parallel property is the only
        // way to verify which symbol the Image renders.
        #expect(AIBackend.appleIntelligence.iconSystemName == Iconography.appleIntelligence)
    }

    @Test("`icon` resolves to the Claude asset for Anthropic")
    func anthropicIconIsClaude() {
        // The Image for Anthropic resolves to the bundled SVG
        // asset (`Image("Claude", bundle: .module)`), but the
        // parallel `iconSystemName` keeps the SF Symbol fallback
        // `sparkle` for call sites that need a system-image
        // name (e.g. `Label(_:systemImage:)`). Asserting through
        // the system name is the only Equatable surface.
        #expect(AIBackend.anthropic.iconSystemName == Iconography.anthropicClaude)
    }

    @Test("The two backends use distinct icons")
    func iconsAreDistinct() {
        #expect(
            AIBackend.appleIntelligence.iconSystemName != AIBackend.anthropic.iconSystemName
        )
    }
}
