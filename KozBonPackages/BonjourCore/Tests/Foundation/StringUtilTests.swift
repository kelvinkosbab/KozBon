//
//  StringUtilTests.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Testing
@testable import BonjourCore

// MARK: - StringUtilTests

@Suite("String+Util")
struct StringUtilTests {

    // MARK: - trimmed

    @Test("`trimmed` strips leading whitespace")
    func trimmedRemovesLeadingWhitespace() {
        #expect("  hello".trimmed == "hello")
    }

    @Test("`trimmed` strips trailing whitespace")
    func trimmedRemovesTrailingWhitespace() {
        #expect("hello  ".trimmed == "hello")
    }

    @Test("`trimmed` strips whitespace from both ends in a single call")
    func trimmedRemovesBothSides() {
        #expect("  hello  ".trimmed == "hello")
    }

    @Test("`trimmed` leaves interior whitespace untouched")
    func trimmedPreservesInternalSpaces() {
        #expect("hello world".trimmed == "hello world")
    }

    @Test("`trimmed` is a no-op on the empty string")
    func trimmedEmptyString() {
        #expect("".trimmed == "")
    }

    @Test("`trimmed` collapses an all-whitespace string to empty")
    func trimmedOnlyWhitespace() {
        #expect("   ".trimmed == "")
    }

    // MARK: - containsIgnoreCase

    @Test("`containsIgnoreCase` matches when needle case matches haystack")
    func containsIgnoreCaseMatchesSameCase() {
        #expect("Hello World".containsIgnoreCase("Hello"))
    }

    @Test("`containsIgnoreCase` matches a lowercase needle inside a mixed-case haystack")
    func containsIgnoreCaseMatchesDifferentCase() {
        #expect("Hello World".containsIgnoreCase("hello"))
    }

    @Test("`containsIgnoreCase` matches an uppercase needle inside a lowercase haystack")
    func containsIgnoreCaseMatchesUpperCase() {
        #expect("hello world".containsIgnoreCase("HELLO"))
    }

    @Test("`containsIgnoreCase` returns false when the needle is absent")
    func containsIgnoreCaseReturnsFalseForNoMatch() {
        #expect(!"Hello World".containsIgnoreCase("xyz"))
    }

    @Test("`containsIgnoreCase` returns false for an empty needle (Foundation `range(of:)` quirk)")
    func containsIgnoreCaseEmptySearchString() {
        // Empty string range(of:) returns nil, so containsIgnoreCase returns false
        #expect(!"Hello".containsIgnoreCase(""))
    }

    @Test("`containsIgnoreCase` matches an interior substring regardless of case")
    func containsIgnoreCaseSubstringMatch() {
        #expect("AirPlay".containsIgnoreCase("play"))
    }
}
