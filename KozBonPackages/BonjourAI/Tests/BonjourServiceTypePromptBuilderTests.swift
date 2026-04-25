//
//  BonjourServiceTypePromptBuilderTests.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourAI
import BonjourCore
import BonjourModels

// MARK: - BonjourServiceTypePromptBuilderTests

/// Pin the service-type-only prompt surface (Library tab "Explain this
/// type" flow). Split from the main per-service suite so each file stays
/// well under the SwiftLint type/file-length thresholds without disabling
/// them.
@Suite("BonjourServicePromptBuilder · Service Type")
@MainActor
struct BonjourServiceTypePromptBuilderTests {

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
}
