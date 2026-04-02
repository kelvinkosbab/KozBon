//
//  BonjourService.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Core

// MARK: - MyNetServiceDelegate

@MainActor
protocol MyNetServiceDelegate: AnyObject, Sendable {
    func serviceDidResolveAddress(_ service: BonjourService)
}

// MARK: - BonjourService

@MainActor
final class BonjourService: NSObject, @preconcurrency NetServiceDelegate {

    // MARK: - Init

    let service: NetService
    let serviceType: BonjourServiceType
    nonisolated let serviceIdentifier: Int
    private(set) var addresses: [InternetAddress] = []
    private(set) var dataRecords: [TxtDataRecord] = []
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

    var hostName: String {
        if let hostName = self.service.hostName {
            return hostName
                .replacingOccurrences(of: self.service.domain, with: "")
                .replacingOccurrences(of: ".", with: "")
                .replacingOccurrences(of: "-", with: " ")
        }
        return "NA"
    }

    var hasResolvedAddresses: Bool {
        self.service.addresses != nil
    }

    // MARK: - Stopping Resolution / Publishing

    private var isStopping: Bool = false
    private var didStop: (() -> Void)?

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

    private(set) var isResolving: Bool = false
    private var resolveAddressContinuation: CheckedContinuation<Void, Never>?

    func resolve() {
        self.isResolving = true
        self.service.resolve(withTimeout: 10.0)
        self.startMonitoring()
    }

    func resolveAddresses() async {
        await withCheckedContinuation { continuation in
            self.resolveAddressContinuation = continuation
            self.isResolving = true
            self.service.resolve(withTimeout: 10.0)
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

    private(set) var isPublishing: Bool = false
    private var publishContinuation: CheckedContinuation<Void, any Error>?

    func publishService() async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.publishContinuation = continuation
            self.isPublishing = true
            self.service.publish()
        }
    }

    func unPublish() async {
        await withCheckedContinuation { continuation in
            self.stop {
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(500))
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
            try? await Task.sleep(for: .milliseconds(500))
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
