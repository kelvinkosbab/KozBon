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

@Suite("SelectServiceTypeView.ViewModel")
@MainActor
struct SelectServiceTypeViewModelTests {

    // MARK: - Initial State

    @Test func searchTextIsEmptyInitially() {
        let vm = SelectServiceTypeView.ViewModel()
        #expect(vm.searchText.isEmpty)
    }

    // MARK: - Filtering (without Core Data)

    @Test func filteredBuiltInServiceTypesIsEmptyBeforeLoad() {
        let vm = SelectServiceTypeView.ViewModel()
        // Before load() is called, no data is populated
        #expect(vm.filteredBuiltInServiceTypes.isEmpty)
    }

    @Test func filteredCustomServiceTypesIsEmptyBeforeLoad() {
        let vm = SelectServiceTypeView.ViewModel()
        #expect(vm.filteredCustomServiceTypes.isEmpty)
    }

    @Test func filteredBuiltInServiceTypesReturnsEmptyForNoMatchBeforeLoad() {
        let vm = SelectServiceTypeView.ViewModel()
        vm.searchText = "NONEXISTENT"
        #expect(vm.filteredBuiltInServiceTypes.isEmpty)
    }

    @Test func searchTextCanBeSetAndRead() {
        let vm = SelectServiceTypeView.ViewModel()
        vm.searchText = "SSH"
        #expect(vm.searchText == "SSH")
    }

    @Test func filteredCustomServiceTypesStaysEmptyWithSearchText() {
        let vm = SelectServiceTypeView.ViewModel()
        vm.searchText = "custom"
        // No custom types loaded, so filtered custom should also be empty
        #expect(vm.filteredCustomServiceTypes.isEmpty)
    }
}
