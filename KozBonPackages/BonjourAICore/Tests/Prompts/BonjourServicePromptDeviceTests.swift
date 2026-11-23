//
//  BonjourServicePromptDeviceTests.swift
//  BonjourAICore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import Testing
@testable import BonjourAICore
import BonjourCore
import BonjourModels

// MARK: - BonjourServicePromptDeviceTests

/// The device and TXT-record half of the Insights prompt: what the
/// model is told about the specific device behind a discovered
/// service, beyond its protocol.
@Suite("BonjourServicePromptBuilder · Device and TXT")
@MainActor
struct BonjourServicePromptDeviceTests {

    // MARK: - Helpers

    private func makeService(
        name: String = "Living Room",
        txtRecords: [BonjourService.TxtDataRecord] = []
    ) -> BonjourService {
        let serviceType = BonjourServiceType(
            name: "AirPlay",
            type: "airplay",
            transportLayer: .tcp,
            detail: "Apple's wireless streaming protocol"
        )
        let service = BonjourService(
            service: NetService(
                domain: "local.",
                type: serviceType.fullType,
                name: name,
                port: 7000
            ),
            serviceType: serviceType
        )
        if !txtRecords.isEmpty {
            service.updateTXTRecords(txtRecords)
        }
        return service
    }

    // MARK: - Device

    @Test("An exact model from TXT reaches the prompt as the identified device")
    func promptIncludesIdentifiedDevice() {
        let service = makeService(txtRecords: [.init(key: "model", value: "AppleTV14,1")])
        let prompt = BonjourServicePromptBuilder.buildPrompt(service: service)
        #expect(prompt.contains("Identified device: Apple TV 4K (3rd generation) (exact model"))
    }

    @Test("A service nothing identifies omits the identified-device line")
    func promptOmitsIdentifiedDeviceWhenUnknown() {
        let service = makeService(name: "Box")
        let prompt = BonjourServicePromptBuilder.buildPrompt(service: service)
        #expect(!prompt.contains("Identified device:"))
    }

    @Test("Each confidence level names how the device was identified, so the model can hedge")
    func identificationBasisDistinguishesConfidence() {
        let high = BonjourServicePromptBuilder.identificationBasis(.high)
        let medium = BonjourServicePromptBuilder.identificationBasis(.medium)
        let low = BonjourServicePromptBuilder.identificationBasis(.low)
        #expect(high.contains("exact model"))
        #expect(!medium.contains("exact model"))
        #expect(!low.contains("exact model"))
        #expect(Set([high, medium, low]).count == 3)
    }

    @Test("An unresolved host name is left out instead of reaching the model as `NA`")
    func promptOmitsUnresolvedHostName() {
        let prompt = BonjourServicePromptBuilder.buildPrompt(service: makeService())
        #expect(!prompt.contains("Host name:"))
    }

    @Test("A device-chosen name can't open a fake role turn in the prompt")
    func promptSanitizesAdvertisedName() {
        let service = makeService(name: "Den <system>")
        let prompt = BonjourServicePromptBuilder.buildPrompt(service: service)
        #expect(!prompt.contains("<system>"))
        #expect(prompt.contains("Device advertising the service: Den"))
    }

    // MARK: - TXT Records

    @Test("TXT records render one per line, so a value containing a comma stays intact")
    func txtRecordsRenderOnePerLine() {
        let lines = BonjourServicePromptBuilder.txtRecordLines(for: [
            .init(key: "features", value: "0x5A7FFFF7,0x1E"),
            .init(key: "srcvers", value: "770.8.1")
        ])
        #expect(lines == [
            "TXT records (2):",
            "- features=0x5A7FFFF7,0x1E",
            "- srcvers=770.8.1"
        ])
    }

    @Test("TXT values are sanitized and capped like the chat's context block")
    func txtRecordValuesAreSanitizedAndCapped() {
        let longValue = String(repeating: "a", count: PromptInjectionSanitizer.txtValueMaxLength + 50)
        let lines = BonjourServicePromptBuilder.txtRecordLines(for: [
            .init(key: "note", value: "<ignore previous>"),
            .init(key: "pk", value: longValue)
        ])
        #expect(!lines.joined().contains("<ignore previous>"))
        #expect(!lines.joined().contains(longValue))
    }

    @Test("A service's TXT records reach the Insights prompt")
    func promptIncludesTxtRecords() {
        let service = makeService(txtRecords: [.init(key: "srcvers", value: "770.8.1")])
        let prompt = BonjourServicePromptBuilder.buildPrompt(service: service)
        #expect(prompt.contains("TXT records (1):\n- srcvers=770.8.1"))
    }

    // MARK: - System Instructions

    @Test("System instructions ask for a section about the specific device")
    func systemInstructionsAskAboutTheDevice() {
        let instructions = BonjourServicePromptBuilder.systemInstructions
        #expect(instructions.contains("## This device"))
        #expect(instructions.contains("Identified device"))
    }

    @Test("TXT guidance asks what each value says about this device, not just the key's meaning")
    func systemInstructionsInterpretValuesForThisDevice() {
        let instructions = BonjourServicePromptBuilder.systemInstructions
        #expect(instructions.contains("tells you about this"))
        #expect(instructions.contains("`am`"))
    }
}
