//
//  BonjourServicesViewModelTests.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourCore
import BonjourModels
import BonjourScanning
@testable import BonjourUI

// MARK: - BonjourServicesViewModelTests

@Suite("BonjourServicesViewModel")
@MainActor
struct BonjourServicesViewModelTests {

    // MARK: - Helpers

    private func makeViewModel() -> (BonjourServicesViewModel, MockBonjourServiceScanner) {
        let scanner = MockBonjourServiceScanner()
        let publishManager = MockBonjourPublishManager()
        let viewModel = BonjourServicesViewModel(
            serviceScanner: scanner,
            publishManager: publishManager
        )
        return (viewModel, scanner)
    }

    private func makeService(name: String, type: String = "http") -> BonjourService {
        let serviceType = BonjourServiceType(name: name, type: type, transportLayer: .tcp)
        return BonjourService(
            service: NetService(domain: "local.", type: serviceType.fullType, name: name, port: 8080),
            serviceType: serviceType
        )
    }

    // MARK: - Initial State

    @Test("New view model starts in the initial-load state with no services or errors")
    func initialStateIsCorrect() {
        let (viewModel, _) = makeViewModel()
        #expect(viewModel.isInitialLoad)
        #expect(viewModel.lastScanTime == nil)
        #expect(viewModel.flatActiveServices.isEmpty)
        #expect(viewModel.sortedPublishedServices.isEmpty)
        #expect(viewModel.scanError == nil)
    }

    // MARK: - shouldRefreshOnForeground

    @Test("`shouldRefreshOnForeground` is true before the first scan ever runs")
    func shouldRefreshOnForegroundReturnsTrueInitially() {
        let (viewModel, _) = makeViewModel()
        #expect(viewModel.shouldRefreshOnForeground())
    }

    @Test("`shouldRefreshOnForeground` is false right after `load()` to avoid back-to-back scans")
    func shouldRefreshOnForegroundReturnsFalseAfterRecentScan() {
        let (viewModel, _) = makeViewModel()
        viewModel.load()
        #expect(!viewModel.shouldRefreshOnForeground())
    }

    // MARK: - load

    @Test("`load()` triggers a scan and records `lastScanTime` and exits the initial-load state")
    func loadStartsScanAndUpdatesState() {
        let (viewModel, scanner) = makeViewModel()
        viewModel.load()
        #expect(!viewModel.isInitialLoad)
        #expect(viewModel.lastScanTime != nil)
        #expect(scanner.startScanCallCount == 1)
    }

    @Test("`load()` is a no-op while the scanner reports `isProcessing`")
    func loadDoesNotStartScanWhileProcessing() {
        let (viewModel, scanner) = makeViewModel()
        scanner.isProcessing = true
        viewModel.load()
        #expect(scanner.startScanCallCount == 0)
    }

    // MARK: - Delegate Methods

    @Test("`didAdd(service:)` appends a new service to `flatActiveServices`")
    func didAddAppendsService() {
        let (viewModel, _) = makeViewModel()
        let service = makeService(name: "Test Device")
        viewModel.didAdd(service: service)
        #expect(viewModel.flatActiveServices.count == 1)
    }

    @Test("`didRemove(service:)` removes the matching entry from `flatActiveServices`")
    func didRemoveRemovesService() {
        let (viewModel, _) = makeViewModel()
        let service = makeService(name: "Test Device")
        viewModel.didAdd(service: service)
        viewModel.didRemove(service: service)
        #expect(viewModel.flatActiveServices.isEmpty)
    }

    @Test("`didReset()` empties `flatActiveServices` regardless of how many services were tracked")
    func didResetClearsAllServices() {
        let (viewModel, _) = makeViewModel()
        viewModel.didAdd(service: makeService(name: "Device 1"))
        viewModel.didAdd(service: makeService(name: "Device 2"))
        viewModel.didReset()
        #expect(viewModel.flatActiveServices.isEmpty)
    }

    @Test("`didFailWithError(description:)` surfaces the message via `scanError` for the UI")
    func didFailWithErrorSetsScanError() {
        let (viewModel, _) = makeViewModel()
        viewModel.didFailWithError(description: "Test error")
        #expect(viewModel.scanError == "Test error")
    }

    // MARK: - Sorting

    @Test("`hostNameAsc` sort orders `flatActiveServices` alphabetically by host name")
    func flatActiveServicesHostNameAsc() {
        let (viewModel, _) = makeViewModel()
        viewModel.didAdd(service: makeService(name: "Zebra"))
        viewModel.didAdd(service: makeService(name: "Alpha", type: "ssh"))
        viewModel.sort(sortType: .hostNameAsc)

        let names = viewModel.flatActiveServices.map(\.service.name)
        #expect(names == ["Alpha", "Zebra"])
    }

