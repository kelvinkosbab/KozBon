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

    @Test("Service-type prompt emits the type's display name on a labeled `Service name:` line")
    func serviceTypePromptContainsName() {
        let serviceType = BonjourServiceType(
            name: "AirPlay", type: "airplay", transportLayer: .tcp
        )
        let prompt = BonjourServicePromptBuilder.buildPrompt(serviceType: serviceType)
        #expect(prompt.contains("Service name: AirPlay"))
    }

    @Test("Service-type prompt emits the full `_type._transport` form for taxonomy clarity")
    func serviceTypePromptContainsFullType() {
        let serviceType = BonjourServiceType(
            name: "AirPlay", type: "airplay", transportLayer: .tcp
        )
        let prompt = BonjourServicePromptBuilder.buildPrompt(serviceType: serviceType)
        #expect(prompt.contains("Full type: _airplay._tcp"))
    }

    @Test("UDP service types render `Transport layer: UDP` so the model can scope behavior correctly")
    func serviceTypePromptContainsTransportLayer() {
        let serviceType = BonjourServiceType(
            name: "DNS", type: "dns", transportLayer: .udp
        )
        let prompt = BonjourServicePromptBuilder.buildPrompt(serviceType: serviceType)
        #expect(prompt.contains("Transport layer: UDP"))
    }

    @Test("Service-type prompt surfaces the localized protocol detail when one is available")
    func serviceTypePromptContainsDescription() {
        let serviceType = BonjourServiceType(
            name: "HTTP", type: "http", transportLayer: .tcp, detail: "Web server"
        )
        let prompt = BonjourServicePromptBuilder.buildPrompt(serviceType: serviceType)
        #expect(prompt.contains("Protocol description: Web server"))
    }

    @Test("Nil protocol detail omits the `Protocol description:` line entirely (no empty placeholder)")
    func serviceTypePromptOmitsDescriptionWhenNil() {
        let serviceType = BonjourServiceType(
            name: "HTTP", type: "http", transportLayer: .tcp, detail: nil
        )
        let prompt = BonjourServicePromptBuilder.buildPrompt(serviceType: serviceType)
        #expect(!prompt.contains("Protocol description:"))
    }

    @Test("Service-type prompt omits per-instance fields (host, addresses, advertising device)")
    func serviceTypePromptOmitsHostAndAddresses() {
        let serviceType = BonjourServiceType(
            name: "HTTP", type: "http", transportLayer: .tcp
        )
        let prompt = BonjourServicePromptBuilder.buildPrompt(serviceType: serviceType)
        #expect(!prompt.contains("Host name:"))
        #expect(!prompt.contains("IP addresses:"))
        #expect(!prompt.contains("Device advertising"))
    }

    @Test("Service-type prompt asks `what devices commonly use it` so the answer covers typical deployments")
    func serviceTypePromptAsksAboutDeviceTypes() {
        let serviceType = BonjourServiceType(
            name: "HTTP", type: "http", transportLayer: .tcp
        )
        let prompt = BonjourServicePromptBuilder.buildPrompt(serviceType: serviceType)
        #expect(prompt.contains("what devices commonly use it"))
    }

    @Test("Service-type prompt explicitly tells the model not to assume the service is currently running")
    func serviceTypePromptDoesNotAssumeRunning() {
        let serviceType = BonjourServiceType(
            name: "HTTP", type: "http", transportLayer: .tcp
        )
        let prompt = BonjourServicePromptBuilder.buildPrompt(serviceType: serviceType)
        #expect(prompt.contains("Do not assume this service is currently running"))
    }

    @Test("Service-type system instructions tell the model the user is browsing a library, not querying a live service")
    func serviceTypeSystemInstructionsDoNotAssumeDiscovered() {
        let instructions = BonjourServicePromptBuilder.serviceTypeSystemInstructions
        #expect(instructions.contains("Do NOT assume"))
        #expect(instructions.contains("browsing a library"))
    }

    @Test("Service-type instructions lead with the language directive so it survives context truncation")
    func serviceTypeSystemInstructionsStartsWithLanguageDirective() {
        let instructions = BonjourServicePromptBuilder.serviceTypeSystemInstructions
        #expect(instructions.hasPrefix("TOP PRIORITY: Respond in"))
    }

    @Test("Service-type instructions ship an `ACCURACY RULES` block to constrain hallucinations")
    func serviceTypeSystemInstructionsHasAccuracyRules() {
        let instructions = BonjourServicePromptBuilder.serviceTypeSystemInstructions
        #expect(instructions.contains("ACCURACY RULES"))
    }

    @Test("`buildPrompt(serviceType:)` defaults to the `.basic` expertise directive when none is passed")
    func serviceTypePromptDefaultsToBasicLevel() {
        let serviceType = BonjourServiceType(
            name: "HTTP", type: "http", transportLayer: .tcp
        )
        let prompt = BonjourServicePromptBuilder.buildPrompt(serviceType: serviceType)
        let basicDirective = BonjourServicePromptBuilder.expertiseLevelDirective(.basic)
        #expect(prompt.contains(basicDirective))
    }

    @Test("Passing `expertiseLevel: .technical` injects the technical directive into the service-type prompt")
    func serviceTypePromptWithTechnicalLevel() {
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

    @Test("Service-type prompt re-emits `Please respond in <lang>` at the tail to reinforce language")
    func serviceTypePromptContainsLanguageRequest() {
        let serviceType = BonjourServiceType(
            name: "HTTP", type: "http", transportLayer: .tcp
        )
        let prompt = BonjourServicePromptBuilder.buildPrompt(serviceType: serviceType)
        let languageName = BonjourServicePromptBuilder.preferredLanguageName
        #expect(prompt.contains("Please respond in \(languageName)."))
    }

    @Test("Service-type prompt omits the `I am using` device blurb — there is no specific device using the type")
    func serviceTypePromptOmitsDeviceContext() {
        let serviceType = BonjourServiceType(
            name: "HTTP", type: "http", transportLayer: .tcp
        )
        let prompt = BonjourServicePromptBuilder.buildPrompt(serviceType: serviceType)
        #expect(!prompt.contains("I am using"))
    }
}
