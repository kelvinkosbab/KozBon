//
//  BonjourServicePromptBuilderTests.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourAI
import BonjourCore
import BonjourModels

// MARK: - BonjourServicePromptBuilderTests

@Suite("BonjourServicePromptBuilder")
@MainActor
struct BonjourServicePromptBuilderTests {

    // MARK: - Helpers

    private func makeService(
        name: String = "Test Device",
        typeName: String = "HTTP",
        type: String = "http",
        transportLayer: TransportLayer = .tcp,
        detail: String? = "Web server protocol"
    ) -> BonjourService {
        let serviceType = BonjourServiceType(
            name: typeName,
            type: type,
            transportLayer: transportLayer,
            detail: detail
        )
        return BonjourService(
            service: NetService(
                domain: "local.",
                type: serviceType.fullType,
                name: name,
                port: 8080
            ),
            serviceType: serviceType
        )
    }

    // MARK: - System Instructions

    @Test func systemInstructionsIsNotEmpty() {
        #expect(!BonjourServicePromptBuilder.systemInstructions.isEmpty)
    }

    @Test func systemInstructionsContainsBonjourContext() {
        let instructions = BonjourServicePromptBuilder.systemInstructions
        #expect(instructions.contains("Bonjour"))
        #expect(instructions.contains("mDNS"))
    }

    // MARK: - Device Context

    @Test func deviceContextIsNotEmpty() {
        #expect(!BonjourServicePromptBuilder.deviceContext.isEmpty)
    }

    @Test func currentDeviceShortNameIsNotEmpty() {
        #expect(!BonjourServicePromptBuilder.currentDeviceShortName.isEmpty)
    }

    // MARK: - Prompt Building

    @Test func promptContainsServiceName() {
        let service = makeService(typeName: "HTTP")
        let prompt = BonjourServicePromptBuilder.buildPrompt(service: service)
        #expect(prompt.contains("Service name: HTTP"))
    }

    @Test func promptContainsFullType() {
        let service = makeService(type: "http")
        let prompt = BonjourServicePromptBuilder.buildPrompt(service: service)
        #expect(prompt.contains("Full type: _http._tcp"))
    }

    @Test func promptContainsTransportLayer() {
        let service = makeService(transportLayer: .tcp)
        let prompt = BonjourServicePromptBuilder.buildPrompt(service: service)
        #expect(prompt.contains("Transport layer: TCP"))
    }

    @Test func promptContainsUDPTransportLayer() {
        let service = makeService(transportLayer: .udp)
        let prompt = BonjourServicePromptBuilder.buildPrompt(service: service)
        #expect(prompt.contains("Transport layer: UDP"))
    }

    @Test func promptContainsDeviceName() {
        let service = makeService(name: "Living Room Apple TV")
        let prompt = BonjourServicePromptBuilder.buildPrompt(service: service)
        #expect(prompt.contains("Device advertising the service: Living Room Apple TV"))
    }

    @Test func promptContainsDomain() {
        let service = makeService()
        let prompt = BonjourServicePromptBuilder.buildPrompt(service: service)
        #expect(prompt.contains("Domain: local."))
    }

    @Test func promptContainsProtocolDescription() {
        let service = makeService(detail: "Web server protocol")
        let prompt = BonjourServicePromptBuilder.buildPrompt(service: service)
        #expect(prompt.contains("Protocol description: Web server protocol"))
    }

    @Test func promptOmitsProtocolDescriptionWhenNil() {
        let service = makeService(detail: nil)
        let prompt = BonjourServicePromptBuilder.buildPrompt(service: service)
        #expect(!prompt.contains("Protocol description:"))
    }

    @Test func promptContainsDeviceContext() {
        let service = makeService()
        let prompt = BonjourServicePromptBuilder.buildPrompt(service: service)
        #expect(prompt.contains(BonjourServicePromptBuilder.deviceContext))
    }

    @Test func promptContainsInteractionQuestion() {
        let service = makeService()
        let prompt = BonjourServicePromptBuilder.buildPrompt(service: service)
        let deviceName = BonjourServicePromptBuilder.currentDeviceShortName
        #expect(prompt.contains("how can I interact with it from my \(deviceName)?"))
    }

    @Test func promptOmitsAddressesWhenEmpty() {
        let service = makeService()
        let prompt = BonjourServicePromptBuilder.buildPrompt(service: service)
        #expect(!prompt.contains("IP addresses:"))
    }

    @Test func promptOmitsTxtRecordsWhenEmpty() {
        let service = makeService()
        let prompt = BonjourServicePromptBuilder.buildPrompt(service: service)
        #expect(!prompt.contains("TXT records:"))
    }
}
