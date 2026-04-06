//
//  BonjourServiceTypeScopeTests.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Testing
@testable import BonjourModels

// MARK: - BonjourServiceTypeScopeTests

@Suite("BonjourServiceTypeScope")
struct BonjourServiceTypeScopeTests {

    // MARK: - string

    @Test func allStringIsAll() {
        #expect(BonjourServiceTypeScope.all.string == "All")
    }

    @Test func builtInStringIsBuiltIn() {
        #expect(BonjourServiceTypeScope.builtIn.string == "Built-In")
    }

    @Test func createdStringIsCreated() {
        #expect(BonjourServiceTypeScope.created.string == "Created")
    }

    // MARK: - isAll

    @Test func isAllReturnsTrueForAll() {
        #expect(BonjourServiceTypeScope.all.isAll == true)
    }

    @Test func isAllReturnsFalseForOthers() {
        #expect(BonjourServiceTypeScope.builtIn.isAll == false)
        #expect(BonjourServiceTypeScope.created.isAll == false)
    }

    // MARK: - isBuiltIn

    @Test func isBuiltInReturnsTrueForBuiltIn() {
        #expect(BonjourServiceTypeScope.builtIn.isBuiltIn == true)
    }

    // MARK: - isCreated

    @Test func isCreatedReturnsTrueForCreated() {
        #expect(BonjourServiceTypeScope.created.isCreated == true)
    }

    // MARK: - allScopes

    @Test func allScopesContainsThreeElements() {
        #expect(BonjourServiceTypeScope.allScopes.count == 3)
    }

    @Test func allScopesContainsAllCases() {
        let scopes = BonjourServiceTypeScope.allScopes
        #expect(scopes.contains(.all))
        #expect(scopes.contains(.builtIn))
        #expect(scopes.contains(.created))
    }

    // MARK: - allScopeTitles

    @Test func allScopeTitlesMatchesStrings() {
        #expect(BonjourServiceTypeScope.allScopeTitles == ["All", "Built-In", "Created"])
    }

    // MARK: - CaseIterable

    @Test func caseIterableMatchesAllScopes() {
        #expect(BonjourServiceTypeScope.allCases.count == BonjourServiceTypeScope.allScopes.count)
    }
}
