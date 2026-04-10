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

    @Test func searchTextIsEmptyInitially() {
        let vm = SupportedServicesViewModel()
        #expect(vm.searchText.isEmpty)
    }

    @Test func selectedServiceTypeIsNilInitially() {
        let vm = SupportedServicesViewModel()
        #expect(vm.selectedServiceType == nil)
    }

    @Test func isCreateCustomServiceTypePresentedIsFalseInitially() {
        let vm = SupportedServicesViewModel()
        #expect(!vm.isCreateCustomServiceTypePresented)
    }

    // MARK: - Filtering Built-in Service Types (without Core Data)

    @Test func filteredBuiltInServiceTypesIsEmptyBeforeLoad() {
        let vm = SupportedServicesViewModel()
        // Before load() is called, no data is populated
        #expect(vm.filteredBuiltInServiceTypes.isEmpty)
    }

    @Test func filteredCustomServiceTypesIsEmptyBeforeLoad() {
        let vm = SupportedServicesViewModel()
        #expect(vm.filteredCustomServiceTypes.isEmpty)
    }

    @Test func filteredBuiltInServiceTypesReturnsEmptyForNoMatchBeforeLoad() {
        let vm = SupportedServicesViewModel()
        vm.searchText = "XYZNONEXISTENT"
        #expect(vm.filteredBuiltInServiceTypes.isEmpty)
    }

    @Test func searchTextCanBeSetAndRead() {
        let vm = SupportedServicesViewModel()
        vm.searchText = "HTTP"
        #expect(vm.searchText == "HTTP")
    }

    @Test func selectedServiceTypeCanBeSetAndRead() {
        let vm = SupportedServicesViewModel()
        let serviceType = BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp)
        vm.selectedServiceType = serviceType
        #expect(vm.selectedServiceType == serviceType)
    }

    @Test func isCreateCustomServiceTypePresentedCanBeToggled() {
        let vm = SupportedServicesViewModel()
        #expect(!vm.isCreateCustomServiceTypePresented)
        vm.isCreateCustomServiceTypePresented = true
        #expect(vm.isCreateCustomServiceTypePresented)
    }

    @Test func createButtonStringIsNotEmpty() {
        let vm = SupportedServicesViewModel()
        #expect(!vm.createButtonString.isEmpty)
    }
}
