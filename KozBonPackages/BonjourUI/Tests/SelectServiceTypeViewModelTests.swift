//
//  SelectServiceTypeViewModelTests.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Testing
@testable import BonjourUI
import BonjourCore
import BonjourModels

// MARK: - SelectServiceTypeViewModelTests

@Suite("SelectServiceTypeViewModel")
@MainActor
struct SelectServiceTypeViewModelTests {

    // MARK: - Initial State

    @Test("New view model starts with an empty `searchText` so the search field is blank")
    func searchTextIsEmptyInitially() {
        let vm = SelectServiceTypeViewModel()
        #expect(vm.searchText.isEmpty)
    }

    // MARK: - Filtering (without Core Data)

    @Test("`filteredBuiltInServiceTypes` is empty until `load()` populates the data")
    func filteredBuiltInServiceTypesIsEmptyBeforeLoad() {
        let vm = SelectServiceTypeViewModel()
        // Before load() is called, no data is populated
        #expect(vm.filteredBuiltInServiceTypes.isEmpty)
    }

    @Test("`filteredCustomServiceTypes` is empty until `load()` populates the data")
    func filteredCustomServiceTypesIsEmptyBeforeLoad() {
        let vm = SelectServiceTypeViewModel()
        #expect(vm.filteredCustomServiceTypes.isEmpty)
    }

    @Test("Filtering with no data loaded returns an empty result instead of crashing")
    func filteredBuiltInServiceTypesReturnsEmptyForNoMatchBeforeLoad() {
        let vm = SelectServiceTypeViewModel()
        vm.searchText = "NONEXISTENT"
        #expect(vm.filteredBuiltInServiceTypes.isEmpty)
    }

    @Test("`searchText` round-trips through writes so the search field binds correctly")
    func searchTextCanBeSetAndRead() {
        let vm = SelectServiceTypeViewModel()
        vm.searchText = "SSH"
        #expect(vm.searchText == "SSH")
    }

    @Test("Setting `searchText` does not invent custom service types when none have been loaded")
    func filteredCustomServiceTypesStaysEmptyWithSearchText() {
        let vm = SelectServiceTypeViewModel()
        vm.searchText = "custom"
        // No custom types loaded, so filtered custom should also be empty
        #expect(vm.filteredCustomServiceTypes.isEmpty)
    }
}
