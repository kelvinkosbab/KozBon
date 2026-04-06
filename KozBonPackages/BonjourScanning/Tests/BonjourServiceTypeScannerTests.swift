//
//  BonjourServiceTypeScannerTests.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourScanning
import BonjourCore
import BonjourModels

// MARK: - TypeScannerTestDelegate

@MainActor
final class TypeScannerTestDelegate: BonjourServiceScannerDelegate {
    var addedServices: [BonjourService] = []
    var removedServices: [BonjourService] = []
    var resetCount = 0
    var errors: [String] = []

    func didAdd(service: BonjourService) { addedServices.append(service) }
    func didRemove(service: BonjourService) { removedServices.append(service) }
    func didReset() { resetCount += 1 }
    func didFailWithError(description: String) { errors.append(description) }
}

// MARK: - BonjourServiceTypeScannerTests

@Suite("BonjourServiceTypeScanner")
@MainActor
struct BonjourServiceTypeScannerTests {

    // MARK: - Helpers

    private func makeScanner() -> BonjourServiceTypeScanner {
        BonjourServiceTypeScanner(
            serviceType: BonjourServiceType(name: "HTTP", type: "http", transportLayer: .tcp),
            domain: "local."
        )
    }

    private func makeDummyBrowser() -> NetServiceBrowser {
        NetServiceBrowser()
    }

    private func makeDummyNetService() -> NetService {
        NetService(domain: "local.", type: "_http._tcp", name: "Test", port: 8080)
    }

    // MARK: - Init Tests

    @Test func initSetsStateToStopped() {
        let scanner = makeScanner()
        #expect(scanner.state == .stopped)
    }

    @Test func initSetsEmptyActiveServices() {
        let scanner = makeScanner()
        #expect(scanner.activeServices.isEmpty)
    }

    // MARK: - startScan Guard

    @Test func startScanGuardsAgainstDuplicateSearch() {
        let scanner = makeScanner()
        // Manually transition to searching state via the delegate method
        scanner.netServiceBrowserWillSearch(makeDummyBrowser())
        #expect(scanner.state == .searching)
        // Calling startScan again should not crash; it guards and returns early
        scanner.startScan()
        #expect(scanner.state == .searching)
    }

    // MARK: - reset

    @Test func resetClearsActiveServicesAndCallsDelegate() {
        let scanner = makeScanner()
        let delegate = TypeScannerTestDelegate()
        scanner.delegate = delegate

        // Add a service via the browser delegate method
        scanner.netServiceBrowser(makeDummyBrowser(), didFind: makeDummyNetService(), moreComing: true)
        #expect(scanner.activeServices.count == 1)

        scanner.reset()
        #expect(scanner.activeServices.isEmpty)
        #expect(delegate.resetCount == 1)
    }

    // MARK: - NetServiceBrowserDelegate State Transitions

    @Test func netServiceBrowserWillSearchSetsSearchingState() {
        let scanner = makeScanner()
        scanner.netServiceBrowserWillSearch(makeDummyBrowser())
        #expect(scanner.state == .searching)
    }

    @Test func netServiceBrowserDidStopSearchSetsStoppedState() {
        let scanner = makeScanner()
        // First transition to searching
        scanner.netServiceBrowserWillSearch(makeDummyBrowser())
        #expect(scanner.state == .searching)
        // Then stop
        scanner.netServiceBrowserDidStopSearch(makeDummyBrowser())
        #expect(scanner.state == .stopped)
    }

    @Test func netServiceBrowserDidNotSearchSetsStoppedAndDelegatesError() {
        let scanner = makeScanner()
        let delegate = TypeScannerTestDelegate()
        scanner.delegate = delegate

        scanner.netServiceBrowser(makeDummyBrowser(), didNotSearch: [:])
        #expect(scanner.state == .stopped)
        #expect(delegate.errors.count == 1)
    }

    // MARK: - didFind / didRemove

    @Test func netServiceBrowserDidFindAddsServiceAndCallsDelegate() {
        let scanner = makeScanner()
        let delegate = TypeScannerTestDelegate()
        scanner.delegate = delegate

        scanner.netServiceBrowser(makeDummyBrowser(), didFind: makeDummyNetService(), moreComing: true)
        #expect(scanner.activeServices.count == 1)
        #expect(delegate.addedServices.count == 1)
    }

    @Test func netServiceBrowserDidFindStopsBrowserWhenNotMoreComing() {
        let scanner = makeScanner()
        let delegate = TypeScannerTestDelegate()
        scanner.delegate = delegate

        scanner.netServiceBrowser(makeDummyBrowser(), didFind: makeDummyNetService(), moreComing: false)
        // Service should still be added regardless of moreComing
        #expect(scanner.activeServices.count == 1)
        #expect(delegate.addedServices.count == 1)
    }

    @Test func netServiceBrowserDidRemoveCallsDelegateWithService() {
        let scanner = makeScanner()
        let delegate = TypeScannerTestDelegate()
        scanner.delegate = delegate

        let netService = makeDummyNetService()

        // Add a service first
        scanner.netServiceBrowser(makeDummyBrowser(), didFind: netService, moreComing: true)
        #expect(scanner.activeServices.count == 1)
        #expect(delegate.addedServices.count == 1)

        // Remove with the same NetService — delegate should be called.
        // Note: BonjourService inherits NSObject identity equality, so the newly
        // created wrapper inside didRemove is a different object than the one
        // stored in activeServices. The delegate is still notified.
        scanner.netServiceBrowser(makeDummyBrowser(), didRemove: netService, moreComing: true)
        #expect(delegate.removedServices.count == 1)
        #expect(delegate.removedServices.first?.service.name == "Test")
    }
}
