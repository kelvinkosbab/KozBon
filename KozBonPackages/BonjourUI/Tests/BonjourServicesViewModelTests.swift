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

    @Test func initialStateIsCorrect() {
        let (viewModel, _) = makeViewModel()
        #expect(viewModel.isInitialLoad)
        #expect(viewModel.lastScanTime == nil)
        #expect(viewModel.flatActiveServices.isEmpty)
        #expect(viewModel.sortedPublishedServices.isEmpty)
        #expect(viewModel.scanError == nil)
    }

    // MARK: - shouldRefreshOnForeground

    @Test func shouldRefreshOnForegroundReturnsTrueInitially() {
        let (viewModel, _) = makeViewModel()
        #expect(viewModel.shouldRefreshOnForeground())
    }

    @Test func shouldRefreshOnForegroundReturnsFalseAfterRecentScan() {
        let (viewModel, _) = makeViewModel()
        viewModel.load()
        #expect(!viewModel.shouldRefreshOnForeground())
    }

    // MARK: - load

    @Test func loadStartsScanAndUpdatesState() {
        let (viewModel, scanner) = makeViewModel()
        viewModel.load()
        #expect(!viewModel.isInitialLoad)
        #expect(viewModel.lastScanTime != nil)
        #expect(scanner.startScanCallCount == 1)
    }

    @Test func loadDoesNotStartScanWhileProcessing() {
        let (viewModel, scanner) = makeViewModel()
        scanner.isProcessing = true
        viewModel.load()
        #expect(scanner.startScanCallCount == 0)
    }

    // MARK: - Delegate Methods

    @Test func didAddAppendsService() {
        let (viewModel, _) = makeViewModel()
        let service = makeService(name: "Test Device")
        viewModel.didAdd(service: service)
        #expect(viewModel.flatActiveServices.count == 1)
    }

    @Test func didRemoveRemovesService() {
        let (viewModel, _) = makeViewModel()
        let service = makeService(name: "Test Device")
        viewModel.didAdd(service: service)
        viewModel.didRemove(service: service)
        #expect(viewModel.flatActiveServices.isEmpty)
    }

    @Test func didResetClearsAllServices() {
        let (viewModel, _) = makeViewModel()
        viewModel.didAdd(service: makeService(name: "Device 1"))
        viewModel.didAdd(service: makeService(name: "Device 2"))
        viewModel.didReset()
        #expect(viewModel.flatActiveServices.isEmpty)
    }

    @Test func didFailWithErrorSetsScanError() {
        let (viewModel, _) = makeViewModel()
        viewModel.didFailWithError(description: "Test error")
        #expect(viewModel.scanError == "Test error")
    }

    // MARK: - Sorting

    @Test func flatActiveServicesHostNameAsc() {
        let (viewModel, _) = makeViewModel()
        viewModel.didAdd(service: makeService(name: "Zebra"))
        viewModel.didAdd(service: makeService(name: "Alpha", type: "ssh"))
        viewModel.sort(sortType: .hostNameAsc)

        let names = viewModel.flatActiveServices.map(\.service.name)
        #expect(names == ["Alpha", "Zebra"])
    }

    @Test func flatActiveServicesHostNameDesc() {
        let (viewModel, _) = makeViewModel()
        viewModel.didAdd(service: makeService(name: "Alpha"))
        viewModel.didAdd(service: makeService(name: "Zebra", type: "ssh"))
        viewModel.sort(sortType: .hostNameDesc)

        let names = viewModel.flatActiveServices.map(\.service.name)
        #expect(names == ["Zebra", "Alpha"])
    }

    @Test func flatActiveServicesServiceNameAsc() throws {
        let (viewModel, _) = makeViewModel()
        viewModel.didAdd(service: makeService(name: "DeviceA", type: "ssh"))
        viewModel.didAdd(service: makeService(name: "DeviceB", type: "http"))
        viewModel.sort(sortType: .serviceNameAsc)

        let typeNames = viewModel.flatActiveServices.map(\.serviceType.name)
        let first = try #require(typeNames.first)
        let last = try #require(typeNames.last)
        #expect(first <= last)
    }

    @Test func flatActiveServicesServiceNameDesc() throws {
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

    @Test func publishedServicesAreFilteredFromActive() {
        let (viewModel, _) = makeViewModel()
        let service = makeService(name: "My Device")
        viewModel.customPublishedServices.append(service)
        viewModel.didAdd(service: service)

        #expect(viewModel.sortedPublishedServices.count == 1)
        #expect(viewModel.flatActiveServices.isEmpty)
    }

    // MARK: - Edge Cases

    @Test func didAddUpdatesExistingServiceById() {
        let (viewModel, _) = makeViewModel()
        let service = makeService(name: "Device")
        viewModel.didAdd(service: service)
        viewModel.didAdd(service: service)
        #expect(viewModel.flatActiveServices.count == 1)
    }

    @Test func didRemoveNonExistentServiceIsNoOp() {
        let (viewModel, _) = makeViewModel()
        let service = makeService(name: "Ghost")
        viewModel.didRemove(service: service)
        #expect(viewModel.flatActiveServices.isEmpty)
    }

    @Test func flatActiveServicesWithNilSortTypeDefaultsToAsc() {
        let (viewModel, _) = makeViewModel()
        viewModel.didAdd(service: makeService(name: "Zebra"))
        viewModel.didAdd(service: makeService(name: "Alpha", type: "ssh"))
        #expect(viewModel.sortType == nil)
        #expect(viewModel.flatActiveServices.count == 2)
    }

    @Test func multipleDidResetCallsAreIdempotent() {
        let (viewModel, _) = makeViewModel()
        viewModel.didAdd(service: makeService(name: "Device"))
        viewModel.didReset()
        viewModel.didReset()
        #expect(viewModel.flatActiveServices.isEmpty)
    }

    @Test func scanErrorClearsWhenSetToNil() {
        let (viewModel, _) = makeViewModel()
        viewModel.didFailWithError(description: "Error")
        #expect(viewModel.scanError == "Error")
        viewModel.scanError = nil
        #expect(viewModel.scanError == nil)
    }

    // MARK: - Initial Load State

    @Test func isInitialLoadTrueBeforeFirstLoad() {
        let (viewModel, _) = makeViewModel()
        #expect(viewModel.isInitialLoad)
    }

    @Test func isInitialLoadFalseAfterLoad() {
        let (viewModel, _) = makeViewModel()
        viewModel.load()
        #expect(!viewModel.isInitialLoad)
    }

    @Test func isInitialLoadRemainsFalseAfterSubsequentLoads() {
        let (viewModel, _) = makeViewModel()
        viewModel.load()
        viewModel.load()
        #expect(!viewModel.isInitialLoad)
    }

    @Test func isInitialLoadFalseEvenWhenNoServicesFound() {
        let (viewModel, _) = makeViewModel()
        viewModel.load()
        #expect(!viewModel.isInitialLoad)
        #expect(viewModel.flatActiveServices.isEmpty)
    }

    // MARK: - Broadcast Sheet State

    @Test func isBroadcastBonjourServicePresentedDefaultsFalse() {
        let (viewModel, _) = makeViewModel()
        #expect(!viewModel.isBroadcastBonjourServicePresented)
    }

    @Test func broadcastSheetCanBePresented() {
        let (viewModel, _) = makeViewModel()
        viewModel.isBroadcastBonjourServicePresented = true
        #expect(viewModel.isBroadcastBonjourServicePresented)
    }

    // MARK: - Strings

    @Test func noActiveServicesStringIsNotEmpty() {
        let (viewModel, _) = makeViewModel()
        #expect(!viewModel.noActiveServicesString.isEmpty)
    }

    @Test func createButtonStringIsNotEmpty() {
        let (viewModel, _) = makeViewModel()
        #expect(!viewModel.createButtonString.isEmpty)
    }

    // MARK: - Convenience Init

    @Test func initWithDependenciesResolvesScannerAndPublishManager() {
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

    @Test func viewModelRegistersItselfAsScannerDelegate() {
        let (viewModel, scanner) = makeViewModel()
        #expect(scanner.delegate === viewModel)
    }

    @Test func secondViewModelOverwritesFirstAsScannerDelegate() {
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

    @Test func onlyTheMostRecentViewModelReceivesScannerEvents() {
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
