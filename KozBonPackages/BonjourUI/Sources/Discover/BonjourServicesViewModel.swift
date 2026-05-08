//
//  BonjourServicesViewModel.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourCore
import BonjourLocalization
import BonjourModels
import BonjourScanning

// MARK: - BonjourServicesViewModel

/// View model responsible for managing the state of nearby Bonjour service scanning.
///
/// Handles starting and stopping scans, tracking discovered services, managing user-published
/// services, and determining when a foreground refresh is needed based on elapsed time.
///
/// A single instance is created at the app level and shared between the Discover tab
/// and the Chat tab. This is required because the underlying `BonjourServiceScanner`
/// exposes only one `weak var delegate`; creating a separate view model per tab would
/// cause the tabs to overwrite each other's delegate registration, and whichever tab
/// was initialized most recently would silently "win" while the other showed zero
/// discovered services.
@MainActor
@Observable
public final class BonjourServicesViewModel: BonjourServiceScannerDelegate {

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

    /// Builds a Set of `(hostName | fullType)` keys identifying every
    /// service the user is currently broadcasting from this device.
    /// Used by ``flatActiveServices`` and ``sortedPublishedServices``
    /// to bucket each discovered service into "published by this
    /// device" vs "discovered on the network".
    ///
    /// Computed via a function (not a getter) so call sites
    /// explicitly bind it to a local — that way each accessor pays
    /// the construction cost ONCE per call instead of once per
    /// element in the filter closure. The previous getter-based
    /// `publishedServiceKeys` rebuilt the entire Set on every
    /// `.contains` check inside `filter`, turning what should be
    /// O(N + M) into O(N × M) — visible as Discover-tab scroll jank
    /// on networks with many published or discovered services.
    private func makePublishedServiceKeys() -> Set<String> {
        Set(customPublishedServices.map { "\($0.hostName)|\($0.serviceType.fullType)" })
    }

    /// Returns whether the given service matches a user-published service.
    ///
    /// Internally builds a fresh keys Set on each call. Hot loops
    /// that need to filter against the published set should compute
    /// the keys once via ``makePublishedServiceKeys()`` and check
    /// membership inline; this single-shot helper is intended for
    /// per-row checks where the cost of one Set construction is
    /// fine.
    func isPublishedService(_ service: BonjourService) -> Bool {
        makePublishedServiceKeys().contains("\(service.hostName)|\(service.serviceType.fullType)")
    }

    /// Active services that match a user-published service.
    var sortedPublishedServices: [BonjourService] {
        let publishedKeys = makePublishedServiceKeys()
        return activeServices.filter {
            publishedKeys.contains("\($0.hostName)|\($0.serviceType.fullType)")
        }
    }

    /// Active services excluding user-published ones, sorted by the current `sortType`.
    ///
    /// - Host name sorts cluster services from the same device together.
    /// - Service type sorts cluster services of the same protocol together.
    /// - Defaults to host name A→Z when no sort type is set.
    var flatActiveServices: [BonjourService] {
        // Build the published-keys Set once per call, not once per
        // element in the filter — see ``makePublishedServiceKeys()``
        // for the rationale.
        let publishedKeys = makePublishedServiceKeys()
        let nonPublished = activeServices.filter {
            !publishedKeys.contains("\($0.hostName)|\($0.serviceType.fullType)")
        }

        // Filter cases delegate to the shared `BonjourServiceCategory`
        // — the source of truth for which service types belong to
        // each bucket. Sort cases handle ordering inline.
        if let category = sortType?.category {
            return nonPublished
                .filter(category.matches)
                .sorted {
                    ($0.service.name, $0.serviceType.name) < ($1.service.name, $1.serviceType.name)
                }
        }

        switch sortType {
        case .hostNameAsc, nil:
            return nonPublished.sorted {
                ($0.service.name, $0.serviceType.name) < ($1.service.name, $1.serviceType.name)
            }
        case .hostNameDesc:
            return nonPublished.sorted {
                ($1.service.name, $0.serviceType.name) < ($0.service.name, $1.serviceType.name)
            }
        case .serviceNameAsc:
            return nonPublished.sorted {
                ($0.serviceType.name, $0.service.name) < ($1.serviceType.name, $1.service.name)
            }
        case .serviceNameDesc:
            return nonPublished.sorted {
                ($1.serviceType.name, $0.service.name) < ($0.serviceType.name, $1.service.name)
            }
        case .smartHome, .appleDevices, .mediaAndStreaming, .printersAndScanners, .remoteAccess:
            // Unreachable — the `category` branch above covers these.
            // The exhaustive switch is here to satisfy the compiler.
            return []
        }
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
    /// - Parameter serviceScanner: The scanner to use for discovering services.
    /// - Parameter publishManager: The publish manager to use.
    public init(
        serviceScanner: BonjourServiceScannerProtocol,
        publishManager: BonjourPublishManagerProtocol
    ) {
        self.serviceScanner = serviceScanner
        self.publishManager = publishManager
        self.serviceScanner.delegate = self
    }

    /// Convenience initializer that resolves the scanner and publish manager
    /// from a ``DependencyContainer``.
    public convenience init(dependencies: DependencyContainer) {
        self.init(
            serviceScanner: dependencies.bonjourServiceScanner,
            publishManager: dependencies.bonjourPublishManager
        )
    }

    // MARK: - Strings

    /// Localized title for the create/broadcast button.
    let createButtonString = String(localized: Strings.Buttons.create)

    /// Localized empty state message when no services are found.
    let noActiveServicesString = String(localized: Strings.EmptyStates.noActiveServices)

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
    public func didAdd(service: BonjourService) {
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
    public func didRemove(service: BonjourService) {
        withAnimation {
            let index = activeServices.firstIndex { $0.id == service.id }
            if let index {
                self.activeServices.remove(at: index)
            }
        }
    }

    /// Called when the scanner resets, clearing all discovered services.
    public func didReset() {
        withAnimation {
            self.activeServices = []
        }
    }

    /// Called when the scanner encounters an error during service discovery.
    public func didFailWithError(description: String) {
        withAnimation {
            self.scanError = description
        }
    }
}
