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

    @Test func systemInstructionsContainsLanguageDirective() {
        let instructions = BonjourServicePromptBuilder.systemInstructions
        let languageName = BonjourServicePromptBuilder.preferredLanguageName
        #expect(instructions.contains("respond in \(languageName)"))
    }

    // MARK: - Language Detection

    @Test func preferredLanguageNameIsNotEmpty() {
        #expect(!BonjourServicePromptBuilder.preferredLanguageName.isEmpty)
    }

    @Test func preferredLanguageNameIsHumanReadable() {
        let name = BonjourServicePromptBuilder.preferredLanguageName
        // Should be a display name like "English", "Español", etc., not a code like "en"
        #expect(name.count > 2)
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

    @Test func promptContainsLanguageRequest() {
        let service = makeService()
        let prompt = BonjourServicePromptBuilder.buildPrompt(service: service)
        let languageName = BonjourServicePromptBuilder.preferredLanguageName
        #expect(prompt.contains("Please respond in \(languageName)."))
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

    // MARK: - Structured Output

    @Test func systemInstructionsContainsStructuredSections() {
        let instructions = BonjourServicePromptBuilder.systemInstructions
        #expect(instructions.contains("## What It Does"))
        #expect(instructions.contains("## Why It's Running"))
        #expect(instructions.contains("## How to Interact"))
        #expect(instructions.contains("## Configuration Details"))
    }

    // MARK: - Expertise Level

    @Test func promptDefaultsToBasicLevel() {
        let service = makeService()
        let prompt = BonjourServicePromptBuilder.buildPrompt(service: service)
        let beginnerDirective = BonjourServicePromptBuilder.expertiseLevelDirective(.basic)
        #expect(prompt.contains(beginnerDirective))
    }

    @Test func promptWithBasicContainsSimpleDirective() {
        let service = makeService()
        let prompt = BonjourServicePromptBuilder.buildPrompt(
            service: service,
            expertiseLevel: .basic
        )
        #expect(prompt.contains("simple terms"))
        #expect(prompt.contains("Avoid acronyms"))
    }

    @Test func promptWithTechnicalContainsTechnicalDirective() {
        let service = makeService()
        let prompt = BonjourServicePromptBuilder.buildPrompt(
            service: service,
            expertiseLevel: .technical
        )
        #expect(prompt.contains("protocol details"))
        #expect(prompt.contains("RFC references"))
    }

    @Test func expertiseLevelDirectivesDiffer() {
        let beginner = BonjourServicePromptBuilder.expertiseLevelDirective(.basic)
        let technical = BonjourServicePromptBuilder.expertiseLevelDirective(.technical)
        #expect(beginner != technical)
    }

    @Test func expertiseLevelHasTwoCases() {
        let allCases = BonjourServicePromptBuilder.ExpertiseLevel.allCases
        #expect(allCases.count == 2)
        #expect(allCases.contains(.basic))
        #expect(allCases.contains(.technical))
    }

    // MARK: - Service Type Prompt

    @Test func serviceTypePromptContainsName() {
        let serviceType = BonjourServiceType(
            name: "AirPlay", type: "airplay", transportLayer: .tcp
        )
        let prompt = BonjourServicePromptBuilder.buildPrompt(serviceType: serviceType)
        #expect(prompt.contains("Service name: AirPlay"))
    }

    @Test func serviceTypePromptContainsFullType() {
        let serviceType = BonjourServiceType(
            name: "AirPlay", type: "airplay", transportLayer: .tcp
        )
        let prompt = BonjourServicePromptBuilder.buildPrompt(serviceType: serviceType)
        #expect(prompt.contains("Full type: _airplay._tcp"))
    }

    @Test func serviceTypePromptContainsTransportLayer() {
        let serviceType = BonjourServiceType(
            name: "DNS", type: "dns", transportLayer: .udp
        )
        let prompt = BonjourServicePromptBuilder.buildPrompt(serviceType: serviceType)
        #expect(prompt.contains("Transport layer: UDP"))
    }

    @Test func serviceTypePromptContainsDescription() {
        let serviceType = BonjourServiceType(
            name: "HTTP", type: "http", transportLayer: .tcp, detail: "Web server"
        )
        let prompt = BonjourServicePromptBuilder.buildPrompt(serviceType: serviceType)
        #expect(prompt.contains("Protocol description: Web server"))
    }

    @Test func serviceTypePromptOmitsDescriptionWhenNil() {
        let serviceType = BonjourServiceType(
            name: "HTTP", type: "http", transportLayer: .tcp, detail: nil
        )
        let prompt = BonjourServicePromptBuilder.buildPrompt(serviceType: serviceType)
        #expect(!prompt.contains("Protocol description:"))
    }

    @Test func serviceTypePromptOmitsHostAndAddresses() {
        let serviceType = BonjourServiceType(
            name: "HTTP", type: "http", transportLayer: .tcp
        )
        let prompt = BonjourServicePromptBuilder.buildPrompt(serviceType: serviceType)
        #expect(!prompt.contains("Host name:"))
        #expect(!prompt.contains("IP addresses:"))
        #expect(!prompt.contains("Device advertising"))
    }

    @Test func serviceTypePromptAsksAboutDeviceTypes() {
        let serviceType = BonjourServiceType(
            name: "HTTP", type: "http", transportLayer: .tcp
        )
        let prompt = BonjourServicePromptBuilder.buildPrompt(serviceType: serviceType)
        #expect(prompt.contains("what kinds of devices typically use it"))
    }
}
