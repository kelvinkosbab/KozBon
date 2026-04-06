//
//  BonjourServicesViewModel.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourCore
import BonjourModels
import BonjourScanning

// MARK: - BonjourServicesViewModel

/// View model responsible for managing the state of nearby Bonjour service scanning.
///
/// Handles starting and stopping scans, tracking discovered services, managing user-published
/// services, and determining when a foreground refresh is needed based on elapsed time.
@MainActor
@Observable
final class BonjourServicesViewModel: BonjourServiceScannerDelegate {

    // MARK: - Properties

    /// All services currently discovered by the scanner.
    private var activeServices: [BonjourService] = []

    /// Services that the user has published (broadcast) from this device.
    var customPublishedServices: [BonjourService] = []

    /// The currently selected service in the navigation split view.
    var selectedService: BonjourService?

    /// The current sort order applied to service lists.
    var sortType: BonjourServiceSortType?

    /// An error message to display when a scan operation fails.
    var scanError: String?

    /// Whether the broadcast service sheet is currently presented.
    var isBroadcastBonjourServicePresented = false {
        didSet {
            if !isBroadcastBonjourServicePresented {
                Task {
                    self.load()
                }
            }
        }
    }

    // MARK: - Computed Properties

    /// Set of keys identifying published services for O(1) lookup.
    private var publishedServiceKeys: Set<String> {
        Set(customPublishedServices.map { "\($0.hostName)|\($0.serviceType.fullType)" })
    }

    /// Returns whether the given service matches a user-published service.
    private func isPublishedService(_ service: BonjourService) -> Bool {
        publishedServiceKeys.contains("\(service.hostName)|\(service.serviceType.fullType)")
    }

    /// Active services that match a user-published service, sorted by the current `sortType`.
    var sortedPublishedServices: [BonjourService] {
        let filtered = activeServices.filter { isPublishedService($0) }
        guard let sortType else { return filtered }
        return sortType.sorted(filtered)
    }

    /// Active services excluding user-published ones, sorted by the current `sortType`.
    var sortedActiveServices: [BonjourService] {
        let filtered = activeServices.filter { !isPublishedService($0) }
        guard let sortType else { return filtered }
        return sortType.sorted(filtered)
    }

    // MARK: - State

    /// Whether this is the first time the view model is loading. Reset to `false` after the first scan.
    private(set) var isInitialLoad = true

    /// Timestamp of the most recent scan start. Used to determine if a foreground refresh is needed.
    private(set) var lastScanTime: Date?

    /// The scanner used to discover Bonjour services on the local network.
    let serviceScanner: BonjourServiceScannerProtocol

    /// The publish manager used to broadcast services and track published service types.
    let publishManager: BonjourPublishManagerProtocol

    // MARK: - Init

    /// Creates a new view model with the given service scanner and publish manager.
    ///
    /// - Parameter serviceScanner: The scanner to use for discovering services. Defaults to the shared singleton.
    /// - Parameter publishManager: The publish manager to use. Defaults to the shared singleton.
    init(
        serviceScanner: BonjourServiceScannerProtocol = BonjourServiceScanner.shared,
        publishManager: BonjourPublishManagerProtocol = MyBonjourPublishManager.shared
    ) {
        self.serviceScanner = serviceScanner
        self.publishManager = publishManager
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

        serviceScanner.startScan(publishedServices: publishManager.publishedServices)
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
        return Date().timeIntervalSince(lastScanTime) > Constants.Refresh.foregroundRefreshInterval
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

    /// Called when the scanner encounters an error during service discovery.
    func didFailWithError(description: String) {
        withAnimation {
            self.scanError = description
        }
    }
}
