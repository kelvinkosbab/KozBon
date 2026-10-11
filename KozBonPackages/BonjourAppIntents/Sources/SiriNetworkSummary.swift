//
//  SiriNetworkSummary.swift
//  BonjourAppIntents
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourAI
import BonjourLocalization
import BonjourModels

// MARK: - SiriDevice

/// One device on the network: the services that share a host.
struct SiriDevice {

    /// The name Siri reads aloud.
    let name: String

    /// `nil` when none of the device's services fits a category.
    let category: BonjourServiceCategory?

    let services: [BonjourService]
}

// MARK: - SiriNetworkSummary

/// Builds what Siri says after the Scan and List actions run.
///
/// Counts devices, not services: an Apple TV advertising AirPlay, RAOP,
/// and Companion Link is one Apple device, not three. Devices are keyed
/// by ``BonjourService/hostIdentifier``, the same key the Discover tab
/// groups by.
@MainActor
enum SiriNetworkSummary {

    typealias CategoryLabel = (BonjourServiceCategory?, Int) -> String

    /// How many device names the List reply reads before "and N more".
    static let spokenNameCap = 3

    /// The order categories are read in, and the priority a device with
    /// services in several categories is filed under. Apple comes first
    /// so a Mac sharing its screen counts as an Apple device, not a
    /// remote-access one.
    static let categoryOrder: [BonjourServiceCategory] = [
        .appleDevices, .printersAndScanners, .smartHome, .mediaAndStreaming, .remoteAccess
    ]

    // MARK: - Replies

    /// The Scan action's reply: device and service counts plus a
    /// breakdown by category.
    static func scanReply(
        services: [BonjourService],
        isOnLocalNetwork: Bool,
        locale: Locale = .current,
        label: CategoryLabel = SiriNetworkSummary.localizedLabel
    ) -> String {
        guard !services.isEmpty else {
            return emptyReply(isOnLocalNetwork: isOnLocalNetwork)
        }
        return foundSentence(services: services, devices: devices(from: services), locale: locale, label: label)
    }

    /// The List action's reply: the Scan reply, then the first few
    /// device names.
    static func listReply(
        services: [BonjourService],
        isOnLocalNetwork: Bool,
        locale: Locale = .current,
        label: CategoryLabel = SiriNetworkSummary.localizedLabel
    ) -> String {
        guard !services.isEmpty else {
            return emptyReply(isOnLocalNetwork: isOnLocalNetwork)
        }
        let grouped = devices(from: services)
        let found = foundSentence(services: services, devices: grouped, locale: locale, label: label)
        return "\(found) \(namesSentence(devices: grouped, locale: locale))"
    }

    // MARK: - Grouping

    /// Groups services by host, in the order hosts first appear.
    static func devices(from services: [BonjourService]) -> [SiriDevice] {
        var order: [String] = []
        var membersByKey: [String: [BonjourService]] = [:]
        for service in services {
            let key = service.hostIdentifier
            if membersByKey[key] == nil {
                order.append(key)
            }
            membersByKey[key, default: []].append(service)
        }
        return order.compactMap { key in
            guard let members = membersByKey[key], !members.isEmpty else { return nil }
            return SiriDevice(
                name: spokenName(for: members),
                category: category(for: members),
                services: members
            )
        }
    }

    /// "2 Apple devices, 1 printer or scanner, and 1 other device".
    static func breakdown(
        of devices: [SiriDevice],
        locale: Locale,
        label: CategoryLabel
    ) -> String {
        var counts: [BonjourServiceCategory?: Int] = [:]
        for device in devices {
            counts[device.category, default: 0] += 1
        }
        let order: [BonjourServiceCategory?] = categoryOrder + [nil]
        let phrases = order.compactMap { category in
            counts[category].map { label(category, $0) }
        }
        return joinedList(phrases, locale: locale)
    }

    /// "A, B, and C" in the reply's language.
    static func joinedList(_ items: [String], locale: Locale) -> String {
        let formatter = ListFormatter()
        formatter.locale = locale
        return formatter.string(from: items) ?? items.joined(separator: ", ")
    }

    nonisolated static func localizedLabel(_ category: BonjourServiceCategory?, count: Int) -> String {
        switch category {
        case .appleDevices: Strings.Siri.appleDevices(count)
        case .mediaAndStreaming: Strings.Siri.mediaDevices(count)
        case .printersAndScanners: Strings.Siri.printers(count)
        case .smartHome: Strings.Siri.smartHomeDevices(count)
        case .remoteAccess: Strings.Siri.computers(count)
        case .none: Strings.Siri.otherDevices(count)
        }
    }

    // MARK: - Internals

    private static func emptyReply(isOnLocalNetwork: Bool) -> String {
        isOnLocalNetwork ? Strings.Siri.noServicesFound : Strings.Siri.notOnLocalNetwork
    }

    private static func foundSentence(
        services: [BonjourService],
        devices: [SiriDevice],
        locale: Locale,
        label: CategoryLabel
    ) -> String {
        Strings.Siri.foundSummary(
            devices: Strings.Siri.deviceCount(devices.count),
            services: Strings.Siri.serviceCount(services.count),
            breakdown: breakdown(of: devices, locale: locale, label: label)
        )
    }

    private static func namesSentence(devices: [SiriDevice], locale: Locale) -> String {
        if devices.count == 1, let only = devices.first {
            return Strings.Siri.singleDevice(only.name)
        }
        var items = devices.prefix(spokenNameCap).map(\.name)
        if devices.count > spokenNameCap {
            items.append(Strings.Siri.moreCount(devices.count - spokenNameCap))
        }
        return Strings.Siri.theyInclude(joinedList(items, locale: locale))
    }

    /// RAOP names carry a MAC prefix (`58E28F@Living Room`), so prefer a
    /// sibling service's name when the device has one.
    private static func spokenName(for services: [BonjourService]) -> String {
        guard let named = services.first(where: { !$0.service.name.contains("@") }) ?? services.first else {
            return ""
        }
        return SiriServiceNameRenderer.voiceFriendlyName(for: named)
    }

    /// A device is filed under the first category in ``categoryOrder``
    /// that any of its services matches.
    private static func category(for services: [BonjourService]) -> BonjourServiceCategory? {
        categoryOrder.first { category in
            services.contains { category.matches($0) }
        }
    }
}
