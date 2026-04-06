//
//  MockDependencies.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourCore
import BonjourModels

// MARK: - Mock Bonjour Service Scanner

/// Mock implementation of BonjourServiceScannerProtocol for testing
@MainActor
public final class MockBonjourServiceScanner: BonjourServiceScannerProtocol {

    public weak var delegate: BonjourServiceScannerDelegate?

    public var isProcessing: Bool = false

    // Test tracking properties
    public var startScanCallCount = 0
    public var stopScanCallCount = 0

    public init() {}

    public func startScan(publishedServices: Set<BonjourService> = []) {
        startScanCallCount += 1
        isProcessing = true
    }

    public func stopScan() {
        stopScanCallCount += 1
        isProcessing = false
    }

    // Test helper methods
    public func simulateServiceFound(_ service: BonjourService) {
        delegate?.didAdd(service: service)
    }

    public func simulateServiceLost(_ service: BonjourService) {
        delegate?.didRemove(service: service)
    }

    public func simulateReset() {
        delegate?.didReset()
    }

    public func simulateError(_ description: String) {
        delegate?.didFailWithError(description: description)
    }

    public func reset() {
        startScanCallCount = 0
        stopScanCallCount = 0
        isProcessing = false
    }
}

// MARK: - Mock Bonjour Publish Manager

/// Mock implementation of BonjourPublishManagerProtocol for testing
@MainActor
public final class MockBonjourPublishManager: BonjourPublishManagerProtocol {

    public var publishedServices: Set<BonjourService> = []

    // Test tracking properties
    public var publishCallCount = 0
    public var unPublishCallCount = 0
    public var lastPublishedServiceName: String?

    // Simulate success or failure
    public var shouldSucceed = true
    public var errorToThrow: Error?

    public init() {}

    public func publish(
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

    public func publish(service: BonjourService) async throws -> BonjourService {
        publishCallCount += 1

        if !shouldSucceed, let error = errorToThrow {
            throw error
        }

        publishedServices.insert(service)
        return service
    }

    public func unPublish(service: BonjourService) async {
        unPublishCallCount += 1
        publishedServices.remove(service)
    }

    public func unPublishAllServices() async {
        publishedServices.removeAll()
    }

    // Test helper
    public func reset() {
        publishCallCount = 0
        unPublishCallCount = 0
        lastPublishedServiceName = nil
        publishedServices.removeAll()
        shouldSucceed = true
        errorToThrow = nil
    }
}

// MARK: - Test Error

public enum MockError: Error {
    case publishFailed
    case networkError
}
