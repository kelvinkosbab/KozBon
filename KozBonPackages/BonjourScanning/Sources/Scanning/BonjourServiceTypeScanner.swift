//
//  BonjourServiceTypeScanner.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourCore
import BonjourModels

// MARK: - BonjourServiceBrowser

/// Scans for services of a given service type (``BonjourServiceType``).
@MainActor
public final class BonjourServiceTypeScanner: NSObject, @preconcurrency NetServiceBrowserDelegate {

    // MARK: - Properties

    private let serviceBrowser: NetServiceBrowser
    private let serviceType: BonjourServiceType
    private let domain: String
    private let logger: Loggable
    /// The set of services currently discovered for this service type.
    public private(set) var activeServices = Set<BonjourService>()

    /// The current scanning state (searching or stopped).
    public private(set) var state: BonjourServiceBrowserState = .stopped

    /// The delegate that receives discovery events for this service type.
    public weak var delegate: BonjourServiceScannerDelegate?

    // MARK: - Init

    /// Creates a scanner for the given Bonjour service type and domain.
    ///
    /// - Parameters:
    ///   - serviceType: The Bonjour service type to scan for.
    ///   - domain: The domain to search in. Pass `""` for the default local domain.
    public init(
        serviceType: BonjourServiceType,
        domain: String
    ) {
        self.serviceBrowser = NetServiceBrowser()
        self.serviceType = serviceType
        self.domain = domain
        self.logger = Logger(category: "Scanner")

        super.init()

        self.serviceBrowser.delegate = self
    }

    // MARK: - Start / Stop

    /// Begins scanning for services of this scanner's service type.
    ///
    /// If a scan is already in progress, this method does nothing.
    public func startScan() {

        guard self.state != .searching else {
            self.logger.info("Already searching. Do nothing.")
            return
        }

        self.serviceBrowser.searchForServices(
            ofType: self.serviceType.fullType,
            inDomain: self.domain
        )
    }

    /// Stops the current scan.
    public func stopScan() {
        self.serviceBrowser.stop()
    }

    /// Stops scanning and clears all discovered services, notifying the delegate of the reset.
    public func reset() {
        self.stopScan()
        self.activeServices.removeAll()
        self.delegate?.didReset()
    }

    // MARK: - NetServiceBrowserDelegate

    public func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
        self.state = .searching
    }

    public func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        self.state = .stopped
    }

    public func netServiceBrowser(
        _ browser: NetServiceBrowser,
        didNotSearch errorDict: [String: NSNumber]
    ) {
        self.logger.error("Did not search", censored: "type=\(serviceType.fullType) and domain='\(domain)' with error=\(errorDict)")
        self.state = .stopped
        self.delegate?.didFailWithError(description: "Failed to search for \(serviceType.name) services")
    }

    public func netServiceBrowser(
        _ browser: NetServiceBrowser,
        didFind service: NetService,
        moreComing: Bool
    ) {
        self.logger.debug("Did find service", censored: "\(service.name)")
        let bonjourService = BonjourService(service: service, serviceType: serviceType)
        self.activeServices.update(with: bonjourService)
        self.delegate?.didAdd(service: bonjourService)

        if !moreComing {
            browser.stop()
        }
    }

    public func netServiceBrowser(
        _ browser: NetServiceBrowser,
        didRemove service: NetService,
        moreComing: Bool
    ) {
        self.logger.debug("Did remove service", censored: "\(service.name)")
        let bonjourService = BonjourService(service: service, serviceType: serviceType)
        self.activeServices.remove(bonjourService)
        self.delegate?.didRemove(service: bonjourService)

        if !moreComing {
            browser.stop()
        }
    }
}
