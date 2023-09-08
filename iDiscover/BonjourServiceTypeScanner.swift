//
//  BonjourServiceTypeScanner.swift
//  Test
//
//  Created by Kelvin Kosbab on 12/25/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation
import Core

// MARK: - BonjourServiceBrowser

/// Scans for services of a given service type (``BonjourServiceType``).
class BonjourServiceTypeScanner : NSObject, NetServiceBrowserDelegate {
    
    // MARK: - Properties
    
    private let serviceBrowser: NetServiceBrowser
    private let serviceType: BonjourServiceType
    private let domain: String
    private let logger: SubsystemCategoryLogger
    private(set) var activeServices = Set<BonjourService>()
    private(set) var state: BonjourServiceBrowserState = .stopped
    
    weak var delegate: BonjourServiceScannerDelegate?
    
    // MARK: - Init
    
    /// Constructs a ``BonjourServiceBrowserByType``.
    init(
        serviceType: BonjourServiceType,
        domain: String
    ) {
        self.serviceBrowser = NetServiceBrowser()
        self.serviceType = serviceType
        self.domain = domain
        self.logger = SubsystemCategoryLogger(
            subsystem: "KozBon",
            category: "Scanner.\(serviceType.fullType).\(domain)"
        )
        
        super.init()
        
        self.serviceBrowser.delegate = self
    }
    
    // MARK: - Start / Stop
    
    func startScan() {
        
        guard self.state != .searching else {
            self.logger.info("Already searching. Do nothing.")
            return
        }
        
        self.serviceBrowser.searchForServices(
            ofType: self.serviceType.fullType,
            inDomain: self.domain
        )
    }
    
    func stopScan() {
        self.serviceBrowser.stop()
    }
    
    func reset() {
        self.stopScan()
        self.activeServices.removeAll()
    }
    
    // MARK: - NetServiceBrowserDelegate
    
    func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
        self.state = .searching
    }
    
    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        self.state = .stopped
    }
    
    func netServiceBrowser(
        _ browser: NetServiceBrowser,
        didNotSearch errorDict: [String : NSNumber]
    ) {
        self.logger.error("Did not search for type=\(self.serviceType.fullType) and domain='\(self.domain)' with error=\(errorDict)")
        self.state = .stopped
    }
    
    func netServiceBrowser(
        _ browser: NetServiceBrowser,
        didFind service: NetService,
        moreComing: Bool
    ) {
        self.logger.debug("Did find service \(service.name)")
        let bonjourService = BonjourService(service: service, serviceType: self.serviceType)
        self.activeServices.update(with: bonjourService)
        
        if !moreComing {
            browser.stop()
        }
    }
    
    func netServiceBrowser(
        _ browser: NetServiceBrowser,
        didRemove service: NetService,
        moreComing: Bool
    ) {
        self.logger.debug("Did remove service \(service.name)")
        let bonjourService = BonjourService(service: service, serviceType: self.serviceType)
        self.activeServices.remove(bonjourService)
        
        if !moreComing {
            browser.stop()
        }
    }
}