    @Test("`hostNameDesc` sort orders `flatActiveServices` reverse-alphabetically by host name")
    func flatActiveServicesHostNameDesc() {
        let (viewModel, _) = makeViewModel()
        viewModel.didAdd(service: makeService(name: "Alpha"))
        viewModel.didAdd(service: makeService(name: "Zebra", type: "ssh"))
        viewModel.sort(sortType: .hostNameDesc)

        let names = viewModel.flatActiveServices.map(\.service.name)
        #expect(names == ["Zebra", "Alpha"])
    }

    @Test("`serviceNameAsc` sort orders `flatActiveServices` ascending by service-type name")
    func flatActiveServicesServiceNameAsc() throws {
        let (viewModel, _) = makeViewModel()
        viewModel.didAdd(service: makeService(name: "DeviceA", type: "ssh"))
        viewModel.didAdd(service: makeService(name: "DeviceB", type: "http"))
        viewModel.sort(sortType: .serviceNameAsc)

        let typeNames = viewModel.flatActiveServices.map(\.serviceType.name)
        let first = try #require(typeNames.first)
        let last = try #require(typeNames.last)
        #expect(first <= last)
    }

    @Test("`serviceNameDesc` sort orders `flatActiveServices` descending by service-type name")
    func flatActiveServicesServiceNameDesc() throws {
        let (viewModel, _) = makeViewModel()
        viewModel.didAdd(service: makeService(name: "DeviceA", type: "http"))
        viewModel.didAdd(service: makeService(name: "DeviceB", type: "ssh"))
        viewModel.sort(sortType: .serviceNameDesc)

        let typeNames = viewModel.flatActiveServices.map(\.serviceType.name)
        let first = try #require(typeNames.first)
        let last = try #require(typeNames.last)
        #expect(first >= last)
    }

    // MARK: - Published vs Active Filtering

    @Test("Locally-published services appear in `sortedPublishedServices` and not in `flatActiveServices`")
    func publishedServicesAreFilteredFromActive() {
        let (viewModel, _) = makeViewModel()
        let service = makeService(name: "My Device")
        viewModel.customPublishedServices.append(service)
        viewModel.didAdd(service: service)

        #expect(viewModel.sortedPublishedServices.count == 1)
        #expect(viewModel.flatActiveServices.isEmpty)
    }

    // MARK: - Edge Cases

    @Test("`didAdd` deduplicates by id so adding the same service twice yields one entry")
    func didAddUpdatesExistingServiceById() {
        let (viewModel, _) = makeViewModel()
        let service = makeService(name: "Device")
        viewModel.didAdd(service: service)
        viewModel.didAdd(service: service)
        #expect(viewModel.flatActiveServices.count == 1)
    }

    @Test("`didRemove` for a service that was never added is a safe no-op")
    func didRemoveNonExistentServiceIsNoOp() {
        let (viewModel, _) = makeViewModel()
        let service = makeService(name: "Ghost")
        viewModel.didRemove(service: service)
        #expect(viewModel.flatActiveServices.isEmpty)
    }

    @Test("With `sortType == nil`, `flatActiveServices` still surfaces every added service")
    func flatActiveServicesWithNilSortTypeDefaultsToAsc() {
        let (viewModel, _) = makeViewModel()
        viewModel.didAdd(service: makeService(name: "Zebra"))
        viewModel.didAdd(service: makeService(name: "Alpha", type: "ssh"))
        #expect(viewModel.sortType == nil)
        #expect(viewModel.flatActiveServices.count == 2)
    }

    @Test("Calling `didReset` twice in a row does not throw or re-populate services")
    func multipleDidResetCallsAreIdempotent() {
        let (viewModel, _) = makeViewModel()
        viewModel.didAdd(service: makeService(name: "Device"))
        viewModel.didReset()
        viewModel.didReset()
        #expect(viewModel.flatActiveServices.isEmpty)
    }

    @Test("Setting `scanError = nil` dismisses a previously-set error so the UI can hide it")
    func scanErrorClearsWhenSetToNil() {
        let (viewModel, _) = makeViewModel()
        viewModel.didFailWithError(description: "Error")
        #expect(viewModel.scanError == "Error")
        viewModel.scanError = nil
        #expect(viewModel.scanError == nil)
    }

    // MARK: - Initial Load State

    @Test("`isInitialLoad` is true before `load()` so the UI can show the first-run placeholder")
    func isInitialLoadTrueBeforeFirstLoad() {
        let (viewModel, _) = makeViewModel()
        #expect(viewModel.isInitialLoad)
    }

    @Test("`isInitialLoad` flips to false after the first `load()` call")
    func isInitialLoadFalseAfterLoad() {
        let (viewModel, _) = makeViewModel()
        viewModel.load()
        #expect(!viewModel.isInitialLoad)
    }

    @Test("`isInitialLoad` stays false through repeated `load()` calls — it never re-enters initial state")
    func isInitialLoadRemainsFalseAfterSubsequentLoads() {
        let (viewModel, _) = makeViewModel()
        viewModel.load()
        viewModel.load()
        #expect(!viewModel.isInitialLoad)
    }

