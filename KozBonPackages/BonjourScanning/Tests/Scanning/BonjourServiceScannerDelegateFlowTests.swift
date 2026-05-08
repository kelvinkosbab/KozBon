//
//  BonjourServiceScannerDelegateFlowTests.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourScanning
import BonjourCore
import BonjourModels

// MARK: - BonjourServiceScannerDelegateFlowTests

@Suite("BonjourServiceScanner Delegate Flow")
@MainActor
struct BonjourServiceScannerDelegateFlowTests {

    // MARK: - Helpers

    private func makeService(name: String = "Test", type: String = "http") -> BonjourService {
        let serviceType = BonjourServiceType(name: name, type: type, transportLayer: .tcp)
        return BonjourService(
            service: NetService(domain: "local.", type: serviceType.fullType, name: name, port: 8080),
            serviceType: serviceType
        )
    }

    private func makeDelegate() -> TypeScannerTestDelegate {
        TypeScannerTestDelegate()
    }

    // MARK: - didAdd

    @Test("`didAdd` forwards the service to the delegate and stores it for tracking")
    func didAddForwardsToDelegateAndTracksService() {
        let scanner = BonjourServiceScanner()
        let delegate = makeDelegate()
        scanner.delegate = delegate

        let service = makeService()
        scanner.didAdd(service: service)

        #expect(delegate.addedServices.count == 1)
        #expect(delegate.addedServices.first?.service.name == "Test")

        // Clean up
        scanner.didReset()
        scanner.delegate = nil
    }

    // MARK: - didRemove

    @Test("`didRemove` forwards to the delegate and drops the service from tracking")
    func didRemoveForwardsToDelegateAndRemovesService() {
        let scanner = BonjourServiceScanner()
        let delegate = makeDelegate()
        scanner.delegate = delegate

        let service = makeService()
        scanner.didAdd(service: service)
        #expect(delegate.addedServices.count == 1)

        scanner.didRemove(service: service)
        #expect(delegate.removedServices.count == 1)
        #expect(delegate.removedServices.first?.service.name == "Test")

        // Clean up
        scanner.didReset()
        scanner.delegate = nil
    }

    // MARK: - didReset

    @Test("`didReset` forwards to the delegate and clears the tracked services list")
    func didResetForwardsToDelegateAndClearsServices() {
        let scanner = BonjourServiceScanner()
        let delegate = makeDelegate()
        scanner.delegate = delegate

        let service = makeService()
        scanner.didAdd(service: service)

        scanner.didReset()
        #expect(delegate.resetCount == 1)

        // Clean up
        scanner.delegate = nil
    }

    // MARK: - didFailWithError

    @Test("`didFailWithError` propagates the error description verbatim to the delegate")
    func didFailWithErrorForwardsToDelegate() {
        let scanner = BonjourServiceScanner()
        let delegate = makeDelegate()
        scanner.delegate = delegate

        scanner.didFailWithError(description: "Network unavailable")
        #expect(delegate.errors.count == 1)
        #expect(delegate.errors.first == "Network unavailable")

        // Clean up
        scanner.didReset()
        scanner.delegate = nil
    }

    // MARK: - isProcessing

    @Test("`isProcessing` is false when the scanner is idle with no per-type scanners running")
    func isProcessingIsFalseWhenNoScanners() {
        let scanner = BonjourServiceScanner()
        // When idle with no type scanners running, isProcessing should be false
        #expect(!scanner.isProcessing)
    }

    // MARK: - Weak Delegate

    @Test("Scanner holds the delegate weakly so deallocating it nils the reference")
    func delegateIsWeak() {
        let scanner = BonjourServiceScanner()
        var delegate: TypeScannerTestDelegate? = makeDelegate()
        scanner.delegate = delegate
        #expect(scanner.delegate != nil)

        delegate = nil
        #expect(scanner.delegate == nil)

        // Clean up
        scanner.didReset()
    }
}
