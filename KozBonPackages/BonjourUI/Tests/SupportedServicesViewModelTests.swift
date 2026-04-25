//
//  SupportedServicesViewModelTests.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Testing
@testable import BonjourUI
import BonjourCore
import BonjourModels

// MARK: - SupportedServicesViewModelTests

@Suite("SupportedServicesViewModel")
@MainActor
struct SupportedServicesViewModelTests {

    // MARK: - Helpers

    // Creates a ViewModel and populates it using the static service type library
    // (no Core Data dependency). We call `loadFromLibrary()` which sets
    // `builtInServiceTypes` via `@testable` access to the `load()` method.
    // Since `load()` calls `fetchAll()` which requires Core Data for persistent
    // copies, we instead verify the filtering logic through the computed properties
    // after the ViewModel is loaded with library data.
    //
    // The `load()` method fetches `BonjourServiceType.fetchAll()` which includes
    // both the static library and Core Data persistent copies. Since Core Data
    // is not available in SPM tests, we test the initial state and filtering
    // behavior through the public API that does not require loaded data.

    // MARK: - Initial State

    @Test("New view model starts with an empty `searchText` so the search field is blank")
    func searchTextIsEmptyInitially() {
        let vm = SupportedServicesViewModel()
        #expect(vm.searchText.isEmpty)
    }

    @Test("New view model has no `selectedServiceType` so the detail pane stays unselected")
    func selectedServiceTypeIsNilInitially() {
        let vm = SupportedServicesViewModel()
        #expect(vm.selectedServiceType == nil)
    }

    @Test("`isCreateCustomServiceTypePresented` starts false so the create-custom sheet is hidden")
    func isCreateCustomServiceTypePresentedIsFalseInitially() {
        let vm = SupportedServicesViewModel()
        #expect(!vm.isCreateCustomServiceTypePresented)
    }

    // MARK: - Filtering Built-in Service Types (without Core Data)

    @Test("`filteredBuiltInServiceTypes` is empty until `load()` populates the data")
    func filteredBuiltInServiceTypesIsEmptyBeforeLoad() {
        let vm = SupportedServicesViewModel()
        // Before load() is called, no data is populated
        #expect(vm.filteredBuiltInServiceTypes.isEmpty)
    }

    @Test("`filteredCustomServiceTypes` is empty until `load()` populates the data")
    func filteredCustomServiceTypesIsEmptyBeforeLoad() {
        let vm = SupportedServicesViewModel()
        #expect(vm.filteredCustomServiceTypes.isEmpty)
    }

    @Test("Filtering with no data loaded returns an empty result instead of crashing")
    func filteredBuiltInServiceTypesReturnsEmptyForNoMatchBeforeLoad() {
        let vm = SupportedServicesViewModel()
        vm.searchText = "XYZNONEXISTENT"
        #expect(vm.filteredBuiltInServiceTypes.isEmpty)
    }

    @Test("`searchText` round-trips through writes so the search field binds correctly")
    func searchTextCanBeSetAndRead() {
        let vm = SupportedServicesViewModel()
        vm.searchText = "HTTP"
        #expect(vm.searchText == "HTTP")
    }

    @Test("`selectedServiceType` round-trips through writes so the detail pane binding works")
    func selectedServiceTypeCanBeSetAndRead() {
        let vm = SupportedServicesViewModel()
        let serviceType = BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp)
        vm.selectedServiceType = serviceType
        #expect(vm.selectedServiceType == serviceType)
    }

    @Test("`isCreateCustomServiceTypePresented` accepts a write to true to present the create sheet")
    func isCreateCustomServiceTypePresentedCanBeToggled() {
        let vm = SupportedServicesViewModel()
        #expect(!vm.isCreateCustomServiceTypePresented)
        vm.isCreateCustomServiceTypePresented = true
        #expect(vm.isCreateCustomServiceTypePresented)
    }

    @Test("`createButtonString` is non-empty so the create button always has a label")
    func createButtonStringIsNotEmpty() {
        let vm = SupportedServicesViewModel()
        #expect(!vm.createButtonString.isEmpty)
    }
}
