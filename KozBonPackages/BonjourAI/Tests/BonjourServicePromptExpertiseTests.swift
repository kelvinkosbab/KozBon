//
//  BonjourServicePromptExpertiseTests.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourAI
import BonjourCore
import BonjourModels

// MARK: - BonjourServicePromptExpertiseTests

/// Pin the Expertise/ResponseLength surfaces of the per-service prompt
/// builder. Split out from the main suite so each file stays well under
/// the SwiftLint type/file-length thresholds without disabling them.
@Suite("BonjourServicePromptBuilder · Expertise & Length")
@MainActor
struct BonjourServicePromptExpertiseTests {

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

    // MARK: - Expertise Level

    @Test("`buildPrompt` defaults to the `.basic` expertise directive when no level is passed")
    func promptDefaultsToBasicLevel() {
        let service = makeService()
        let prompt = BonjourServicePromptBuilder.buildPrompt(service: service)
        let beginnerDirective = BonjourServicePromptBuilder.expertiseLevelDirective(.basic)
        #expect(prompt.contains(beginnerDirective))
    }

    @Test("`.basic` directive uses `curious friend` framing and asks for analogies, not jargon")
    func promptWithBasicContainsSimpleDirective() {
        let service = makeService()
        let prompt = BonjourServicePromptBuilder.buildPrompt(
            service: service,
            expertiseLevel: .basic
        )
        #expect(prompt.contains("curious friend"))
        #expect(prompt.contains("analogies"))
    }

