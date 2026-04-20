//
//  SimulatorBonjourServiceExplainer.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

#if targetEnvironment(simulator)

import Foundation
import BonjourModels

// MARK: - SimulatorBonjourServiceExplainer

/// A simulator-only service explainer that streams random lorem ipsum responses.
///
/// Used on the iOS simulator where `FoundationModels` isn't functional. Lets
/// developers test the "Explain with AI" UI without a real AI device.
@MainActor
@Observable
public final class SimulatorBonjourServiceExplainer: BonjourServiceExplainerProtocol {

    // MARK: - Properties

    public var explanation: String = ""
    public var isGenerating: Bool = false
    public var error: String?
    public var isAvailable: Bool = true
    public var expertiseLevel: BonjourServicePromptBuilder.ExpertiseLevel = .basic

    public init() {}

    // MARK: - Explain

    public func explain(service: BonjourService, isPublished: Bool = false) async {
        await streamRandomResponse()
    }

    public func explain(serviceType: BonjourServiceType) async {
        await streamRandomResponse()
    }

    // MARK: - Streaming

    private func streamRandomResponse() async {
        explanation = ""
        error = nil
        isGenerating = true

        let fullResponse = SimulatorLoremIpsum.randomMarkdownResponse()
        var accumulated = ""

        for word in fullResponse.split(separator: " ", omittingEmptySubsequences: false) {
            if Task.isCancelled { break }
            if !accumulated.isEmpty {
                accumulated += " "
            }
            accumulated += word
            explanation = accumulated
            try? await Task.sleep(nanoseconds: 25_000_000) // 25ms per word
        }

        isGenerating = false
    }
}

#endif
