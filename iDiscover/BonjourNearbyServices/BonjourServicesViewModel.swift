//
//  BonjourScanForServicesViewModel.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 9/8/23.
//  Copyright © 2023 Kozinga. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - BonjourServicesViewModel

class BonjourServicesViewModel: ObservableObject, BonjourServiceScannerDelegate {

    @MainActor @Published private var activeServices: [BonjourService] = []
    @MainActor @Published var customPublishedServices: [BonjourService] = []
    @MainActor @Published var sortType: BonjourServiceSortType?

    @MainActor @Published var isBroadcastBonjourServicePresented = false {
        didSet {
            if !isBroadcastBonjourServicePresented {
                Task {
                    self.load()
                }
            }
        }
    }

    @MainActor var sortedPublishedServices: [BonjourService] {
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

    @MainActor var sortedActiveServices: [BonjourService] {
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

    private(set) var isInitialLoad = true
    let serviceScanner = BonjourServiceScanner.shared

    init() {
        self.serviceScanner.delegate = self
    }

    // MARK: - Strings

    let createButtonString = NSLocalizedString(
        "Create",
        comment: "Create service button string"
    )

    let noActiveServicesString = NSLocalizedString(
        "No active Bonjour services",
        comment: "No active Bonjour services string"
    )

    // MARK: - Actions

    @MainActor
    func load() {

        guard !serviceScanner.isProcessing else {
            return
        }

        serviceScanner.startScan()
        isInitialLoad = false
    }

    @MainActor
    func sort(sortType: BonjourServiceSortType) {
        self.sortType = sortType
    }

    // MARK: - BonjourServiceScannerDelegate

    func didAdd(service: BonjourService) {
        Task { @MainActor in
            withAnimation {
                let index = activeServices.firstIndex { $0.hashValue == service.hashValue}
                if let index {
                    self.activeServices[index] = service
                } else {
                    self.activeServices.append(service)
                }
            }
        }
    }

    func didRemove(service: BonjourService) {
        Task { @MainActor in
            withAnimation {
                let index = activeServices.firstIndex { $0.hashValue == service.hashValue}
                if let index {
                    self.activeServices.remove(at: index)
                }
            }
        }
    }

    func didReset() {
        Task { @MainActor in
            withAnimation {
                self.activeServices = []
            }
        }
    }
}
