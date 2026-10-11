//
//  FindServicesIntentTests.swift
//  BonjourAppIntents
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
import BonjourCore
import BonjourLocalization
import BonjourModels
@testable import BonjourAppIntents

// MARK: - FindServicesIntentTests

@Suite("FindServicesIntent")
@MainActor
struct FindServicesIntentTests {

    private func makeService(name: String, type: String) -> BonjourService {
        let serviceType = BonjourServiceType(name: type, type: type, transportLayer: .tcp)
        return BonjourService(
            service: NetService(domain: "local.", type: serviceType.fullType, name: name, port: 8080),
            serviceType: serviceType
        )
    }

    @Test("A category keeps only the services in it")
    func filtersByCategory() {
        let services = [
            makeService(name: "Office", type: "ipp"),
            makeService(name: "Den", type: "airplay"),
            makeService(name: "Server", type: "ssh")
        ]
        let found = FindServicesIntent.filter(services, category: .printersAndScanners, fullType: nil)
        #expect(found.map(\.service.name) == ["Office"])
    }

    @Test("A service type wins over a category")
    func typeTakesPrecedence() {
        let services = [makeService(name: "Office", type: "ipp"), makeService(name: "Server", type: "ssh")]
        let found = FindServicesIntent.filter(services, category: .printersAndScanners, fullType: "_ssh._tcp")
        #expect(found.map(\.service.name) == ["Server"])
    }

    @Test("Services found but none matching says so")
    func noMatchesReply() {
        let scanned = IntentScanResult(services: [makeService(name: "Server", type: "ssh")], isOnLocalNetwork: true)
        #expect(FindServicesIntent.reply(matches: [], scanned: scanned) == Strings.Siri.noMatchingServices)
    }

    @Test("An empty scan gives the usual empty-scan reply")
    func emptyScanReply() {
        let scanned = IntentScanResult(services: [], isOnLocalNetwork: false)
        #expect(FindServicesIntent.reply(matches: [], scanned: scanned) == Strings.Siri.notOnLocalNetwork)
    }
}
