//
//  MockDependenciesTests.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourScanning
import BonjourCore
import BonjourModels

// MARK: - TestScannerDelegate

@MainActor
final class TestScannerDelegate: BonjourServiceScannerDelegate {
    var addedServices: [BonjourService] = []
    var removedServices: [BonjourService] = []
    var resetCount = 0
    var errors: [String] = []

    func didAdd(service: BonjourService) { addedServices.append(service) }
    func didRemove(service: BonjourService) { removedServices.append(service) }
    func didReset() { resetCount += 1 }
    func didFailWithError(description: String) { errors.append(description) }
}

// MARK: - MockDependenciesTests

@Suite("MockDependencies")
@MainActor
struct MockDependenciesTests {

    // MARK: - Helpers

    private func makeService(name: String = "Test", type: String = "http") -> BonjourService {
        let serviceType = BonjourServiceType(name: name, type: type, transportLayer: .tcp)
        return BonjourService(service: NetService(domain: "local.", type: serviceType.fullType, name: name, port: 8080), serviceType: serviceType)
    }

    // MARK: - MockBonjourServiceScanner Tests

    @Test func scannerStartScanIncrementsCount() {
        let scanner = MockBonjourServiceScanner()
        scanner.startScan()
        #expect(scanner.startScanCallCount == 1)
        scanner.startScan()
        #expect(scanner.startScanCallCount == 2)
    }

    @Test func scannerStartScanSetsProcessing() {
        let scanner = MockBonjourServiceScanner()
        #expect(!scanner.isProcessing)
        scanner.startScan()
        #expect(scanner.isProcessing)
    }

    @Test func scannerStopScanIncrementsCount() {
        let scanner = MockBonjourServiceScanner()
        scanner.stopScan()
        #expect(scanner.stopScanCallCount == 1)
        scanner.stopScan()
        #expect(scanner.stopScanCallCount == 2)
    }

    @Test func scannerStopScanClearsProcessing() {
        let scanner = MockBonjourServiceScanner()
        scanner.startScan()
        #expect(scanner.isProcessing)
        scanner.stopScan()
        #expect(!scanner.isProcessing)
    }

    @Test func scannerResetClearsState() {
        let scanner = MockBonjourServiceScanner()
        scanner.startScan()
        scanner.startScan()
        scanner.stopScan()
        #expect(scanner.startScanCallCount == 2)
        #expect(scanner.stopScanCallCount == 1)
        #expect(!scanner.isProcessing)
        scanner.startScan()
        scanner.reset()
        #expect(scanner.startScanCallCount == 0)
        #expect(scanner.stopScanCallCount == 0)
        #expect(!scanner.isProcessing)
    }

    @Test func scannerSimulateServiceFoundCallsDelegate() {
        let scanner = MockBonjourServiceScanner()
        let delegate = TestScannerDelegate()
        scanner.delegate = delegate
        let service = makeService(name: "Found")
        scanner.simulateServiceFound(service)
        #expect(delegate.addedServices.count == 1)
        #expect(delegate.addedServices.first?.service.name == "Found")
    }

    @Test func scannerSimulateErrorCallsDelegate() {
        let scanner = MockBonjourServiceScanner()
        let delegate = TestScannerDelegate()
        scanner.delegate = delegate
        scanner.simulateError("Network failure")
        #expect(delegate.errors.count == 1)
        #expect(delegate.errors.first == "Network failure")
    }

    // MARK: - MockBonjourPublishManager Tests

    @Test func publishManagerPublishIncrementsCount() async throws {
        let manager = MockBonjourPublishManager()
        let service = makeService()
        _ = try await manager.publish(service: service)
        #expect(manager.publishCallCount == 1)
    }

    @Test func publishManagerPublishAddsToSet() async throws {
        let manager = MockBonjourPublishManager()
        let service = makeService()
        let published = try await manager.publish(service: service)
        #expect(manager.publishedServices.contains(published))
    }

    @Test func publishManagerPublishTracksName() async throws {
        let manager = MockBonjourPublishManager()
        _ = try await manager.publish(
            name: "MyService",
            type: "http",
            port: 8080,
            domain: "local.",
            transportLayer: .tcp,
            detail: ""
        )
        #expect(manager.lastPublishedServiceName == "MyService")
    }

    @Test func publishManagerPublishThrowsWhenConfigured() async {
        let manager = MockBonjourPublishManager()
        manager.shouldSucceed = false
        manager.errorToThrow = MockError.publishFailed
        let service = makeService()
        do {
            _ = try await manager.publish(service: service)
            Issue.record("Expected publish to throw")
        } catch {
            #expect(error is MockError)
        }
    }

    @Test func publishManagerUnPublishRemovesFromSet() async throws {
        let manager = MockBonjourPublishManager()
        let service = makeService()
        let published = try await manager.publish(service: service)
        #expect(!manager.publishedServices.isEmpty)
        await manager.unPublish(service: published)
        #expect(manager.publishedServices.isEmpty)
    }

    @Test func publishManagerUnPublishAllClearsSet() async throws {
        let manager = MockBonjourPublishManager()
        _ = try await manager.publish(service: makeService(name: "A"))
        _ = try await manager.publish(service: makeService(name: "B", type: "ssh"))
        #expect(manager.publishedServices.count == 2)
        await manager.unPublishAllServices()
        #expect(manager.publishedServices.isEmpty)
    }

    @Test func publishManagerResetClearsEverything() async throws {
        let manager = MockBonjourPublishManager()
        _ = try await manager.publish(
            name: "Svc",
            type: "http",
            port: 80,
            domain: "local.",
            transportLayer: .tcp,
            detail: ""
        )
        manager.reset()
        #expect(manager.publishCallCount == 0)
        #expect(manager.unPublishCallCount == 0)
        #expect(manager.lastPublishedServiceName == nil)
        #expect(manager.publishedServices.isEmpty)
        #expect(manager.shouldSucceed)
        #expect(manager.errorToThrow == nil)
    }
}
