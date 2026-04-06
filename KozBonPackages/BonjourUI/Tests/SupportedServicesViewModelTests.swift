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

@Suite("SupportedServicesView.ViewModel")
@MainActor
struct SupportedServicesViewModelTests {

    // MARK: - Helpers

    /// Creates a ViewModel and populates it using the static service type library
    /// (no Core Data dependency). We call `loadFromLibrary()` which sets
    /// `builtInServiceTypes` via `@testable` access to the `load()` method.
    /// Since `load()` calls `fetchAll()` which requires Core Data for persistent
    /// copies, we instead verify the filtering logic through the computed properties
    /// after the ViewModel is loaded with library data.
    ///
    /// The `load()` method fetches `BonjourServiceType.fetchAll()` which includes
    /// both the static library and Core Data persistent copies. Since Core Data
    /// is not available in SPM tests, we test the initial state and filtering
    /// behavior through the public API that does not require loaded data.

    // MARK: - Initial State

    @Test func searchTextIsEmptyInitially() {
        let vm = SupportedServicesView.ViewModel()
        #expect(vm.searchText.isEmpty)
    }

    @Test func selectedServiceTypeIsNilInitially() {
        let vm = SupportedServicesView.ViewModel()
        #expect(vm.selectedServiceType == nil)
    }

    @Test func isCreateCustomServiceTypePresentedIsFalseInitially() {
        let vm = SupportedServicesView.ViewModel()
        #expect(!vm.isCreateCustomServiceTypePresented)
    }

    // MARK: - Filtering Built-in Service Types (without Core Data)

    @Test func filteredBuiltInServiceTypesIsEmptyBeforeLoad() {
        let vm = SupportedServicesView.ViewModel()
        // Before load() is called, no data is populated
        #expect(vm.filteredBuiltInServiceTypes.isEmpty)
    }

    @Test func filteredCustomServiceTypesIsEmptyBeforeLoad() {
        let vm = SupportedServicesView.ViewModel()
        #expect(vm.filteredCustomServiceTypes.isEmpty)
    }

    @Test func filteredBuiltInServiceTypesReturnsEmptyForNoMatchBeforeLoad() {
        let vm = SupportedServicesView.ViewModel()
        vm.searchText = "XYZNONEXISTENT"
        #expect(vm.filteredBuiltInServiceTypes.isEmpty)
    }

    @Test func searchTextCanBeSetAndRead() {
        let vm = SupportedServicesView.ViewModel()
        vm.searchText = "HTTP"
        #expect(vm.searchText == "HTTP")
    }

    @Test func selectedServiceTypeCanBeSetAndRead() {
        let vm = SupportedServicesView.ViewModel()
        let serviceType = BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp)
        vm.selectedServiceType = serviceType
        #expect(vm.selectedServiceType == serviceType)
    }

    @Test func isCreateCustomServiceTypePresentedCanBeToggled() {
        let vm = SupportedServicesView.ViewModel()
        #expect(!vm.isCreateCustomServiceTypePresented)
        vm.isCreateCustomServiceTypePresented = true
        #expect(vm.isCreateCustomServiceTypePresented)
    }

    @Test func createButtonStringIsNotEmpty() {
        let vm = SupportedServicesView.ViewModel()
        #expect(!vm.createButtonString.isEmpty)
    }
}
