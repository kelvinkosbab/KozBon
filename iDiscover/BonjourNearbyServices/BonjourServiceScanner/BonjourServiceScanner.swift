//
//  BonjourServiceScanner.swift
//
//  Created by Kelvin Kosbab on 12/24/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation
import Core

// MARK: - BonjourServiceScannerDelegate

protocol BonjourServiceScannerDelegate: AnyObject {
    func didAdd(service: BonjourService)
    func didRemove(service: BonjourService)
    func didReset()
}

// MARK: - BonjourServiceScanner

class BonjourServiceScanner: BonjourServiceScannerDelegate {

    // MARK: - Properties

    private var typeScanners: [BonjourServiceTypeScanner] = []
    private var services: Set<BonjourService> = Set()
    private let logger: Loggable = Logger(category: "BonjourServiceScanner")

    weak var delegate: BonjourServiceScannerDelegate?

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

    var isProcessing: Bool {
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

    func startScan() {
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

        // Populate service browsers with user-created service types
        for publishedService in MyBonjourPublishManager.shared.publishedServices {
            if !BonjourServiceType.exists(serviceTypes: allServiceTypes, fullType: publishedService.serviceType.fullType) {
                let serviceBrowser = BonjourServiceTypeScanner(
                    serviceType: publishedService.serviceType,
                    domain: publishedService.service.domain
                )
                serviceBrowser.delegate = self
                self.typeScanners.append(serviceBrowser)
            }
        }

        self.logger.info("Starting scan with \(self.typeScanners.count) type scanners")

        for scanner in self.typeScanners {
            scanner.startScan()
        }
    }

    func stopScan() {
        for typeScanner in self.typeScanners {
            typeScanner.stopScan()
        }
    }

    // MARK: - BonjourServiceScannerDelegate

    func didAdd(service: BonjourService) {
        self.services.update(with: service)
        self.delegate?.didAdd(service: service)
    }

    func didRemove(service: BonjourService) {
        self.services.remove(service)
        self.delegate?.didRemove(service: service)
    }

    func didReset() {
        self.services.removeAll()
        self.delegate?.didReset()
    }
}
