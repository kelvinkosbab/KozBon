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

/// Pins the one relationship between tokens that a call site depends on
/// but can't express.
///
/// Deliberately does *not* assert `.space8 == 8` for each token — that
/// form can only fail if someone edits the token and forgets the test,
/// so it catches nothing. The chat input bar's container height is a
/// real invariant: `.space6` vertical padding twice plus a `.size32`
/// button has to land on `.size44`, Apple's minimum touch target.
@Suite("DesignTokens")
struct DesignTokensTests {

    @Test("Chat input bar padding plus button height equals the 44pt minimum touch target")
    func inputBarContainerHeightMatchesMinimumTouchTarget() {
        #expect(CGFloat.space6 * 2 + CGFloat.size32 == CGFloat.size44)
    }
}
