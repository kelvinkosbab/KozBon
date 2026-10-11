//
//  BonjourServiceDetailViewModelTests.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourModels
@testable import BonjourUI

// MARK: - BonjourServiceDetailViewModelTests

@Suite("BonjourServiceDetailViewModel")
@MainActor
struct BonjourServiceDetailViewModelTests {

    private func makeViewModel(type: String) -> BonjourServiceDetailViewModel {
        let serviceType = BonjourServiceType(name: "Test", type: type, transportLayer: .tcp)
        let service = BonjourService(
            service: NetService(domain: "local.", type: serviceType.fullType, name: "Test", port: 8080),
            serviceType: serviceType
        )
        return BonjourServiceDetailViewModel(service: service)
    }

    @Test("A printer's Siri tip suggests finding printers")
    func printerTipCategory() {
        #expect(makeViewModel(type: "ipp").siriTipCategory == .printersAndScanners)
    }

    @Test("A type in no category gets no Find tip")
    func uncategorizedTypeHasNoTip() {
        #expect(makeViewModel(type: "kozbon-test").siriTipCategory == nil)
    }
}
