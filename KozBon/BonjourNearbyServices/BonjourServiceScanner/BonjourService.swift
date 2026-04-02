//
//  BonjourService.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Core

// MARK: - MyNetServiceDelegate

/// Delegate protocol for receiving Bonjour service address resolution updates.
@MainActor
protocol MyNetServiceDelegate: AnyObject, Sendable {
    /// Called when a service finishes resolving its addresses (whether successful or not).
    func serviceDidResolveAddress(_ service: BonjourService)
}

// MARK: - BonjourService

/// Wraps a `NetService` with additional state tracking for address resolution,
/// publishing, and TXT record monitoring.
@MainActor
final class BonjourService: NSObject, @preconcurrency NetServiceDelegate {

    // MARK: - Properties

    /// The underlying Foundation `NetService` instance.
    let service: NetService

    /// The service type metadata (name, type string, transport layer).
    let serviceType: BonjourServiceType

    /// A stable identifier derived from the `NetService` hash at initialization time.
    nonisolated let serviceIdentifier: Int

    /// Resolved IP addresses for this service. Empty until `resolve()` or `resolveAddresses()` completes.
    private(set) var addresses: [InternetAddress] = []

    /// TXT record key-value pairs published by this service.
    private(set) var dataRecords: [TxtDataRecord] = []

    /// Delegate notified when address resolution completes.
    weak var delegate: MyNetServiceDelegate?

    private let logger: Loggable = Logger(category: "BonjourService")

    init(
        service: NetService,
        serviceType: BonjourServiceType
    ) {
        self.service = service
        self.serviceType = serviceType
        self.serviceIdentifier = service.hashValue
        super.init()
        self.service.delegate = self
    }

    /// The human-readable hostname derived from the service's advertised host, with domain and punctuation stripped.
    var hostName: String {
        if let hostName = self.service.hostName {
            return hostName
                .replacingOccurrences(of: self.service.domain, with: "")
                .replacingOccurrences(of: ".", with: "")
                .replacingOccurrences(of: "-", with: " ")
        }
        return "NA"
    }

    /// Whether the underlying `NetService` has resolved at least one address.
    var hasResolvedAddresses: Bool {
        self.service.addresses != nil
    }

    // MARK: - Stopping Resolution / Publishing

    private var isStopping: Bool = false
    private var didStop: (() -> Void)?

    /// Stops all active resolution and publishing operations, then invokes the callback when stopped.
    func stop(didStop: (() -> Void)? = nil) {
        logger.debug("Stopping service", censored: "\(self)")
        self.isStopping = true
        self.isResolving = false
        self.isPublishing = false
        self.didStop = didStop
        self.resolveAddressContinuation = nil
        self.publishContinuation = nil
        self.service.stop()
    }

    // MARK: - NetServiceDelegate - Stopping

    func netServiceDidStop(_ sender: NetService) {
        logger.debug("Service did stop", censored: "\(sender)")
        self.isStopping = false
        self.didStop?()
        self.didStop = nil
    }

    // MARK: - Resolving Address

    /// Whether a resolve operation is currently in progress.
    private(set) var isResolving: Bool = false
    private var resolveAddressContinuation: CheckedContinuation<Void, Never>?

    /// Begins resolving addresses and starts TXT record monitoring. Returns immediately (fire-and-forget).
    func resolve() {
        self.isResolving = true
        self.service.resolve(withTimeout: Constants.Network.resolveTimeout)
        self.startMonitoring()
    }

    /// Resolves the service's addresses asynchronously. Suspends until resolution completes or fails.
    func resolveAddresses() async {
        await withCheckedContinuation { continuation in
            self.resolveAddressContinuation = continuation
            self.isResolving = true
            self.service.resolve(withTimeout: Constants.Network.resolveTimeout)
            self.startMonitoring()
        }
    }

    // MARK: - NetServiceDelegate - Resolving Address

    func netServiceDidResolveAddress(_ sender: NetService) {
        logger.debug("Service did resolve address", censored: "\(sender) with hostname \(self.hostName)")
        self.addresses = sender.parseInternetAddresses()
        delegate?.serviceDidResolveAddress(self)
        isResolving = false
        resolveAddressContinuation?.resume()
        resolveAddressContinuation = nil
    }

    func netService(_ sender: NetService, didNotResolve errorDict: [String: NSNumber]) {
        logger.debug("Service did not resolve address", censored: "\(sender) with errorDict \(errorDict)")
        self.delegate?.serviceDidResolveAddress(self)
        self.isResolving = false
        self.resolveAddressContinuation?.resume()
        self.resolveAddressContinuation = nil
    }

    // MARK: - Publishing Service

    /// Whether a publish operation is currently in progress.
    private(set) var isPublishing: Bool = false
    private var publishContinuation: CheckedContinuation<Void, any Error>?

    /// Publishes this service on the network. Throws ``PublishError/didNotPublish`` on failure.
    func publishService() async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.publishContinuation = continuation
            self.isPublishing = true
            self.service.publish()
        }
    }

    /// Stops and un-publishes this service from the network.
    func unPublish() async {
        await withCheckedContinuation { continuation in
            self.stop {
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(Constants.Network.publishDelayMilliseconds))
                    continuation.resume()
                }
            }
        }
    }

    // MARK: - NetServiceDelegate - Publishing

    func netServiceWillPublish(_ sender: NetService) {
        logger.debug("Service will publish", censored: "\(sender)")

        // For some reason the `didPublish` callback isn't being called. This is a temp hack
        // to allow for the continuation to resume after a short delay
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(Constants.Network.publishDelayMilliseconds))
            self?.netServiceDidPublish(sender)
        }
    }

    func netServiceDidPublish(_ sender: NetService) {
        logger.debug("Service did publish", censored: "\(sender)")
        self.isPublishing = false
        self.publishContinuation?.resume()
        self.publishContinuation = nil
    }

    func netService(_ sender: NetService, didNotPublish errorDict: [String: NSNumber]) {
        logger.error("Service did not publish", censored: "\(sender) with errorDict \(errorDict)")
        self.isPublishing = false
        self.publishContinuation?.resume(throwing: PublishError.didNotPublish)
        self.publishContinuation = nil
    }

    // MARK: - NetServiceDelegate - TXT Records

    func startMonitoring() {
        self.service.startMonitoring()
    }

    func stopMonitoring() {
        self.service.stopMonitoring()
    }

    func netService(_ sender: NetService, didUpdateTXTRecord data: Data) {
        logger.debug("Did update TXT record", censored: "\(data)")

        var records: [TxtDataRecord] = []
        for (key, value) in NetService.dictionary(fromTXTRecord: data) {
            if let stringValue = String(data: value, encoding: .utf8) {
                records.append(TxtDataRecord(key: key, value: stringValue.isEmpty ? "NA" : stringValue))
            }
        }

        self.dataRecords = records.sorted { r1, r2 -> Bool in
            r1 < r2
        }
    }
}

// MARK: - PublishError

enum PublishError: Swift.Error {
    case didNotPublish
}

// MARK: - Identifiable

extension BonjourService: Identifiable {
    nonisolated var id: Int {
        serviceIdentifier
    }
}
