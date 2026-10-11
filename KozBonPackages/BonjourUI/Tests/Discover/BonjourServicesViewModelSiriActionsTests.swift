//
//  BonjourServicesViewModelSiriActionsTests.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourCore
import BonjourModels
import BonjourScanning
@testable import BonjourUI

// MARK: - BonjourServicesViewModelSiriActionsTests

@Suite("BonjourServicesViewModel Siri actions")
@MainActor
struct BonjourServicesViewModelSiriActionsTests {

    private func makeViewModel() -> BonjourServicesViewModel {
        BonjourServicesViewModel(
            serviceScanner: MockBonjourServiceScanner(),
            publishManager: MockBonjourPublishManager(),
            localNetworkMonitor: MockLocalNetworkMonitor()
        )
    }

    private func makeService(name: String, type: String = "http") -> BonjourService {
        let serviceType = BonjourServiceType(name: name, type: type, transportLayer: .tcp)
        return BonjourService(
            service: NetService(domain: "local.", type: serviceType.fullType, name: name, port: 8080),
            serviceType: serviceType
        )
    }

    @Test("A service already found is selected at once")
    func selectsFoundService() {
        let viewModel = makeViewModel()
        let service = makeService(name: "Office")
        viewModel.didAdd(service: service)

        viewModel.selectService(named: "Office", fullType: "_http._tcp")

        #expect(viewModel.selectedService == service)
    }

    @Test("A service not found yet is selected when the scan finds it")
    func selectsWhenFound() {
        let viewModel = makeViewModel()
        viewModel.selectService(named: "Office", fullType: "_http._tcp")
        #expect(viewModel.selectedService == nil)

        viewModel.didAdd(service: makeService(name: "Den"))
        #expect(viewModel.selectedService == nil)

        let office = makeService(name: "Office")
        viewModel.didAdd(service: office)
        #expect(viewModel.selectedService == office)
        #expect(viewModel.pendingSelection == nil)
    }

    @Test("The type must match as well as the name")
    func matchesType() {
        let viewModel = makeViewModel()
        viewModel.selectService(named: "Office", fullType: "_ipp._tcp")
        viewModel.didAdd(service: makeService(name: "Office"))
        #expect(viewModel.selectedService == nil)
    }

    @Test("Broadcasts from Siri are recorded once and cleared together")
    func recordsBroadcasts() {
        let viewModel = makeViewModel()
        let service = makeService(name: "Office")

        viewModel.recordPublishedService(service)
        viewModel.recordPublishedService(service)
        #expect(viewModel.customPublishedServices == [service])

        viewModel.removeAllPublishedServices()
        #expect(viewModel.customPublishedServices.isEmpty)
    }
}
