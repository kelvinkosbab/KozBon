//
//  IsDeviceOnlineIntentTests.swift
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

// MARK: - IsDeviceOnlineIntentTests

@Suite("IsDeviceOnlineIntent")
@MainActor
struct IsDeviceOnlineIntentTests {

    private func makeService(name: String, type: String = "http") -> BonjourService {
        let serviceType = BonjourServiceType(name: type, type: type, transportLayer: .tcp)
        return BonjourService(
            service: NetService(domain: "local.", type: serviceType.fullType, name: name, port: 8080),
            serviceType: serviceType
        )
    }

    @Test("A name matches ignoring case and accents")
    func matchesLoosely() {
        let services = [makeService(name: "Café Speaker")]
        #expect(IsDeviceOnlineIntent.device(named: "cafe speaker", in: services)?.name == "Café Speaker")
    }

    @Test("An exact match beats one that only contains the query")
    func prefersExactMatch() {
        let services = [makeService(name: "Office Printer"), makeService(name: "Office")]
        #expect(IsDeviceOnlineIntent.device(named: "Office", in: services)?.name == "Office")
    }

    @Test("A partial name still finds the device")
    func matchesPartialName() {
        let services = [makeService(name: "Living Room TV")]
        #expect(IsDeviceOnlineIntent.device(named: "living room", in: services)?.name == "Living Room TV")
    }

    @Test("An unknown name finds nothing")
    func noMatch() {
        #expect(IsDeviceOnlineIntent.device(named: "Garage", in: [makeService(name: "Office")]) == nil)
        #expect(IsDeviceOnlineIntent.device(named: " ", in: [makeService(name: "Office")]) == nil)
    }

    @Test("The reply says yes, not found, or not on a local network")
    func replies() throws {
        let office = makeService(name: "Office")
        let match = try #require(IsDeviceOnlineIntent.device(named: "Office", in: [office]))
        let found = IntentScanResult(services: [office], isOnLocalNetwork: true)
        let offline = IntentScanResult(services: [], isOnLocalNetwork: false)

        #expect(IsDeviceOnlineIntent.reply(query: "Office", match: match, scanned: found)
            == Strings.Siri.deviceOnline("Office"))
        #expect(IsDeviceOnlineIntent.reply(query: "Garage", match: nil, scanned: found)
            == Strings.Siri.deviceNotFound("Garage"))
        #expect(IsDeviceOnlineIntent.reply(query: "Garage", match: nil, scanned: offline)
            == Strings.Siri.notOnLocalNetwork)
    }
}
