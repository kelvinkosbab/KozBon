//
//  MockDependencies.swift
//  KozBon
//
//  Created by Dependency Injection Implementation
//  Copyright © 2024 Kozinga. All rights reserved.
//

import Foundation

// MARK: - Mock Bonjour Service Scanner

/// Mock implementation of BonjourServiceScannerProtocol for testing
@MainActor
final class MockBonjourServiceScanner: BonjourServiceScannerProtocol {

    weak var delegate: BonjourServiceScannerDelegate?

    var isProcessing: Bool = false

    // Test tracking properties
    var startScanCallCount = 0
    var stopScanCallCount = 0

    func startScan() {
        startScanCallCount += 1
        isProcessing = true
    }

    func stopScan() {
        stopScanCallCount += 1
        isProcessing = false
    }

    // Test helper methods
    func simulateServiceFound(_ service: BonjourService) {
        delegate?.didAdd(service: service)
    }

    func simulateServiceLost(_ service: BonjourService) {
        delegate?.didRemove(service: service)
    }

    func simulateReset() {
        delegate?.didReset()
    }

    func reset() {
        startScanCallCount = 0
        stopScanCallCount = 0
        isProcessing = false
    }
}

// MARK: - Mock Bonjour Publish Manager

/// Mock implementation of BonjourPublishManagerProtocol for testing
@MainActor
final class MockBonjourPublishManager: BonjourPublishManagerProtocol {

    var publishedServices: Set<BonjourService> = []

    // Test tracking properties
    var publishCallCount = 0
    var unPublishCallCount = 0
    var lastPublishedServiceName: String?

    // Simulate success or failure
    var shouldSucceed = true
    var errorToThrow: Error?

    func publish(
        name: String,
        type: String,
        port: Int,
        domain: String,
        transportLayer: TransportLayer,
        detail: String
    ) async throws -> BonjourService {
        publishCallCount += 1
        lastPublishedServiceName = name

        if !shouldSucceed, let error = errorToThrow {
            throw error
        }

        let serviceType = BonjourServiceType(
            name: name,
            type: type,
            transportLayer: transportLayer,
            detail: detail
        )
        let netService = NetService(domain: domain, type: serviceType.fullType, name: name, port: Int32(port))
        let service = BonjourService(service: netService, serviceType: serviceType)

        publishedServices.insert(service)
        return service
    }

    func publish(service: BonjourService) async throws -> BonjourService {
        publishCallCount += 1

        if !shouldSucceed, let error = errorToThrow {
            throw error
        }

        publishedServices.insert(service)
        return service
    }

    func unPublish(service: BonjourService) async {
        unPublishCallCount += 1
        publishedServices.remove(service)
    }

    func unPublishAllServices() async {
        publishedServices.removeAll()
    }

    // Test helper
    func reset() {
        publishCallCount = 0
        unPublishCallCount = 0
        lastPublishedServiceName = nil
        publishedServices.removeAll()
        shouldSucceed = true
        errorToThrow = nil
    }
}

// MARK: - Test Error

enum MockError: Error {
    case publishFailed
    case networkError
}

// MARK: - Test Dependency Container Factory

extension DependencyContainer {

    /// Creates a dependency container with mock services for testing
    static func mock(
        scanner: MockBonjourServiceScanner = MockBonjourServiceScanner(),
        publishManager: MockBonjourPublishManager = MockBonjourPublishManager()
    ) -> DependencyContainer {
        return DependencyContainer(
            bonjourServiceScanner: scanner,
            bonjourPublishManager: publishManager
        )
    }
}
