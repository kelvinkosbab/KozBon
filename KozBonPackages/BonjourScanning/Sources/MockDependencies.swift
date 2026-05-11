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

/// Mock implementation of ``BonjourServiceScannerProtocol`` for use in tests and SwiftUI previews.
///
/// Tracks call counts for ``startScan(publishedServices:)`` and ``stopScan()``, and provides
/// `simulate*` helpers to drive delegate callbacks without a real network.
@MainActor
public final class MockBonjourServiceScanner: BonjourServiceScannerProtocol {

    /// The delegate that receives simulated discovery events.
    public weak var delegate: BonjourServiceScannerDelegate?

    /// Whether the mock scanner is currently "processing".
    public var isProcessing: Bool = false

    // Test tracking properties

    /// The number of times ``startScan(publishedServices:)`` has been called.
    public var startScanCallCount = 0

    /// The number of times ``stopScan()`` has been called.
    public var stopScanCallCount = 0

    public init() {}

    /// Records the call and sets ``isProcessing`` to `true`.
    public func startScan(publishedServices: Set<BonjourService> = []) {
        startScanCallCount += 1
        isProcessing = true
    }

    /// Records the call and sets ``isProcessing`` to `false`.
    public func stopScan() {
        stopScanCallCount += 1
        isProcessing = false
    }

    // Test helper methods

    /// Simulates discovering a service by calling the delegate's ``didAdd(service:)`` method.
    public func simulateServiceFound(_ service: BonjourService) {
        delegate?.didAdd(service: service)
    }

    /// Simulates a service disappearing by calling the delegate's ``didRemove(service:)`` method.
    public func simulateServiceLost(_ service: BonjourService) {
        delegate?.didRemove(service: service)
    }

    /// Simulates a scanner reset by calling the delegate's ``didReset()`` method.
    public func simulateReset() {
        delegate?.didReset()
    }

    /// Simulates a scan error by calling the delegate's ``didFailWithError(description:)`` method.
    public func simulateError(_ description: String) {
        delegate?.didFailWithError(description: description)
    }

    /// Resets all tracking state (call counts and ``isProcessing``) to initial values.
    public func reset() {
        startScanCallCount = 0
        stopScanCallCount = 0
        isProcessing = false
    }
}

// MARK: - Mock Bonjour Publish Manager

/// Mock implementation of ``BonjourPublishManagerProtocol`` for use in tests and SwiftUI previews.
///
/// Tracks publish/unpublish call counts and supports configurable success or failure
/// via ``shouldSucceed`` and ``errorToThrow``.
@MainActor
public final class MockBonjourPublishManager: BonjourPublishManagerProtocol {

    /// The set of services that have been "published" by this mock.
    public var publishedServices: Set<BonjourService> = []

    // Test tracking properties

    /// The number of times a publish method has been called.
    public var publishCallCount = 0

    /// The number of times ``unPublish(service:)`` has been called.
    public var unPublishCallCount = 0

    /// The name of the most recently published service, if any.
    public var lastPublishedServiceName: String?

    // Simulate success or failure

    /// When `false`, publish methods throw ``errorToThrow`` (defaults to `true`).
    public var shouldSucceed = true

    /// The error to throw when ``shouldSucceed`` is `false`.
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

    /// Resets all tracking state and configuration to initial values.
    public func reset() {
        publishCallCount = 0
        unPublishCallCount = 0
        lastPublishedServiceName = nil
        publishedServices.removeAll()
        shouldSucceed = true
        errorToThrow = nil
    }
}

// MARK: - Mock Network Connectivity Monitor

/// Mock implementation of ``NetworkConnectivityMonitorProtocol`` for
/// tests and SwiftUI previews. Connectivity state is settable so a
/// test can simulate joining / leaving Wi-Fi without involving
/// `NWPathMonitor` or the OS network stack.
///
/// Setting ``isOnLocalNetwork`` synchronously fires
/// ``NetworkConnectivityMonitorDelegate/networkConnectivityDidChange(isOnLocalNetwork:)``
/// on the registered delegate when the value differs from the
/// previous one — same external contract as the production
/// monitor, just without the async path-monitor hop.
@MainActor
public final class MockNetworkConnectivityMonitor: NetworkConnectivityMonitorProtocol {

    public weak var delegate: NetworkConnectivityMonitorDelegate?

    public var isOnLocalNetwork: Bool {
        get { _isOnLocalNetwork }
        set {
            guard newValue != _isOnLocalNetwork else { return }
            _isOnLocalNetwork = newValue
            delegate?.networkConnectivityDidChange(isOnLocalNetwork: newValue)
        }
    }
    private var _isOnLocalNetwork: Bool

    // Test tracking properties

    /// The number of times ``start()`` has been called.
    public var startCallCount = 0

    /// The number of times ``stop()`` has been called.
    public var stopCallCount = 0

    /// - Parameter initialIsOnLocalNetwork: Seed value for
    ///   ``isOnLocalNetwork`` before any explicit mutation. Defaults
    ///   to `true` to match the production monitor's optimistic
    ///   initial state.
    public init(initialIsOnLocalNetwork: Bool = true) {
        self._isOnLocalNetwork = initialIsOnLocalNetwork
    }

    public func start() {
        startCallCount += 1
    }

    public func stop() {
        stopCallCount += 1
    }

    /// Resets call counts and connectivity state to defaults.
    public func reset() {
        startCallCount = 0
        stopCallCount = 0
        _isOnLocalNetwork = true
    }
}

// MARK: - Test Error

/// Simple error type for simulating failures in mock dependencies during tests.
public enum MockError: Error {
    /// Simulates a publish operation failure.
    case publishFailed
    /// Simulates a network-level error.
    case networkError
}
