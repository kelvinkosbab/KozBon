//
//  SiriNetworkSummaryTests.swift
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

// MARK: - SiriNetworkSummaryTests

/// Pins what Siri says after the Scan and List actions. Category
/// labels are injected in English and lists formatted for `en_US`, so
/// the assertions don't depend on whether `swift test` resolves the
/// string catalog.
@Suite("SiriNetworkSummary")
@MainActor
struct SiriNetworkSummaryTests {

    // MARK: - Helpers

    private let locale = Locale(identifier: "en_US")

    private nonisolated static func englishLabel(_ category: BonjourServiceCategory?, _ count: Int) -> String {
        let (one, many): (String, String) = switch category {
        case .appleDevices: ("Apple device", "Apple devices")
        case .mediaAndStreaming: ("media device", "media devices")
        case .printersAndScanners: ("printer", "printers")
        case .smartHome: ("smart home device", "smart home devices")
        case .remoteAccess: ("computer", "computers")
        case .none: ("other device", "other devices")
        }
        return "\(count) \(count == 1 ? one : many)"
    }

    /// Services built in a test never resolve a host, so their device
    /// key is the service name: same name, same device.
    private func makeService(name: String, type: String) -> BonjourService {
        let serviceType = BonjourServiceType(name: type, type: type, transportLayer: .tcp)
        return BonjourService(
            service: NetService(domain: "local.", type: serviceType.fullType, name: name, port: 8080),
            serviceType: serviceType
        )
    }

    private func breakdown(_ services: [BonjourService]) -> String {
        SiriNetworkSummary.breakdown(
            of: SiriNetworkSummary.devices(from: services),
            locale: locale,
            label: Self.englishLabel
        )
    }

    // MARK: - Devices

    @Test("Services on the same host count as one device")
    func servicesOnOneHostAreOneDevice() {
        let services = [
            makeService(name: "Living Room", type: "airplay"),
            makeService(name: "Living Room", type: "raop"),
            makeService(name: "Office", type: "ipp")
        ]
        let devices = SiriNetworkSummary.devices(from: services)
        #expect(devices.map(\.name) == ["Living Room", "Office"])
        #expect(devices.first?.services.count == 2)
    }

    @Test("A device takes the highest-priority category any of its services matches")
    func deviceCategoryUsesPriorityOrder() {
        // ssh alone is remote access; with AirPlay it's an Apple device.
        let services = [
            makeService(name: "Studio Mac", type: "ssh"),
            makeService(name: "Studio Mac", type: "airplay")
        ]
        #expect(SiriNetworkSummary.devices(from: services).first?.category == .appleDevices)
    }

    @Test("A device whose services fit no category is an other device")
    func uncategorizedDeviceIsOther() {
        let services = [makeService(name: "Gadget", type: "completely-novel-protocol")]
        #expect(SiriNetworkSummary.devices(from: services).first?.category == nil)
    }

    @Test("A device with only a RAOP-style name still gets that name")
    func raopOnlyDeviceKeepsItsName() {
        let services = [makeService(name: "58E28F@Den", type: "raop")]
        #expect(SiriNetworkSummary.devices(from: services).first?.name == "58E28F@Den")
    }

    // MARK: - Breakdown

    @Test("One category reads as a single phrase")
    func singleCategory() {
        #expect(breakdown([makeService(name: "TV", type: "airplay")]) == "1 Apple device")
    }

    @Test("Two categories join with `and`")
    func twoCategories() {
        let services = [
            makeService(name: "TV", type: "airplay"),
            makeService(name: "Office", type: "ipp")
        ]
        #expect(breakdown(services) == "1 Apple device and 1 printer")
    }

    @Test("Three or more categories use the serial comma")
    func threeCategories() {
        let services = [
            makeService(name: "TV", type: "airplay"),
            makeService(name: "Office", type: "ipp"),
            makeService(name: "Server", type: "ssh")
        ]
        #expect(breakdown(services) == "1 Apple device, 1 printer, and 1 computer")
    }

    @Test("Categories read in a fixed order regardless of discovery order")
    func breakdownOrderIsStable() {
        let services = [
            makeService(name: "Gadget", type: "completely-novel-protocol"),
            makeService(name: "Server", type: "ssh"),
            makeService(name: "Speaker", type: "googlecast"),
            makeService(name: "Hub", type: "matter"),
            makeService(name: "Office", type: "ipp"),
            makeService(name: "TV", type: "airplay")
        ]
        #expect(breakdown(services) == "1 Apple device, 1 printer, 1 smart home device, "
            + "1 media device, 1 computer, and 1 other device")
    }

    @Test("Counts are per device: an Apple TV with three services is one Apple device")
    func breakdownCountsDevices() {
        let services = [
            makeService(name: "Living Room", type: "airplay"),
            makeService(name: "Living Room", type: "raop"),
            makeService(name: "Living Room", type: "companion-link"),
            makeService(name: "Bedroom", type: "airplay")
        ]
        #expect(breakdown(services) == "2 Apple devices")
    }

    // MARK: - Replies

    @Test("No services on a local network suggests checking permission")
    func emptyReplyOnNetwork() {
        let reply = SiriNetworkSummary.scanReply(services: [], isOnLocalNetwork: true)
        #expect(reply == Strings.Siri.noServicesFound)
    }

    @Test("No services off Wi-Fi and Ethernet says there's no network to scan")
    func emptyReplyOffNetwork() {
        let scan = SiriNetworkSummary.scanReply(services: [], isOnLocalNetwork: false)
        let list = SiriNetworkSummary.listReply(services: [], isOnLocalNetwork: false)
        #expect(scan == Strings.Siri.notOnLocalNetwork)
        #expect(list == Strings.Siri.notOnLocalNetwork)
    }

    @Test("The Scan reply carries the breakdown and no names")
    func scanReplyHasBreakdown() {
        let services = [makeService(name: "Living Room", type: "airplay")]
        let reply = SiriNetworkSummary.scanReply(
            services: services, isOnLocalNetwork: true, locale: locale, label: Self.englishLabel
        )
        #expect(reply.contains("1 Apple device"))
        #expect(!reply.contains("Living Room"))
    }

    @Test("The List reply names a single device")
    func listReplyNamesOnlyDevice() {
        let services = [
            makeService(name: "Living Room", type: "airplay"),
            makeService(name: "Living Room", type: "raop")
        ]
        let reply = SiriNetworkSummary.listReply(
            services: services, isOnLocalNetwork: true, locale: locale, label: Self.englishLabel
        )
        #expect(reply.hasSuffix(Strings.Siri.singleDevice("Living Room")))
    }

    @Test("The List reply names the first few devices and counts the rest")
    func listReplyCapsNames() {
        let names = ["A", "B", "C", "D", "E"]
        let services = names.map { makeService(name: $0, type: "airplay") }
        let reply = SiriNetworkSummary.listReply(
            services: services, isOnLocalNetwork: true, locale: locale, label: Self.englishLabel
        )
        let expectedNames = SiriNetworkSummary.joinedList(
            ["A", "B", "C", Strings.Siri.moreCount(2)], locale: locale
        )
        #expect(reply.hasSuffix(Strings.Siri.theyInclude(expectedNames)))
        #expect(!reply.contains("D"))
    }
}
