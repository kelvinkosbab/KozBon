//
//  BonjourServicesViewModel.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - BonjourServicesViewModel

/// View model responsible for managing the state of nearby Bonjour service scanning.
///
/// Handles starting and stopping scans, tracking discovered services, managing user-published
/// services, and determining when a foreground refresh is needed based on elapsed time.
@MainActor
final class BonjourServicesViewModel: ObservableObject, BonjourServiceScannerDelegate {

    // MARK: - Published Properties

    /// All services currently discovered by the scanner.
    @Published private var activeServices: [BonjourService] = []

    /// Services that the user has published (broadcast) from this device.
    @Published var customPublishedServices: [BonjourService] = []

    /// The current sort order applied to service lists.
    @Published var sortType: BonjourServiceSortType?

    /// Whether the broadcast service sheet is currently presented.
    @Published var isBroadcastBonjourServicePresented = false {
        didSet {
            if !isBroadcastBonjourServicePresented {
                Task {
                    self.load()
                }
            }
        }
    }

    // MARK: - Computed Properties

    /// Active services that match a user-published service, sorted by the current `sortType`.
    var sortedPublishedServices: [BonjourService] {
        let publishedServices = activeServices.filter { service in
            customPublishedServices.contains { publishedSevice in
                service.hostName == publishedSevice.hostName &&
                service.serviceType.fullType == publishedSevice.serviceType.fullType
            }
        }

        switch sortType {
        case .hostNameAsc:
            return publishedServices.sorted { service1, service2 -> Bool in
                service1.service.name < service2.service.name
            }

        case .hostNameDesc:
            return publishedServices.sorted { service1, service2 -> Bool in
                service1.service.name > service2.service.name
            }

        case .serviceNameAsc:
            return publishedServices.sorted { service1, service2 -> Bool in
                service1.serviceType.name < service2.serviceType.name
            }

        case .serviceNameDesc:
            return publishedServices.sorted { service1, service2 -> Bool in
                service1.serviceType.name > service2.serviceType.name
            }

        default:
            return publishedServices
        }
    }

    /// Active services excluding user-published ones, sorted by the current `sortType`.
    var sortedActiveServices: [BonjourService] {
        let nonPublishedServices = activeServices.filter { service in
            !customPublishedServices.contains { publishedSevice in
                service.hostName == publishedSevice.hostName &&
                service.serviceType.fullType == publishedSevice.serviceType.fullType
            }
        }

        switch sortType {
        case .hostNameAsc:
            return nonPublishedServices.sorted { service1, service2 -> Bool in
                service1.service.name < service2.service.name
            }

        case .hostNameDesc:
            return nonPublishedServices.sorted { service1, service2 -> Bool in
                service1.service.name > service2.service.name
            }

        case .serviceNameAsc:
            return nonPublishedServices.sorted { service1, service2 -> Bool in
                service1.serviceType.name < service2.serviceType.name
            }

        case .serviceNameDesc:
            return nonPublishedServices.sorted { service1, service2 -> Bool in
                service1.serviceType.name > service2.serviceType.name
            }

        default:
            return nonPublishedServices
        }
    }

    // MARK: - State

    /// Whether this is the first time the view model is loading. Reset to `false` after the first scan.
    private(set) var isInitialLoad = true

    /// Timestamp of the most recent scan start. Used to determine if a foreground refresh is needed.
    private(set) var lastScanTime: Date?

    /// The scanner used to discover Bonjour services on the local network.
    let serviceScanner: BonjourServiceScannerProtocol

    // MARK: - Init

    /// Creates a new view model with the given service scanner.
    ///
    /// - Parameter serviceScanner: The scanner to use for discovering services. Defaults to the shared singleton.
    init(serviceScanner: BonjourServiceScannerProtocol = BonjourServiceScanner.shared) {
        self.serviceScanner = serviceScanner
        self.serviceScanner.delegate = self
    }

    // MARK: - Strings

    /// Localized title for the create/broadcast button.
    let createButtonString = NSLocalizedString(
        "Create",
        comment: "Create service button string"
    )

    /// Localized empty state message when no services are found.
    let noActiveServicesString = NSLocalizedString(
        "No active Bonjour services",
        comment: "No active Bonjour services string"
    )

    // MARK: - Actions

    /// Starts a new Bonjour service scan if one is not already in progress.
    ///
    /// Updates `lastScanTime` and marks `isInitialLoad` as `false`.
    func load() {

        guard !serviceScanner.isProcessing else {
            return
        }

        serviceScanner.startScan()
        lastScanTime = Date()
        isInitialLoad = false
    }

    /// Returns whether a refresh should be triggered when the app returns to the foreground.
    ///
    /// Returns `true` if no scan has occurred yet or if more than 5 minutes (300 seconds)
    /// have elapsed since the last scan.
    func shouldRefreshOnForeground() -> Bool {
        guard let lastScanTime else {
            return true
        }
        return Date().timeIntervalSince(lastScanTime) > 300
    }

    /// Updates the sort order for service lists.
    ///
    /// - Parameter sortType: The new sort order to apply.
    func sort(sortType: BonjourServiceSortType) {
        self.sortType = sortType
    }

    // MARK: - BonjourServiceScannerDelegate

    /// Called when a new service is discovered or an existing service is updated.
    ///
    /// Uses the service's `id` (derived from the underlying `NetService`) to find
    /// existing entries, since `BonjourService` inherits `NSObject` identity-based hashing.
    func didAdd(service: BonjourService) {
        withAnimation {
            let index = activeServices.firstIndex { $0.id == service.id }
            if let index {
                self.activeServices[index] = service
            } else {
                self.activeServices.append(service)
            }
        }
    }

    /// Called when a previously discovered service is no longer available.
    func didRemove(service: BonjourService) {
        withAnimation {
            let index = activeServices.firstIndex { $0.id == service.id }
            if let index {
                self.activeServices.remove(at: index)
            }
        }
    }

    /// Called when the scanner resets, clearing all discovered services.
    func didReset() {
        withAnimation {
            self.activeServices = []
        }
    }
}
