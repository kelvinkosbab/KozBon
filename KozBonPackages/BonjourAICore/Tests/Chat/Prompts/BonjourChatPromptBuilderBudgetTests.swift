//
//  BonjourChatPromptBuilderBudgetTests.swift
//  BonjourAICore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourAICore
import BonjourCore
import BonjourModels

// MARK: - BonjourChatPromptBuilderBudgetTests

/// Pins the difference between the on-device and cloud context budgets:
/// the on-device block stays as compact as before, while cloud models
/// get the detail a 200K window has room for.
@Suite("BonjourChatPromptBuilder · Context Budget")
@MainActor
struct BonjourChatPromptBuilderBudgetTests {

    // MARK: - Helpers

    private func makeService(name: String, type: String, detail: String? = nil) -> BonjourService {
        let serviceType = BonjourServiceType(name: type.uppercased(), type: type, transportLayer: .tcp, detail: detail)
        return BonjourService(
            service: NetService(domain: "local.", type: serviceType.fullType, name: name, port: 8080),
            serviceType: serviceType
        )
    }

    // MARK: - Service List

    @Test("The cloud budget lists services the on-device budget summarizes as \"…and N more\"")
    func cloudListsMoreServices() {
        let services = (0..<60).map { makeService(name: "Device \($0)", type: "http") }
        let context = BonjourChatPromptBuilder.ChatContext(discoveredServices: services)

        let onDevice = BonjourChatPromptBuilder.contextBlock(context: context)
        let cloud = BonjourChatPromptBuilder.contextBlock(context: context, budget: .cloud)

        #expect(onDevice.contains("...and 10 more"))
        #expect(!onDevice.contains("Device 59"))
        #expect(!cloud.contains("...and "))
        #expect(cloud.contains("Device 59"))
    }

    @Test("Only the cloud budget tags services with their categories")
    func cloudTagsCategories() {
        let context = BonjourChatPromptBuilder.ChatContext(
            discoveredServices: [makeService(name: "Living Room Apple TV", type: "airplay")]
        )

        let onDevice = BonjourChatPromptBuilder.contextBlock(context: context)
        let cloud = BonjourChatPromptBuilder.contextBlock(context: context, budget: .cloud)

        #expect(!onDevice.contains("categories:"))
        #expect(cloud.contains("categories: "))
        #expect(cloud.contains(BonjourServiceCategory.appleDevices.promptLabel))
    }

    // MARK: - Library

    @Test("The cloud budget names library types; the on-device budget sends counts only")
    func cloudNamesLibraryTypes() {
        let library = [
            BonjourServiceType(name: "Jellyfin", type: "jellyfin", transportLayer: .tcp),
            BonjourServiceType(name: "Gopher", type: "gopher", transportLayer: .tcp)
        ]
        let context = BonjourChatPromptBuilder.ChatContext(serviceTypeLibrary: library)

        let onDevice = BonjourChatPromptBuilder.contextBlock(context: context)
        let cloud = BonjourChatPromptBuilder.contextBlock(context: context, budget: .cloud)

        #expect(!onDevice.contains("Jellyfin"))
        #expect(cloud.contains("Jellyfin"))
        #expect(cloud.contains("Gopher"))
    }

    // MARK: - Type Descriptions

    @Test("The cloud budget describes each service type found on the network once")
    func cloudDescribesDiscoveredTypes() {
        let detail = "Streams audio and video to receivers."
        let context = BonjourChatPromptBuilder.ChatContext(discoveredServices: [
            makeService(name: "Living Room", type: "airplay", detail: detail),
            makeService(name: "Kitchen", type: "airplay", detail: detail)
        ])

        let onDevice = BonjourChatPromptBuilder.contextBlock(context: context)
        let cloud = BonjourChatPromptBuilder.contextBlock(context: context, budget: .cloud)

        #expect(!onDevice.contains("Service types on this network"))
        #expect(cloud.contains("Service types on this network (1):"))
        #expect(cloud.components(separatedBy: detail).count == 2)
    }

    @Test("A type identifier with its underscore pulls in the type's description")
    func referencedMatchesIdentifier() {
        let serviceType = BonjourServiceType(
            name: "Internet Printing Protocol",
            type: "ipp",
            transportLayer: .tcp,
            detail: "Sends print jobs to network printers."
        )
        let context = BonjourChatPromptBuilder.ChatContext(serviceTypeLibrary: [serviceType])

        let named = BonjourChatPromptBuilder.queriedDescriptionsBlock(context: context, query: "What is _ipp._tcp?")
        let bare = BonjourChatPromptBuilder.queriedDescriptionsBlock(context: context, query: "What happens when shipping ipp?")

        #expect(named.contains("Sends print jobs"))
        #expect(bare.isEmpty)
    }

    // MARK: - Signature

    @Test("The signature follows the budget, so cloud sessions re-send when cloud-only detail changes")
    func signatureFollowsBudget() {
        let context = BonjourChatPromptBuilder.ChatContext(
            discoveredServices: [makeService(name: "Living Room Apple TV", type: "airplay")]
        )
        #expect(
            BonjourChatPromptBuilder.contextSignature(context: context)
                != BonjourChatPromptBuilder.contextSignature(context: context, budget: .cloud)
        )
    }
}
