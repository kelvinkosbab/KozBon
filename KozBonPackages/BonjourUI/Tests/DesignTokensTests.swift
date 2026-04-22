//
//  DesignTokensTests.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import CoreGraphics
import Testing
@testable import BonjourUI

// MARK: - DesignTokensTests

/// Pins the numeric value of every published design token.
///
/// The token names encode their intended point value (e.g. `.space16` → 16pt)
/// and that contract matters at call sites — if anyone changes `.space16` to
/// something other than 16, every layout that depended on the named semantics
/// silently shifts. These tests fail loudly if a token drifts from its label.
@Suite("DesignTokens")
struct DesignTokensTests {

    // MARK: - Spacing

    @Test func spaceTokensMatchTheirNames() {
        #expect(CGFloat.space2 == 2)
        #expect(CGFloat.space4 == 4)
        #expect(CGFloat.space6 == 6)
        #expect(CGFloat.space8 == 8)
        #expect(CGFloat.space10 == 10)
        #expect(CGFloat.space12 == 12)
        #expect(CGFloat.space14 == 14)
        #expect(CGFloat.space16 == 16)
        #expect(CGFloat.space20 == 20)
        #expect(CGFloat.space24 == 24)
        #expect(CGFloat.space28 == 28)
        #expect(CGFloat.space32 == 32)
        #expect(CGFloat.space40 == 40)
        #expect(CGFloat.space48 == 48)
        #expect(CGFloat.space56 == 56)
        #expect(CGFloat.space64 == 64)
        #expect(CGFloat.space80 == 80)
        #expect(CGFloat.space96 == 96)
    }

    // MARK: - Sizes

    @Test func sizeTokensMatchTheirNames() {
        #expect(CGFloat.size4 == 4)
        #expect(CGFloat.size6 == 6)
        #expect(CGFloat.size8 == 8)
        #expect(CGFloat.size12 == 12)
        #expect(CGFloat.size14 == 14)
        #expect(CGFloat.size16 == 16)
        #expect(CGFloat.size20 == 20)
        #expect(CGFloat.size24 == 24)
        #expect(CGFloat.size28 == 28)
        #expect(CGFloat.size32 == 32)
        #expect(CGFloat.size40 == 40)
        #expect(CGFloat.size44 == 44)
        #expect(CGFloat.size48 == 48)
        #expect(CGFloat.size56 == 56)
        #expect(CGFloat.size64 == 64)
        #expect(CGFloat.size80 == 80)
        #expect(CGFloat.size96 == 96)
        #expect(CGFloat.size120 == 120)
    }

    // MARK: - Corner Radius

    @Test func radiusTokensMatchTheirNames() {
        #expect(CGFloat.radius2 == 2)
        #expect(CGFloat.radius4 == 4)
        #expect(CGFloat.radius6 == 6)
        #expect(CGFloat.radius8 == 8)
        #expect(CGFloat.radius10 == 10)
        #expect(CGFloat.radius12 == 12)
        #expect(CGFloat.radius16 == 16)
        #expect(CGFloat.radius20 == 20)
        #expect(CGFloat.radius24 == 24)
        #expect(CGFloat.radius32 == 32)
    }

    // MARK: - Stroke

    @Test func strokeTokensMatchTheirNames() {
        #expect(CGFloat.strokeHairline == 0.5)
        #expect(CGFloat.stroke1 == 1)
        #expect(CGFloat.stroke2 == 2)
        #expect(CGFloat.stroke3 == 3)
        #expect(CGFloat.stroke4 == 4)
    }

    // MARK: - Cross-namespace invariants

    /// `.space{N}` and `.size{N}` should share values today — they're
    /// semantically distinct namespaces but both read from the same 4pt grid.
    /// This test documents that expectation so a future divergence is an
    /// explicit, test-visible change rather than an accidental drift.
    @Test func spaceAndSizeShareSharedValues() {
        #expect(CGFloat.space16 == CGFloat.size16)
        #expect(CGFloat.space24 == CGFloat.size24)
        #expect(CGFloat.space32 == CGFloat.size32)
        #expect(CGFloat.space48 == CGFloat.size48)
    }
}
