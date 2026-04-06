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

    @Test func trimmedRemovesLeadingWhitespace() {
        #expect("  hello".trimmed == "hello")
    }

    @Test func trimmedRemovesTrailingWhitespace() {
        #expect("hello  ".trimmed == "hello")
    }

    @Test func trimmedRemovesBothSides() {
        #expect("  hello  ".trimmed == "hello")
    }

    @Test func trimmedPreservesInternalSpaces() {
        #expect("hello world".trimmed == "hello world")
    }

    @Test func trimmedEmptyString() {
        #expect("".trimmed == "")
    }

    @Test func trimmedOnlyWhitespace() {
        #expect("   ".trimmed == "")
    }

    // MARK: - containsIgnoreCase

    @Test func containsIgnoreCaseMatchesSameCase() {
        #expect("Hello World".containsIgnoreCase("Hello"))
    }

    @Test func containsIgnoreCaseMatchesDifferentCase() {
        #expect("Hello World".containsIgnoreCase("hello"))
    }

    @Test func containsIgnoreCaseMatchesUpperCase() {
        #expect("hello world".containsIgnoreCase("HELLO"))
    }

    @Test func containsIgnoreCaseReturnsFalseForNoMatch() {
        #expect(!"Hello World".containsIgnoreCase("xyz"))
    }

    @Test func containsIgnoreCaseEmptySearchString() {
        // Empty string range(of:) returns nil, so containsIgnoreCase returns false
        #expect(!"Hello".containsIgnoreCase(""))
    }

    @Test func containsIgnoreCaseSubstringMatch() {
        #expect("AirPlay".containsIgnoreCase("play"))
    }
}
