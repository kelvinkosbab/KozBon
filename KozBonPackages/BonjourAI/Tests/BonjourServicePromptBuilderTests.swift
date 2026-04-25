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

/// Per-service prompt building (Insights long-press flow): system
/// instructions, language/device context, and prompt-shape invariants.
///
/// Expertise/ResponseLength tests live in
/// `BonjourServicePromptExpertiseTests`. Service-type-only prompt
/// tests live in `BonjourServiceTypePromptBuilderTests`. The split keeps
/// each suite under SwiftLint's `type_body_length` and `file_length`
/// thresholds so neither needs an inline disable.
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

    @Test("`systemInstructions` is non-empty so the model never sees a blank system prompt")
    func systemInstructionsIsNotEmpty() {
        #expect(!BonjourServicePromptBuilder.systemInstructions.isEmpty)
    }

    @Test("System instructions name Bonjour and mDNS to scope the assistant's domain")
    func systemInstructionsContainsBonjourContext() {
        let instructions = BonjourServicePromptBuilder.systemInstructions
        #expect(instructions.contains("Bonjour"))
        #expect(instructions.contains("mDNS"))
    }

    @Test("Single TOP-PRIORITY language directive is the sole source of truth (duplicate tail removed)")
    func systemInstructionsContainsLanguageDirective() {
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

    @Test("`preferredLanguageName` is non-empty so language directive interpolation never blanks out")
    func preferredLanguageNameIsNotEmpty() {
        #expect(!BonjourServicePromptBuilder.preferredLanguageName.isEmpty)
    }

    @Test("`preferredLanguageName` returns a display name (e.g. `English`), not a 2-letter code")
    func preferredLanguageNameIsHumanReadable() {
        let name = BonjourServicePromptBuilder.preferredLanguageName
        // Should be a display name like "English", "Español", etc., not a code like "en"
        #expect(name.count > 2)
    }

    // MARK: - Device Context

    @Test("`deviceContext` is non-empty so the prompt always carries the reader's device family")
    func deviceContextIsNotEmpty() {
        #expect(!BonjourServicePromptBuilder.deviceContext.isEmpty)
    }

    @Test("`currentDeviceShortName` is non-empty so prompt interpolation never produces `from my .`")
    func currentDeviceShortNameIsNotEmpty() {
        #expect(!BonjourServicePromptBuilder.currentDeviceShortName.isEmpty)
    }

    // MARK: - Prompt Building

    @Test("Prompt emits the service display name on a labeled line for the model to quote back")
    func promptContainsServiceName() {
        let service = makeService(typeName: "HTTP")
        let prompt = BonjourServicePromptBuilder.buildPrompt(service: service)
        #expect(prompt.contains("Service name: HTTP"))
    }

    @Test("Prompt emits the full `_type._transport` form so the model can reason about subtypes")
    func promptContainsFullType() {
        let service = makeService(type: "http")
        let prompt = BonjourServicePromptBuilder.buildPrompt(service: service)
        #expect(prompt.contains("Full type: _http._tcp"))
    }

    @Test("TCP services render `Transport layer: TCP` for protocols that exist on both transports")
    func promptContainsTransportLayer() {
        let service = makeService(transportLayer: .tcp)
        let prompt = BonjourServicePromptBuilder.buildPrompt(service: service)
        #expect(prompt.contains("Transport layer: TCP"))
    }

    @Test("UDP services render `Transport layer: UDP` for protocols that exist on both transports")
    func promptContainsUDPTransportLayer() {
        let service = makeService(transportLayer: .udp)
        let prompt = BonjourServicePromptBuilder.buildPrompt(service: service)
        #expect(prompt.contains("Transport layer: UDP"))
    }

    @Test("Prompt names the advertising device so the model can reference the user's actual setup")
    func promptContainsDeviceName() {
        let service = makeService(name: "Living Room Apple TV")
        let prompt = BonjourServicePromptBuilder.buildPrompt(service: service)
        #expect(prompt.contains("Device advertising the service: Living Room Apple TV"))
    }

    @Test("Prompt includes the domain (`local.`) so the model can distinguish link-local from WAN")
    func promptContainsDomain() {
        let service = makeService()
        let prompt = BonjourServicePromptBuilder.buildPrompt(service: service)
        #expect(prompt.contains("Domain: local."))
    }

    @Test("Localized protocol description is emitted on a labeled line for the model to defer to")
    func promptContainsProtocolDescription() {
        let service = makeService(detail: "Web server protocol")
        let prompt = BonjourServicePromptBuilder.buildPrompt(service: service)
        #expect(prompt.contains("Protocol description: Web server protocol"))
    }

    @Test("Nil protocol detail omits the line entirely so the model isn't fed an empty placeholder")
    func promptOmitsProtocolDescriptionWhenNil() {
        let service = makeService(detail: nil)
        let prompt = BonjourServicePromptBuilder.buildPrompt(service: service)
        #expect(!prompt.contains("Protocol description:"))
    }

    @Test("Prompt includes the full `deviceContext` blurb so the model tailors instructions to the device")
    func promptContainsDeviceContext() {
        let service = makeService()
        let prompt = BonjourServicePromptBuilder.buildPrompt(service: service)
        #expect(prompt.contains(BonjourServicePromptBuilder.deviceContext))
    }

    @Test("Prompt asks `how can I use it from my <device>?` to anchor the answer to the reader")
    func promptContainsInteractionQuestion() {
        let service = makeService()
        let prompt = BonjourServicePromptBuilder.buildPrompt(service: service)
        let deviceName = BonjourServicePromptBuilder.currentDeviceShortName
        #expect(prompt.contains("how can I use it from my \(deviceName)?"))
    }

    @Test("Prompt repeats the `Please respond in <lang>` directive at the tail to reinforce language")
    func promptContainsLanguageRequest() {
        let service = makeService()
        let prompt = BonjourServicePromptBuilder.buildPrompt(service: service)
        let languageName = BonjourServicePromptBuilder.preferredLanguageName
        #expect(prompt.contains("Please respond in \(languageName)."))
    }

    @Test("Empty IP-address list omits the `IP addresses:` line entirely (no empty placeholder)")
    func promptOmitsAddressesWhenEmpty() {
        let service = makeService()
        let prompt = BonjourServicePromptBuilder.buildPrompt(service: service)
        #expect(!prompt.contains("IP addresses:"))
    }

    @Test("Empty TXT record dictionary omits the `TXT records:` line entirely")
    func promptOmitsTxtRecordsWhenEmpty() {
        let service = makeService()
        let prompt = BonjourServicePromptBuilder.buildPrompt(service: service)
        #expect(!prompt.contains("TXT records:"))
    }

    // MARK: - isPublished

    @Test("`isPublished: false` frames the service as `discovered` from the network")
    func promptForDiscoveredServiceMentionsDiscovered() {
        let service = makeService()
        let prompt = BonjourServicePromptBuilder.buildPrompt(service: service, isPublished: false)
        #expect(prompt.contains("discovered"))
    }

    @Test("`isPublished: true` frames the service as the user's own `broadcasting` from this device")
    func promptForPublishedServiceMentionsBroadcasting() {
        let service = makeService()
        let prompt = BonjourServicePromptBuilder.buildPrompt(service: service, isPublished: true)
        #expect(prompt.contains("broadcasting"))
    }

    @Test("Default `isPublished` is false so the discovered framing wins by default")
    func promptDefaultsToDiscovered() {
        let service = makeService()
        let prompt = BonjourServicePromptBuilder.buildPrompt(service: service)
        #expect(prompt.contains("discovered"))
        #expect(!prompt.contains("broadcasting"))
    }

    // MARK: - Structured Output

    @Test("System instructions enforce the four-section markdown template the renderer expects")
    func systemInstructionsContainsStructuredSections() {
        let instructions = BonjourServicePromptBuilder.systemInstructions
        #expect(instructions.contains("## What it does"))
        // Renamed from "Why it's running" to "Why devices advertise this" so
        // the heading anchors the answer to the service type's typical
        // deployment rather than inviting speculation about the user's setup.
        #expect(instructions.contains("## Why devices advertise this"))
        #expect(instructions.contains("## How to interact"))
        #expect(instructions.contains("## Configuration details"))
    }

    @Test("Language directive is the first line so it survives mid-prompt context truncation")
    func systemInstructionsStartsWithLanguageDirective() {
        let instructions = BonjourServicePromptBuilder.systemInstructions
        #expect(instructions.hasPrefix("TOP PRIORITY: Respond in"))
    }

    @Test("System instructions ship an `ACCURACY RULES` block forbidding invented port numbers")
    func systemInstructionsHasAccuracyRules() {
        let instructions = BonjourServicePromptBuilder.systemInstructions
        #expect(instructions.contains("ACCURACY RULES"))
        #expect(instructions.contains("Never invent port numbers"))
    }

    @Test("TXT-record guardrail pairs verbatim pass-through with an allowlist of documented keys")
    func systemInstructionsHasTXTRecordGuardrail() {
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

    // MARK: - Prompt Quality Invariants
    //
    // These tests pin specific guardrails introduced in the prompt audit.
    // They're intentionally narrow — each asserts one behavior users would
    // feel if it regressed, so a failure points at a specific missing
    // rule rather than "the prompt string changed".

    @Test("System instructions force the first emitted character to be `#` so streaming feels instant")
    func systemInstructionsForbidConversationalPreamble() {
        // Users see tokens stream as they generate. A "Sure, here's..."
        // preamble means the user waits an extra beat before useful
        // content arrives. The rule must stay explicit.
        let instructions = BonjourServicePromptBuilder.systemInstructions
        #expect(instructions.contains("first character you emit must be `#`"))
    }

    @Test("System instructions pin second-person voice (`you`) for warmer, more direct tone")
    func systemInstructionsDirectUserVoice() {
        // Second-person ("you") reads warmer than third-person ("the
        // user"). The rule also requires active voice to avoid
        // awkward "this service can be used" phrasings.
        let instructions = BonjourServicePromptBuilder.systemInstructions
        #expect(instructions.contains("Address the user as \"you\""))
    }

    @Test("System instructions show a worked example (`_airplay._tcp`) so the model mimics inline-code style")
    func systemInstructionsInlineCodeFormatting() {
        // Protocol names and port numbers must render as inline code in
        // the output. The example in the rule itself demonstrates the
        // pattern so the model has a concrete template to mimic.
        let instructions = BonjourServicePromptBuilder.systemInstructions
        #expect(instructions.contains("Wrap protocol names"))
        #expect(instructions.contains("`_airplay._tcp`"))
    }

    @Test("System instructions ship named hedge prefixes so uncertainty reads consistently")
    func systemInstructionsUncertaintyPhrasingRule() {
        // Named prefixes ("Likely:", "This typically means:") give the
        // model a stable way to hedge instead of confabulating.
        let instructions = BonjourServicePromptBuilder.systemInstructions
        #expect(instructions.contains("Likely:"))
        #expect(instructions.contains("This typically means:"))
    }

    @Test("System instructions pin a source-priority order so TXT records and detail copy never conflict silently")
    func systemInstructionsSourcePriorityHierarchy() {
        // Resolves conflicts between TXT records, "Protocol description",
        // and model training by pinning an explicit priority order.
        let instructions = BonjourServicePromptBuilder.systemInstructions
        #expect(instructions.contains("Source priority when they conflict"))
        #expect(instructions.contains("Never contradict the \"Protocol description\""))
    }

    @Test("System instructions call out undocumented Apple-internal types so the model hedges instead of inventing")
    func systemInstructionsHandleAppleInternalServices() {
        // Services like `_companion-link._tcp` are undocumented. The
        // model must acknowledge the uncertainty instead of inventing
        // plausible-sounding but wrong details.
        let instructions = BonjourServicePromptBuilder.systemInstructions
        #expect(instructions.contains("apple-mobdev"))
        #expect(instructions.contains("companion-link"))
        #expect(instructions.contains("undocumented"))
    }

    @Test("`How to interact` section is anchored to the reader's specific device, not generic guidance")
    func howToInteractSectionTargetsUserDevice() {
        // The explanation must be specific to the reader's device, not
        // generic — otherwise `deviceContext` is wasted context.
        let instructions = BonjourServicePromptBuilder.systemInstructions
        #expect(instructions.contains("your specific device"))
    }
}
