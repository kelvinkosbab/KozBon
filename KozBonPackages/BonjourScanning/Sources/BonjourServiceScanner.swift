//
//  BonjourServiceScanner.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourCore
import BonjourModels

// MARK: - BonjourServiceScannerDelegate

/// Delegate protocol for receiving Bonjour service scanner lifecycle events.
@MainActor
public protocol BonjourServiceScannerDelegate: AnyObject, Sendable {
    /// Called when a new service is discovered on the network.
    func didAdd(service: BonjourService)
    /// Called when a previously discovered service is no longer available.
    func didRemove(service: BonjourService)
    /// Called when the scanner resets, indicating all previous results are invalidated.
    func didReset()
    /// Called when a scan operation fails for a particular service type.
    func didFailWithError(description: String)
}

// MARK: - BonjourServiceScanner

/// Aggregates discovery results from multiple ``BonjourServiceTypeScanner`` instances,
/// one per registered service type.
///
/// The scanner creates a ``BonjourServiceTypeScanner`` for every known ``BonjourServiceType``
/// and forwards discovery events through its ``delegate``. Use the ``shared`` singleton
/// for production scanning.
@MainActor
public final class BonjourServiceScanner: BonjourServiceScannerDelegate {

    public init() {}

    // MARK: - Properties

    private var typeScanners: [BonjourServiceTypeScanner] = []
    private var services: Set<BonjourService> = Set()
    private let logger: Loggable = Logger(category: "BonjourServiceScanner")

    /// The delegate that receives service discovery lifecycle events.
    public weak var delegate: BonjourServiceScannerDelegate?

    // MARK: - Service Browser State

    private var browserState: BonjourServiceBrowserState {
        for serviceBrowser in self.typeScanners where serviceBrowser.state.isSearching {
            return .searching
        }
        return .stopped
    }

    // MARK: - Resolving Addresses

    private var isResolvingFoundServiceAddresses: Bool {
        for service in self.services where service.isResolving {
            return true
        }
        return false
    }

    // MARK: - Completed Discovery Process

    /// Whether any type scanner is actively searching or any discovered service is still resolving its address.
    public var isProcessing: Bool {
        return self.browserState.isSearching || self.isResolvingFoundServiceAddresses
    }

    // MARK: - Services

    private func reset() {
        for browser in self.typeScanners {
            browser.reset()
        }
        self.didReset()
    }

    // MARK: - Start / Stop

    /// Starts scanning for all known Bonjour service types on the local network.
    ///
    /// Resets any previous scan state, creates a ``BonjourServiceTypeScanner`` for each
    /// registered service type, and additionally creates scanners for any user-published
    /// service types not already in the library.
    ///
    /// - Parameter publishedServices: Services published by the user, used to ensure their
    ///   types are also scanned even if not in the built-in library.
    public func startScan(publishedServices: Set<BonjourService> = []) {
        self.logger.debug("Starting scan")

        // First reset all the scanners
        self.reset()

        // Populate service browsers with existing service types
        let allServiceTypes = BonjourServiceType.fetchAll()
        for serviceType in allServiceTypes {

            let serviceBrowser = BonjourServiceTypeScanner(serviceType: serviceType, domain: "")
            serviceBrowser.delegate = self
            self.typeScanners.append(serviceBrowser)
        }

        // Populate service browsers with user-published service types
        for publishedService in publishedServices where
            !BonjourServiceType.exists(serviceTypes: allServiceTypes, fullType: publishedService.serviceType.fullType) {
            let serviceBrowser = BonjourServiceTypeScanner(
                serviceType: publishedService.serviceType,
                domain: publishedService.service.domain
            )
            serviceBrowser.delegate = self
            self.typeScanners.append(serviceBrowser)
        }

        self.logger.info("Starting scan with \(self.typeScanners.count) type scanners")

        for scanner in self.typeScanners {
            scanner.startScan()
        }
    }

    /// Stops all active type scanners.
    public func stopScan() {
        for typeScanner in self.typeScanners {
            typeScanner.stopScan()
        }
    }

    // MARK: - BonjourServiceScannerDelegate

    public func didAdd(service: BonjourService) {
        self.services.update(with: service)
        self.delegate?.didAdd(service: service)
    }

    public func didRemove(service: BonjourService) {
        self.services.remove(service)
        self.delegate?.didRemove(service: service)
    }

    public func didReset() {
        self.services.removeAll()
        self.delegate?.didReset()
    }

    public func didFailWithError(description: String) {
        self.delegate?.didFailWithError(description: description)
    }
}
