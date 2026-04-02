//
//  BonjourServicesViewModelTests.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import KozBon

// MARK: - BonjourServicesViewModelTests

@Suite("BonjourServicesViewModel")
@MainActor
struct BonjourServicesViewModelTests {

    // MARK: - Helpers

    private func makeViewModel() -> (BonjourServicesViewModel, MockBonjourServiceScanner) {
        let scanner = MockBonjourServiceScanner()
        let viewModel = BonjourServicesViewModel(serviceScanner: scanner)
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
        #expect(viewModel.sortedActiveServices.isEmpty)
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
        #expect(viewModel.sortedActiveServices.count == 1)
    }

    @Test func didRemoveRemovesService() {
        let (viewModel, _) = makeViewModel()
        let service = makeService(name: "Test Device")
        viewModel.didAdd(service: service)
        viewModel.didRemove(service: service)
        #expect(viewModel.sortedActiveServices.isEmpty)
    }

    @Test func didResetClearsAllServices() {
        let (viewModel, _) = makeViewModel()
        viewModel.didAdd(service: makeService(name: "Device 1"))
        viewModel.didAdd(service: makeService(name: "Device 2"))
        viewModel.didReset()
        #expect(viewModel.sortedActiveServices.isEmpty)
    }

    @Test func didFailWithErrorSetsScanError() {
        let (viewModel, _) = makeViewModel()
        viewModel.didFailWithError(description: "Test error")
        #expect(viewModel.scanError == "Test error")
    }

    // MARK: - Sorting

    @Test func sortedActiveServicesRespectsSortType() {
        let (viewModel, _) = makeViewModel()
        viewModel.didAdd(service: makeService(name: "Zebra"))
        viewModel.didAdd(service: makeService(name: "Alpha", type: "ssh"))
        viewModel.sort(sortType: .hostNameAsc)

        let names = viewModel.sortedActiveServices.map(\.service.name)
        #expect(names == ["Alpha", "Zebra"])
    }

    @Test func sortedActiveServicesDescending() {
        let (viewModel, _) = makeViewModel()
        viewModel.didAdd(service: makeService(name: "Alpha"))
        viewModel.didAdd(service: makeService(name: "Zebra", type: "ssh"))
        viewModel.sort(sortType: .hostNameDesc)

        let names = viewModel.sortedActiveServices.map(\.service.name)
        #expect(names == ["Zebra", "Alpha"])
    }

    // MARK: - Published vs Active Filtering

    @Test func publishedServicesAreFilteredFromActive() {
        let (viewModel, _) = makeViewModel()
        let service = makeService(name: "My Device")
        viewModel.customPublishedServices.append(service)
        viewModel.didAdd(service: service)

        #expect(viewModel.sortedPublishedServices.count == 1)
        #expect(viewModel.sortedActiveServices.isEmpty)
    }
}
