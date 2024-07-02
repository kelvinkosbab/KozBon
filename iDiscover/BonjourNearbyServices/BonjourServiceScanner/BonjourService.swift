//
//  BonjourService.swift
//  Test
//
//  Created by Kelvin Kosbab on 12/25/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation
import Core

// MARK: - MyNetServiceDelegate

protocol MyNetServiceDelegate: AnyObject {
    func serviceDidResolveAddress(_ service: BonjourService)
}

// MARK: - BonjourService

class BonjourService: NSObject, NetServiceDelegate {

    // MARK: - Init

    let service: NetService
    let serviceType: BonjourServiceType
    private(set) var addresses: [InternetAddress] = []
    private(set) var dataRecords: [TxtDataRecord] = []
    weak var delegate: MyNetServiceDelegate?

    private let logger: Loggable = Logger(category: "BonjourService")

    init(service: NetService, serviceType: BonjourServiceType) {
        self.service = service
        self.serviceType = serviceType
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
        if let _ = self.service.addresses {
            return true
        }
        return false
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
        self.completedAddressResolution = nil
        self.publishServiceSuccess = nil
        self.publishServiceFailure = nil
        self.service.stop()
    }

    // MARK: - NetServiceDelegate - Stopping

    func netServiceDidStop(_ sender: NetService) {
        logger.debug("Service did stop", censored: "\(sender)")
        NotificationCenter.default.post(name: .netServiceDidStop, object: self)
        self.isStopping = false
        self.didStop?()
        self.didStop = nil
    }

    // MARK: - Resolving Address

    private(set) var isResolving: Bool = false
    private var completedAddressResolution: (() -> Void)?

    func resolve(completedAddressResolution: (() -> Void)? = nil) {
        self.isResolving = true
        self.completedAddressResolution = completedAddressResolution
        self.service.resolve(withTimeout: 10.0)
        self.startMonitoring()
    }

    // MARK: - NetServiceDelegate - Resolving Address

    func netServiceDidResolveAddress(_ sender: NetService) {
        logger.debug("Service did resolve address", censored: "\(sender) with hostname \(self.hostName)")
        self.addresses = sender.parseInternetAddresses()
        NotificationCenter.default.post(name: .netServiceResolveAddressComplete, object: self)
        delegate?.serviceDidResolveAddress(self)
        completedAddressResolution?()
        completedAddressResolution = nil
        isResolving = false
    }

    func netService(_ sender: NetService, didNotResolve errorDict: [String: NSNumber]) {
        logger.debug("Service did not resolve address", censored: "\(sender) with errorDict \(errorDict)")
        NotificationCenter.default.post(name: .netServiceResolveAddressComplete, object: self)
        self.delegate?.serviceDidResolveAddress(self)
        self.completedAddressResolution?()
        self.completedAddressResolution = nil
        self.isResolving = false
    }

    // MARK: - Publishing Service

    private(set) var isPublishing: Bool = false
    private var publishServiceSuccess: (() -> Void)?
    private var publishServiceFailure: ((_ error: Error) -> Void)?

    func publish(
        publishServiceSuccess: @escaping () -> Void,
        publishServiceFailure: @escaping (_ error: Error) -> Void
    ) {
        self.isPublishing = true
        self.publishServiceSuccess = publishServiceSuccess
        self.publishServiceFailure = publishServiceFailure
        self.service.publish()
    }

    func unPublish(completion: (() -> Void)? = nil) {
        self.stop {
            // Add delay for some reason? (not sure what 2014 me added this)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                NotificationCenter.default.post(name: .netServiceDidUnPublish, object: self)
                completion?()
            }
        }
    }

    // MARK: - Publishing Service

    func netServiceWillPublish(_ sender: NetService) {
        logger.debug("Service will publish", censored: "\(sender)")
        
        // For some reason the `didPublish` callback isn't beeing called. This is a temp hack
        // to allow for the completion handlers to return after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            self.netServiceDidPublish(sender)
        }
    }

    func netServiceDidPublish(_ sender: NetService) {
        logger.debug("Service did publish", censored: "\(sender)")
        self.publishServiceSuccess?()
        self.publishServiceSuccess = nil
        self.publishServiceFailure = nil
        self.isPublishing = false
        NotificationCenter.default.post(name: .netServiceDidPublish, object: self)
    }

    func netService(_ sender: NetService, didNotPublish errorDict: [String: NSNumber]) {
        logger.error("Service did not publish", censored: "\(sender) with errorDict \(errorDict)")
        self.publishServiceFailure?(PublishError.didNotPublish)
        self.publishServiceSuccess = nil
        self.publishServiceFailure = nil
        self.isPublishing = false
        NotificationCenter.default.post(name: .netServiceDidNotPublish, object: self)
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
    var id: Int {
        service.hashValue
    }
}
