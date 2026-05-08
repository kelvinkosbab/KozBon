//
//  BonjourService.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourCore

// MARK: - MyNetServiceDelegate

/// Delegate protocol for receiving Bonjour service address resolution updates.
@MainActor
public protocol MyNetServiceDelegate: AnyObject, Sendable {
    /// Called when a service finishes resolving its addresses (whether successful or not).
    func serviceDidResolveAddress(_ service: BonjourService)
}

// MARK: - BonjourService

/// Wraps a `NetService` with additional state tracking for address resolution,
/// publishing, and TXT record monitoring.
@MainActor
public final class BonjourService: NSObject, @preconcurrency NetServiceDelegate {

    // MARK: - Properties

    /// The underlying Foundation `NetService` instance.
    public let service: NetService

    /// The service type metadata (name, type string, transport layer).
    public let serviceType: BonjourServiceType

    /// DNS-SD logical identity for this service: `name|type|domain`,
    /// captured once at init time. Used as the basis for ``id``,
    /// ``hash``, and ``isEqual(_:)``.
    ///
    /// The DNS-SD spec guarantees that the `(name, type, domain)`
    /// tuple uniquely identifies a service on a network — two
    /// physical NetService instances with the same tuple represent
    /// the SAME service, even if they were discovered through
    /// different network interfaces, IP families, or scanner
    /// restarts. The previous identity (`NetService.hashValue`)
    /// was pointer-based, so it produced a fresh integer per
    /// instance even when the underlying logical service was
    /// identical — the chat surface and Discover tab saw the same
    /// device duplicated several times whenever Bonjour emitted
    /// per-interface or post-restart re-discovery callbacks.
    ///
    /// Cached as a `nonisolated let` so `hash` / `isEqual(_:)` /
    /// `id` (all required to be nonisolated by their respective
    /// protocols) can read it without crossing the
    /// `@MainActor` boundary that protects the underlying
    /// `NetService` delegate state.
    public nonisolated let logicalIdentity: String

    /// Resolved IP addresses for this service. Empty until `resolve()` or `resolveAddresses()` completes.
    public private(set) var addresses: [InternetAddress] = []

    /// TXT record key-value pairs published by this service.
    public private(set) var dataRecords: [TxtDataRecord] = []

    /// Delegate notified when address resolution completes.
    public weak var delegate: MyNetServiceDelegate?

    private let logger: Loggable = Logger(category: "BonjourService")

    /// Creates a new Bonjour service wrapper.
    ///
    /// Sets up the delegate chain so this object receives `NetService` callbacks for
    /// resolution, publishing, and TXT record updates.
    ///
    /// - Parameters:
    ///   - service: The underlying `NetService` instance to wrap.
    ///   - serviceType: The service type metadata describing this service.
    public init(
        service: NetService,
        serviceType: BonjourServiceType
    ) {
        self.service = service
        self.serviceType = serviceType
        // Compose the DNS-SD identity tuple at construction time.
        // `NetService.name` / `.type` / `.domain` are populated
        // before the browser hands the instance to us — they're
        // discovery-time properties, not resolve-time properties,
        // so reading them here is safe even for an unresolved
        // service. The pipe separator is a character that can't
        // legally appear in any of the three components, so the
        // composition is unambiguous.
        self.logicalIdentity = "\(service.name)|\(service.type)|\(service.domain)"
        super.init()
        self.service.delegate = self
    }

    // MARK: - NSObject Identity Overrides

    /// Hash by DNS-SD logical identity rather than NSObject's
    /// pointer-based default. Required for `Set<BonjourService>`
    /// (used by both `BonjourServiceScanner` and
    /// `BonjourServiceTypeScanner`) to dedup logical duplicates
    /// emitted by per-interface or post-restart re-discovery
    /// callbacks.
    public override nonisolated var hash: Int {
        logicalIdentity.hashValue
    }

