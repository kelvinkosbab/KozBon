//
//  BonjourServicesViewModel+SiriActions.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourModels

// MARK: - PendingServiceSelection

/// A service to select once the scan finds it.
struct PendingServiceSelection {
    let name: String
    let fullType: String

    func matches(_ service: BonjourService) -> Bool {
        service.service.name == name && service.serviceType.fullType == fullType
    }
}

// MARK: - Siri Actions

extension BonjourServicesViewModel {

    /// Selects the service with this name and type, or waits for the
    /// scan to find it. Used by the Open in KozBon Siri action.
    public func selectService(named name: String, fullType: String) {
        let wanted = PendingServiceSelection(name: name, fullType: fullType)
        if let match = activeServices.first(where: wanted.matches) {
            selectedService = match
            pendingSelection = nil
        } else {
            pendingSelection = wanted
        }
    }

    /// Selects a newly discovered service if Open in KozBon was waiting
    /// for it. Called from `didAdd(service:)`.
    func selectIfPending(_ service: BonjourService) {
        guard let pendingSelection, pendingSelection.matches(service) else { return }
        selectedService = service
        self.pendingSelection = nil
    }

    /// Adds a broadcast started outside the Broadcast form (from Siri),
    /// replacing an existing entry for the same service.
    public func recordPublishedService(_ service: BonjourService) {
        if let index = customPublishedServices.firstIndex(of: service) {
            customPublishedServices[index] = service
        } else {
            customPublishedServices.append(service)
        }
    }

    /// Forgets every broadcast after Siri stopped them all.
    public func removeAllPublishedServices() {
        customPublishedServices = []
    }
}