    @Test("`isInitialLoad` flips to false after `load()` even if zero services are discovered")
    func isInitialLoadFalseEvenWhenNoServicesFound() {
        let (viewModel, _) = makeViewModel()
        viewModel.load()
        #expect(!viewModel.isInitialLoad)
        #expect(viewModel.flatActiveServices.isEmpty)
    }

    // MARK: - Broadcast Sheet State

    @Test("`isBroadcastBonjourServicePresented` starts false so the broadcast sheet is hidden")
    func isBroadcastBonjourServicePresentedDefaultsFalse() {
        let (viewModel, _) = makeViewModel()
        #expect(!viewModel.isBroadcastBonjourServicePresented)
    }

    @Test("`isBroadcastBonjourServicePresented` accepts a write to true to present the sheet")
    func broadcastSheetCanBePresented() {
        let (viewModel, _) = makeViewModel()
        viewModel.isBroadcastBonjourServicePresented = true
        #expect(viewModel.isBroadcastBonjourServicePresented)
    }

    // MARK: - Strings

    @Test("`noActiveServicesString` is non-empty so the empty-state UI always has copy to display")
    func noActiveServicesStringIsNotEmpty() {
        let (viewModel, _) = makeViewModel()
        #expect(!viewModel.noActiveServicesString.isEmpty)
    }

    @Test("`createButtonString` is non-empty so the create button always has a label")
    func createButtonStringIsNotEmpty() {
        let (viewModel, _) = makeViewModel()
        #expect(!viewModel.createButtonString.isEmpty)
    }

    // MARK: - Convenience Init

    @Test("Convenience init pulls the exact scanner and publish manager out of the dependency container")
    func initWithDependenciesResolvesScannerAndPublishManager() {
        let scanner = MockBonjourServiceScanner()
        let publishManager = MockBonjourPublishManager()
        let container = DependencyContainer(
            bonjourServiceScanner: scanner,
            bonjourPublishManager: publishManager
        )

        let viewModel = BonjourServicesViewModel(dependencies: container)

        // The convenience init should pull the same underlying scanner and
        // publish manager out of the container — comparing by ObjectIdentifier
        // guarantees we got the exact instances back, not copies.
        #expect(ObjectIdentifier(viewModel.serviceScanner as AnyObject)
                == ObjectIdentifier(scanner))
        #expect(ObjectIdentifier(viewModel.publishManager as AnyObject)
                == ObjectIdentifier(publishManager))
    }

    // MARK: - Scanner Delegate Ownership
    //
    // These tests pin down the scanner's single-delegate semantics so that
    // nobody reintroduces the "Discover tab shows zero services" bug. The
    // scanner exposes `weak var delegate`, so creating a second view model
    // against the same scanner silently steals the delegate slot from the
    // first. The app ships with one shared `BonjourServicesViewModel` hoisted
    // to `AppCore` to avoid exactly this.

    @Test("View model registers itself as the scanner's delegate during initialization")
    func viewModelRegistersItselfAsScannerDelegate() {
        let (viewModel, scanner) = makeViewModel()
        #expect(scanner.delegate === viewModel)
    }

    @Test("Second view model on the same scanner clobbers the first as delegate (single-slot semantics)")
    func secondViewModelOverwritesFirstAsScannerDelegate() {
        let scanner = MockBonjourServiceScanner()
        let publishManager = MockBonjourPublishManager()

        let first = BonjourServicesViewModel(
            serviceScanner: scanner,
            publishManager: publishManager
        )
        #expect(scanner.delegate === first)

        let second = BonjourServicesViewModel(
            serviceScanner: scanner,
            publishManager: publishManager
        )

        // The scanner's `weak var delegate` is a single pointer — creating a
        // second view model against the same scanner overwrites the first.
        // This is the reason `AppCore` hoists one shared view model and
        // passes it to both the Discover tab and the Chat tab.
        #expect(scanner.delegate === second)
        #expect(scanner.delegate !== first)
    }

    @Test("Only the most recently-attached view model receives scanner events — the empty-Discover-tab regression")
    func onlyTheMostRecentViewModelReceivesScannerEvents() {
        let scanner = MockBonjourServiceScanner()
        let publishManager = MockBonjourPublishManager()

        let first = BonjourServicesViewModel(
            serviceScanner: scanner,
            publishManager: publishManager
        )
        let second = BonjourServicesViewModel(
            serviceScanner: scanner,
            publishManager: publishManager
        )

        // Simulate the scanner reporting a discovered service to its current
        // delegate (which is `second` after the second init ran).
        let service = makeService(name: "Discovered")
        scanner.delegate?.didAdd(service: service)

        // The second view model sees the service; the first is "blind" —
        // exactly the bug that made the Discover tab appear empty while
        // the Chat tab (initialized later) could still see services.
        #expect(second.flatActiveServices.count == 1)
        #expect(first.flatActiveServices.isEmpty)
    }
}
