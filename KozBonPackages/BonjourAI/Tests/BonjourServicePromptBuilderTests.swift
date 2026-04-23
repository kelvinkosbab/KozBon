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

// swiftlint:disable file_length
// The file intentionally holds one narrowly-scoped assertion per prompt
// invariant — each `@Test` catches a specific regression (e.g. "the RFC
// citation ban was removed", "the source-priority hierarchy disappeared").
// Splitting across multiple files would scatter related invariants and
// make it harder to see the full prompt contract at a glance. The
// `type_body_length` suite disable below extends the same rationale to
// the struct body.

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
        // The prompt audit removed the duplicated "IMPORTANT: Always
        // respond in X" tail — modern models follow the top-level
        // directive reliably, and the duplicate was burning tokens
        // without improving reliability. We pin the TOP PRIORITY form
        // (uppercase `Respond`) as the sole source of truth.
        let instructions = BonjourServicePromptBuilder.systemInstructions
        let languageName = BonjourServicePromptBuilder.preferredLanguageName
        #expect(instructions.contains("TOP PRIORITY: Respond in \(languageName)"))
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
        #expect(prompt.contains("how can I use it from my \(deviceName)?"))
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
        // Renamed from "Why it's running" to "Why devices advertise this" so
        // the heading anchors the answer to the service type's typical
        // deployment rather than inviting speculation about the user's setup.
        #expect(instructions.contains("## Why devices advertise this"))
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
        // Rule replaced the "Vendor-specific" label with a verbatim
        // pass-through ("The device advertises `<key>=<value>`.") plus a
        // concrete allowlist of documented keys the model may interpret.
        // Both halves of the guardrail must be present — the allowlist
        // bounds what the model speculates on, the pass-through bounds
        // what it does when it can't.
        #expect(instructions.contains("The device advertises"))
        #expect(instructions.contains("`txtvers`"))
        #expect(instructions.contains("`rmodel`"))
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
        // RFC citations are now explicitly forbidden — the previous
        // "cite if you're certain" wording produced confident-wrong
        // hallucinations. Any future RFC references need to come from a
        // curated lookup, not the model's memory.
        #expect(prompt.contains("Do NOT cite RFC numbers"))
    }

    @Test func expertiseDirectiveTechnicalForbidsRFCCitations() {
        // Pin the anti-hallucination rule: even on a "technical" response,
        // the model must not be asked to cite RFC numbers. This is the
        // single highest-return change from the prompt audit — RFC numbers
        // are where the model fails most confidently.
        let directive = BonjourServicePromptBuilder.expertiseLevelDirective(.technical)
        #expect(directive.contains("Do NOT cite RFC"))
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

    @Test func briefDirectiveProducesSingleParagraph() {
        // `.brief` used to shrink the sectioned template into 3 sentences
        // total, which made the model drop sections inconsistently. The
        // new directive explicitly bypasses the section template and
        // asks for a single paragraph — giving the three length settings
        // genuinely distinct structural shapes. Both invariants matter:
        // (1) the paragraph framing, (2) the explicit "no headings" rule.
        let directive = BonjourServicePromptBuilder.responseLengthDirective(.brief)
        #expect(directive.contains("SINGLE paragraph"))
        #expect(directive.contains("DO NOT use Markdown section headings"))
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

    // MARK: - Prompt Quality Invariants
    //
    // These tests pin specific guardrails introduced in the prompt audit.
    // They're intentionally narrow — each asserts one behavior users would
    // feel if it regressed, so a failure points at a specific missing
    // rule rather than "the prompt string changed".

    @Test func systemInstructionsForbidConversationalPreamble() {
        // Users see tokens stream as they generate. A "Sure, here's..."
        // preamble means the user waits an extra beat before useful
        // content arrives. The rule must stay explicit.
        let instructions = BonjourServicePromptBuilder.systemInstructions
        #expect(instructions.contains("first character you emit must be `#`"))
    }

    @Test func systemInstructionsDirectUserVoice() {
        // Second-person ("you") reads warmer than third-person ("the
        // user"). The rule also requires active voice to avoid
        // awkward "this service can be used" phrasings.
        let instructions = BonjourServicePromptBuilder.systemInstructions
        #expect(instructions.contains("Address the user as \"you\""))
    }

    @Test func systemInstructionsInlineCodeFormatting() {
        // Protocol names and port numbers must render as inline code in
        // the output. The example in the rule itself demonstrates the
        // pattern so the model has a concrete template to mimic.
        let instructions = BonjourServicePromptBuilder.systemInstructions
        #expect(instructions.contains("Wrap protocol names"))
        #expect(instructions.contains("`_airplay._tcp`"))
    }

    @Test func systemInstructionsUncertaintyPhrasingRule() {
        // Named prefixes ("Likely:", "This typically means:") give the
        // model a stable way to hedge instead of confabulating.
        let instructions = BonjourServicePromptBuilder.systemInstructions
        #expect(instructions.contains("Likely:"))
        #expect(instructions.contains("This typically means:"))
    }

    @Test func systemInstructionsSourcePriorityHierarchy() {
        // Resolves conflicts between TXT records, "Protocol description",
        // and model training by pinning an explicit priority order.
        let instructions = BonjourServicePromptBuilder.systemInstructions
        #expect(instructions.contains("Source priority when they conflict"))
        #expect(instructions.contains("Never contradict the \"Protocol description\""))
    }

    @Test func systemInstructionsHandleAppleInternalServices() {
        // Services like `_companion-link._tcp` are undocumented. The
        // model must acknowledge the uncertainty instead of inventing
        // plausible-sounding but wrong details.
        let instructions = BonjourServicePromptBuilder.systemInstructions
        #expect(instructions.contains("apple-mobdev"))
        #expect(instructions.contains("companion-link"))
        #expect(instructions.contains("undocumented"))
    }

    @Test func howToInteractSectionTargetsUserDevice() {
        // The explanation must be specific to the reader's device, not
        // generic — otherwise `deviceContext` is wasted context.
        let instructions = BonjourServicePromptBuilder.systemInstructions
        #expect(instructions.contains("your specific device"))
    }
}
