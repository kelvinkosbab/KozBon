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
// swiftlint:disable:next type_body_length
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

    // MARK: - isPublished

    @Test func promptForDiscoveredServiceMentionsDiscovered() {
        let service = makeService()
        let prompt = BonjourServicePromptBuilder.buildPrompt(service: service, isPublished: false)
        #expect(prompt.contains("discovered"))
    }

    @Test func promptForPublishedServiceMentionsBroadcasting() {
        let service = makeService()
        let prompt = BonjourServicePromptBuilder.buildPrompt(service: service, isPublished: true)
        #expect(prompt.contains("broadcasting"))
    }

    @Test func promptDefaultsToDiscovered() {
        let service = makeService()
        let prompt = BonjourServicePromptBuilder.buildPrompt(service: service)
        #expect(prompt.contains("discovered"))
        #expect(!prompt.contains("broadcasting"))
    }

    // MARK: - Structured Output

    @Test func systemInstructionsContainsStructuredSections() {
        let instructions = BonjourServicePromptBuilder.systemInstructions
        #expect(instructions.contains("## What it does"))
        #expect(instructions.contains("## Why it's running"))
        #expect(instructions.contains("## How to interact"))
        #expect(instructions.contains("## Configuration details"))
    }

    @Test func systemInstructionsStartsWithLanguageDirective() {
        let instructions = BonjourServicePromptBuilder.systemInstructions
        #expect(instructions.hasPrefix("TOP PRIORITY: Respond in"))
    }

    @Test func systemInstructionsHasAccuracyRules() {
        let instructions = BonjourServicePromptBuilder.systemInstructions
        #expect(instructions.contains("ACCURACY RULES"))
        #expect(instructions.contains("Never invent port numbers"))
    }

    @Test func systemInstructionsHasTXTRecordGuardrail() {
        let instructions = BonjourServicePromptBuilder.systemInstructions
        #expect(instructions.contains("Vendor-specific"))
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
        #expect(prompt.contains("curious friend"))
        #expect(prompt.contains("analogies"))
    }

    @Test func promptWithTechnicalContainsTechnicalDirective() {
        let service = makeService()
        let prompt = BonjourServicePromptBuilder.buildPrompt(
            service: service,
            expertiseLevel: .technical
        )
        #expect(prompt.contains("developer or sysadmin"))
        #expect(prompt.contains("RFC"))
    }

    @Test func expertiseLevelDirectivesDiffer() {
        let beginner = BonjourServicePromptBuilder.expertiseLevelDirective(.basic)
        let technical = BonjourServicePromptBuilder.expertiseLevelDirective(.technical)
        #expect(beginner != technical)
    }

    // MARK: - Response Length

    @Test func responseLengthHasThreeCases() {
        let allCases = BonjourServicePromptBuilder.ResponseLength.allCases
        #expect(allCases.count == 3)
        #expect(allCases.contains(.brief))
        #expect(allCases.contains(.standard))
        #expect(allCases.contains(.thorough))
    }

    @Test func responseLengthDirectivesDiffer() {
        let brief = BonjourServicePromptBuilder.responseLengthDirective(.brief)
        let standard = BonjourServicePromptBuilder.responseLengthDirective(.standard)
        let thorough = BonjourServicePromptBuilder.responseLengthDirective(.thorough)
        #expect(brief != standard)
        #expect(standard != thorough)
        #expect(brief != thorough)
    }

    @Test func briefDirectiveMentionsConcise() {
        let directive = BonjourServicePromptBuilder.responseLengthDirective(.brief)
        #expect(directive.contains("concise") || directive.contains("1-2 sentences"))
    }

    @Test func thoroughDirectiveMentionsComprehensive() {
        let directive = BonjourServicePromptBuilder.responseLengthDirective(.thorough)
        #expect(directive.contains("comprehensive") || directive.contains("4-6 sentences"))
    }

    @Test func promptWithBriefLengthIncludesBriefDirective() {
        let service = makeService()
        let prompt = BonjourServicePromptBuilder.buildPrompt(
            service: service,
            responseLength: .brief
        )
        let directive = BonjourServicePromptBuilder.responseLengthDirective(.brief)
        #expect(prompt.contains(directive))
    }

    @Test func promptDefaultResponseLengthIsStandard() {
        let service = makeService()
        let prompt = BonjourServicePromptBuilder.buildPrompt(service: service)
        let directive = BonjourServicePromptBuilder.responseLengthDirective(.standard)
        #expect(prompt.contains(directive))
    }

    @Test func responseLengthRawValuesAreStable() {
        #expect(BonjourServicePromptBuilder.ResponseLength.brief.rawValue == "brief")
        #expect(BonjourServicePromptBuilder.ResponseLength.standard.rawValue == "standard")
        #expect(BonjourServicePromptBuilder.ResponseLength.thorough.rawValue == "thorough")
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
        #expect(prompt.contains("what devices commonly use it"))
    }

    @Test func serviceTypePromptDoesNotAssumeRunning() {
        let serviceType = BonjourServiceType(
            name: "HTTP", type: "http", transportLayer: .tcp
        )
        let prompt = BonjourServicePromptBuilder.buildPrompt(serviceType: serviceType)
        #expect(prompt.contains("Do not assume this service is currently running"))
    }

    @Test func serviceTypeSystemInstructionsDoNotAssumeDiscovered() {
        let instructions = BonjourServicePromptBuilder.serviceTypeSystemInstructions
        #expect(instructions.contains("Do NOT assume"))
        #expect(instructions.contains("browsing a library"))
    }

    @Test func serviceTypeSystemInstructionsStartsWithLanguageDirective() {
        let instructions = BonjourServicePromptBuilder.serviceTypeSystemInstructions
        #expect(instructions.hasPrefix("TOP PRIORITY: Respond in"))
    }

    @Test func serviceTypeSystemInstructionsHasAccuracyRules() {
        let instructions = BonjourServicePromptBuilder.serviceTypeSystemInstructions
        #expect(instructions.contains("ACCURACY RULES"))
    }

    @Test func serviceTypePromptDefaultsToBasicLevel() {
        let serviceType = BonjourServiceType(
            name: "HTTP", type: "http", transportLayer: .tcp
        )
        let prompt = BonjourServicePromptBuilder.buildPrompt(serviceType: serviceType)
        let basicDirective = BonjourServicePromptBuilder.expertiseLevelDirective(.basic)
        #expect(prompt.contains(basicDirective))
    }

    @Test func serviceTypePromptWithTechnicalLevel() {
        let serviceType = BonjourServiceType(
            name: "HTTP", type: "http", transportLayer: .tcp
        )
        let prompt = BonjourServicePromptBuilder.buildPrompt(
            serviceType: serviceType,
            expertiseLevel: .technical
        )
        let technicalDirective = BonjourServicePromptBuilder.expertiseLevelDirective(.technical)
        #expect(prompt.contains(technicalDirective))
    }

    @Test func serviceTypePromptContainsLanguageRequest() {
        let serviceType = BonjourServiceType(
            name: "HTTP", type: "http", transportLayer: .tcp
        )
        let prompt = BonjourServicePromptBuilder.buildPrompt(serviceType: serviceType)
        let languageName = BonjourServicePromptBuilder.preferredLanguageName
        #expect(prompt.contains("Please respond in \(languageName)."))
    }

    @Test func serviceTypePromptOmitsDeviceContext() {
        let serviceType = BonjourServiceType(
            name: "HTTP", type: "http", transportLayer: .tcp
        )
        let prompt = BonjourServicePromptBuilder.buildPrompt(serviceType: serviceType)
        #expect(!prompt.contains("I am using"))
    }

    // MARK: - ExpertiseLevel Raw Values

    @Test func basicRawValueIsBasic() {
        #expect(BonjourServicePromptBuilder.ExpertiseLevel.basic.rawValue == "basic")
    }

    @Test func technicalRawValueIsTechnical() {
        #expect(BonjourServicePromptBuilder.ExpertiseLevel.technical.rawValue == "technical")
    }

    @Test func expertiseLevelRoundTripsFromRawValue() {
        for level in BonjourServicePromptBuilder.ExpertiseLevel.allCases {
            let roundTripped = BonjourServicePromptBuilder.ExpertiseLevel(rawValue: level.rawValue)
            #expect(roundTripped == level)
        }
    }
}