    /// Equality by DNS-SD logical identity. Two `BonjourService`
    /// wrappers for the same `(name, type, domain)` tuple compare
    /// equal regardless of underlying `NetService` instance, so
    /// dedup paths see them as one service.
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? BonjourService else { return false }
        return self.logicalIdentity == other.logicalIdentity
    }

    /// The human-readable hostname derived from the service's advertised host, with domain and punctuation stripped.
    public var hostName: String {
        if let hostName = self.service.hostName {
            return hostName
                .replacingOccurrences(of: self.service.domain, with: "")
                .replacingOccurrences(of: ".", with: "")
                .replacingOccurrences(of: "-", with: " ")
        }
        return "NA"
    }

    /// Whether the underlying `NetService` has resolved at least one address.
    public var hasResolvedAddresses: Bool {
        self.service.addresses != nil
    }

    // MARK: - Stopping Resolution / Publishing

    private var isStopping: Bool = false
    private var didStop: (() -> Void)?

    /// Stops all active resolution and publishing operations, then invokes the callback when stopped.
    public func stop(didStop: (() -> Void)? = nil) {
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

    public func netServiceDidStop(_ sender: NetService) {
        logger.debug("Service did stop", censored: "\(sender)")
        self.isStopping = false
        self.didStop?()
        self.didStop = nil
    }

    // MARK: - Resolving Address

    /// Whether a resolve operation is currently in progress.
    public private(set) var isResolving: Bool = false
    private var resolveAddressContinuation: CheckedContinuation<Void, Never>?

    /// Begins resolving addresses and starts TXT record monitoring. Returns immediately (fire-and-forget).
    public func resolve() {
        self.isResolving = true
        self.service.resolve(withTimeout: Constants.Network.resolveTimeout)
        self.startMonitoring()
    }

    /// Resolves the service's addresses asynchronously. Suspends until resolution completes or fails.
    public func resolveAddresses() async {
        await withCheckedContinuation { continuation in
            self.resolveAddressContinuation = continuation
            self.isResolving = true
            self.service.resolve(withTimeout: Constants.Network.resolveTimeout)
            self.startMonitoring()
        }
    }

    // MARK: - NetServiceDelegate - Resolving Address

    public func netServiceDidResolveAddress(_ sender: NetService) {
        logger.debug("Service did resolve address", censored: "\(sender) with hostname \(self.hostName)")
        self.addresses = sender.parseInternetAddresses()
        delegate?.serviceDidResolveAddress(self)
        isResolving = false
        resolveAddressContinuation?.resume()
        resolveAddressContinuation = nil
    }

    public func netService(_ sender: NetService, didNotResolve errorDict: [String: NSNumber]) {
        logger.debug("Service did not resolve address", censored: "\(sender) with errorDict \(errorDict)")
        self.delegate?.serviceDidResolveAddress(self)
        self.isResolving = false
        self.resolveAddressContinuation?.resume()
        self.resolveAddressContinuation = nil
    }

    // MARK: - Publishing Service

    /// Whether a publish operation is currently in progress.
    public private(set) var isPublishing: Bool = false
    private var publishContinuation: CheckedContinuation<Void, any Error>?

    /// Publishes this service on the network. Throws ``PublishError/didNotPublish`` on failure.
    public func publishService() async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.publishContinuation = continuation
            self.isPublishing = true
            self.service.publish()
        }
    }

    /// Stops and un-publishes this service from the network.
    public func unPublish() async {
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

    public func netServiceWillPublish(_ sender: NetService) {
        logger.debug("Service will publish", censored: "\(sender)")

        // For some reason the `didPublish` callback isn't being called. This is a temp hack
        // to allow for the continuation to resume after a short delay
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(Constants.Network.publishDelayMilliseconds))
            self?.netServiceDidPublish(sender)
        }
    }

    public func netServiceDidPublish(_ sender: NetService) {
        logger.debug("Service did publish", censored: "\(sender)")
        self.isPublishing = false
        self.publishContinuation?.resume()
        self.publishContinuation = nil
    }

    public func netService(_ sender: NetService, didNotPublish errorDict: [String: NSNumber]) {
        logger.error("Service did not publish", censored: "\(sender) with errorDict \(errorDict)")
        self.isPublishing = false
        self.publishContinuation?.resume(throwing: PublishError.didNotPublish)
        self.publishContinuation = nil
    }

    // MARK: - NetServiceDelegate - TXT Records

    /// Begins monitoring the service for TXT record changes.
    public func startMonitoring() {
        self.service.startMonitoring()
    }

    /// Stops monitoring the service for TXT record changes.
    public func stopMonitoring() {
        self.service.stopMonitoring()
    }

    /// Updates the TXT records on the live published service and refreshes the local `dataRecords`.
    ///
    /// Calls `NetService.setTXTRecord()` to apply changes immediately on the network.
    /// - Parameter records: The complete set of TXT records to publish.
    public func updateTXTRecords(_ records: [TxtDataRecord]) {
        var txtRecords: [String: Data] = [:]
        for record in records {
            if let data = record.value.data(using: .utf8) {
                txtRecords[record.key] = data
            }
        }
        let data = NetService.data(fromTXTRecord: txtRecords)
        _ = service.setTXTRecord(data)
        self.dataRecords = records.sorted { $0 < $1 }
    }

    public func netService(_ sender: NetService, didUpdateTXTRecord data: Data) {
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

/// Errors that can occur when publishing a Bonjour service on the network.
public enum PublishError: Swift.Error {
    /// The service failed to publish. The underlying `NetService` reported a publish error.
    case didNotPublish
}

// MARK: - Identifiable

extension BonjourService: Identifiable {

    /// SwiftUI / dedup identifier — the DNS-SD logical identity
    /// (`name|type|domain`). Stable for the lifetime of any
    /// `BonjourService` wrapping a NetService that represents the
    /// same logical service, so `ForEach` and `firstIndex(where:)`
    /// dedup paths collapse per-interface and post-restart
    /// duplicates correctly.
    public nonisolated var id: String {
        logicalIdentity
    }
}
