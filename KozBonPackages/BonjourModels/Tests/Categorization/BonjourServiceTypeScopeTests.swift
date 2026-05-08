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

    @Test("`.all.string` is the segmented-control label `All`")
    func allStringIsAll() {
        #expect(BonjourServiceTypeScope.all.string == "All")
    }

    @Test("`.builtIn.string` is the segmented-control label `Built-In`")
    func builtInStringIsBuiltIn() {
        #expect(BonjourServiceTypeScope.builtIn.string == "Built-In")
    }

    @Test("`.created.string` is the segmented-control label `Created`")
    func createdStringIsCreated() {
        #expect(BonjourServiceTypeScope.created.string == "Created")
    }

    // MARK: - isAll

    @Test("`.all.isAll` is true")
    func isAllReturnsTrueForAll() {
        #expect(BonjourServiceTypeScope.all.isAll == true)
    }

    @Test("Non-`.all` scopes report `isAll == false`")
    func isAllReturnsFalseForOthers() {
        #expect(BonjourServiceTypeScope.builtIn.isAll == false)
        #expect(BonjourServiceTypeScope.created.isAll == false)
    }

    // MARK: - isBuiltIn

    @Test("`.builtIn.isBuiltIn` is true")
    func isBuiltInReturnsTrueForBuiltIn() {
        #expect(BonjourServiceTypeScope.builtIn.isBuiltIn == true)
    }

    // MARK: - isCreated

    @Test("`.created.isCreated` is true")
    func isCreatedReturnsTrueForCreated() {
        #expect(BonjourServiceTypeScope.created.isCreated == true)
    }

    // MARK: - allScopes

    @Test("`allScopes` exposes exactly the three segmented-control buckets")
    func allScopesContainsThreeElements() {
        #expect(BonjourServiceTypeScope.allScopes.count == 3)
    }

    @Test("`allScopes` includes `.all`, `.builtIn`, and `.created`")
    func allScopesContainsAllCases() {
        let scopes = BonjourServiceTypeScope.allScopes
        #expect(scopes.contains(.all))
        #expect(scopes.contains(.builtIn))
        #expect(scopes.contains(.created))
    }

    // MARK: - allScopeTitles

    @Test("`allScopeTitles` returns the three labels in display order")
    func allScopeTitlesMatchesStrings() {
        #expect(BonjourServiceTypeScope.allScopeTitles == ["All", "Built-In", "Created"])
    }

    // MARK: - CaseIterable

    @Test("`allCases` and `allScopes` stay in sync so neither path drops a scope")
    func caseIterableMatchesAllScopes() {
        #expect(BonjourServiceTypeScope.allCases.count == BonjourServiceTypeScope.allScopes.count)
    }
}