    @Test("`.technical` directive targets developers/sysadmins and explicitly forbids RFC citations")
    func promptWithTechnicalContainsTechnicalDirective() {
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

    @Test("Technical directive forbids RFC citations to prevent confidently-wrong hallucinations")
    func expertiseDirectiveTechnicalForbidsRFCCitations() {
        // Pin the anti-hallucination rule: even on a "technical" response,
        // the model must not be asked to cite RFC numbers. This is the
        // single highest-return change from the prompt audit — RFC numbers
        // are where the model fails most confidently.
        let directive = BonjourServicePromptBuilder.expertiseLevelDirective(.technical)
        #expect(directive.contains("Do NOT cite RFC"))
    }

    @Test("Basic and technical directives are distinct strings — settings change must produce visible differences")
    func expertiseLevelDirectivesDiffer() {
        let beginner = BonjourServicePromptBuilder.expertiseLevelDirective(.basic)
        let technical = BonjourServicePromptBuilder.expertiseLevelDirective(.technical)
        #expect(beginner != technical)
    }

    // MARK: - Response Length

    @Test("`ResponseLength` enumerates exactly three cases (`brief`, `standard`, `thorough`)")
    func responseLengthHasThreeCases() {
        let allCases = BonjourServicePromptBuilder.ResponseLength.allCases
        #expect(allCases.count == 3)
        #expect(allCases.contains(.brief))
        #expect(allCases.contains(.standard))
        #expect(allCases.contains(.thorough))
    }

    @Test("All three response-length directives are pairwise distinct so settings produce visible differences")
    func responseLengthDirectivesDiffer() {
        let brief = BonjourServicePromptBuilder.responseLengthDirective(.brief)
        let standard = BonjourServicePromptBuilder.responseLengthDirective(.standard)
        let thorough = BonjourServicePromptBuilder.responseLengthDirective(.thorough)
        #expect(brief != standard)
        #expect(standard != thorough)
        #expect(brief != thorough)
    }

    @Test("`.brief` directive bypasses the section template and forces a single heading-less paragraph")
    func briefDirectiveProducesSingleParagraph() {
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

    @Test("`.thorough` directive asks for `comprehensive` length or a 4–6 sentence shape")
    func thoroughDirectiveMentionsComprehensive() {
        let directive = BonjourServicePromptBuilder.responseLengthDirective(.thorough)
        #expect(directive.contains("comprehensive") || directive.contains("4-6 sentences"))
    }

    @Test("`buildPrompt(responseLength: .brief)` injects the brief directive into the prompt")
    func promptWithBriefLengthIncludesBriefDirective() {
        let service = makeService()
        let prompt = BonjourServicePromptBuilder.buildPrompt(
            service: service,
            responseLength: .brief
        )
        let directive = BonjourServicePromptBuilder.responseLengthDirective(.brief)
        #expect(prompt.contains(directive))
    }

    @Test("`buildPrompt` defaults to the `.standard` response-length directive when none is passed")
    func promptDefaultResponseLengthIsStandard() {
        let service = makeService()
        let prompt = BonjourServicePromptBuilder.buildPrompt(service: service)
        let directive = BonjourServicePromptBuilder.responseLengthDirective(.standard)
        #expect(prompt.contains(directive))
    }

    @Test("`ResponseLength` raw values are stable wire strings (persisted in user defaults)")
    func responseLengthRawValuesAreStable() {
        #expect(BonjourServicePromptBuilder.ResponseLength.brief.rawValue == "brief")
        #expect(BonjourServicePromptBuilder.ResponseLength.standard.rawValue == "standard")
        #expect(BonjourServicePromptBuilder.ResponseLength.thorough.rawValue == "thorough")
    }

    @Test("`ExpertiseLevel` enumerates exactly two cases (`basic`, `technical`)")
    func expertiseLevelHasTwoCases() {
        let allCases = BonjourServicePromptBuilder.ExpertiseLevel.allCases
        #expect(allCases.count == 2)
        #expect(allCases.contains(.basic))
        #expect(allCases.contains(.technical))
    }

    // MARK: - ExpertiseLevel Raw Values

    @Test("`ExpertiseLevel.basic` raw value is the stable wire string `basic`")
    func basicRawValueIsBasic() {
        #expect(BonjourServicePromptBuilder.ExpertiseLevel.basic.rawValue == "basic")
    }

    @Test("`ExpertiseLevel.technical` raw value is the stable wire string `technical`")
    func technicalRawValueIsTechnical() {
        #expect(BonjourServicePromptBuilder.ExpertiseLevel.technical.rawValue == "technical")
    }

    @Test("Every `ExpertiseLevel` round-trips through its raw value so persistence stays lossless")
    func expertiseLevelRoundTripsFromRawValue() {
        for level in BonjourServicePromptBuilder.ExpertiseLevel.allCases {
            let roundTripped = BonjourServicePromptBuilder.ExpertiseLevel(rawValue: level.rawValue)
            #expect(roundTripped == level)
        }
    }

    // MARK: - ExpertiseLevel → ResponseLength Mapping
    //
    // The standalone "Response length" preference was removed from the
    // Preferences UI; both the Insights long-press and the Chat surface
    // derive their response length from the user's Detail level
    // selection. These tests pin the mapping so the two settings stay
    // meaningfully different — losing the mapping would silently
    // collapse Basic and Technical to the same shape of response.

    @Test("`.basic` expertise maps to `.standard` length so non-technical users get a friendly mid-length answer")
    func basicExpertiseMapsToStandardLength() {
        // Basic readers want a friendly, medium-length explanation —
        // long enough to cover the topic, short enough not to wall-of-
        // text a non-technical user.
        #expect(BonjourServicePromptBuilder.ExpertiseLevel.basic.responseLength == .standard)
    }

    @Test("`.technical` expertise maps to `.thorough` length so depth-seekers get the longer, example-rich shape")
    func technicalExpertiseMapsToThoroughLength() {
        // Technical readers asked for depth in their Detail level
        // selection — so the response should also use the longer,
        // example-rich `.thorough` shape rather than collapsing to
        // standard.
        #expect(BonjourServicePromptBuilder.ExpertiseLevel.technical.responseLength == .thorough)
    }

    @Test("Expertise→length mappings are pairwise distinct so the Detail-level setting stays meaningful")
    func expertiseLevelMappingsAreDistinct() {
        // If both Basic and Technical mapped to the same length, the
        // single Detail level setting would lose a real axis of
        // differentiation — vocabulary alone, with identical length,
        // is too subtle. Pin the contract that the two levels produce
        // different lengths.
        let basic = BonjourServicePromptBuilder.ExpertiseLevel.basic.responseLength
        let technical = BonjourServicePromptBuilder.ExpertiseLevel.technical.responseLength
        #expect(basic != technical)
    }
}
