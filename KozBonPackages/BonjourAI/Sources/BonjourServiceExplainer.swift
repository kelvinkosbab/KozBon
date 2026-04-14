//
//  BonjourServiceExplainer.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourCore
import BonjourModels

#if canImport(FoundationModels)
import FoundationModels

// MARK: - BonjourServiceExplainer

/// Uses Apple's on-device FoundationModels to explain Bonjour services to users.
///
/// Provides context-aware explanations by analyzing the service's hostname,
/// IP addresses, transport layer, TXT records, and protocol description.
@available(iOS 26, macOS 26, visionOS 26, *)
@MainActor
@Observable
public final class BonjourServiceExplainer: BonjourServiceExplainerProtocol {

    // MARK: - Properties

    /// The streamed explanation text, updated as tokens arrive.
    public var explanation: String = ""

    /// Whether the model is currently generating a response.
    public var isGenerating: Bool = false

    /// An error message if generation fails.
    public var error: String?

    /// Whether the on-device language model is available.
    public var isAvailable: Bool {
        SystemLanguageModel.default.isAvailable
    }

    /// The desired level of technical detail in the explanation.
    public var expertiseLevel: BonjourServicePromptBuilder.ExpertiseLevel = .basic

    private var session: LanguageModelSession?

    // MARK: - Init

    public init() {}

    // MARK: - Explain

    /// Generates a streaming explanation of the given Bonjour service.
    ///
    /// - Parameter service: The discovered Bonjour service to explain.
    public func explain(service: BonjourService, isPublished: Bool = false) async {
        explanation = ""
        error = nil
        isGenerating = true

        let prompt = BonjourServicePromptBuilder.buildPrompt(
            service: service,
            isPublished: isPublished,
            expertiseLevel: expertiseLevel
        )

        do {
            let session = LanguageModelSession(
                instructions: BonjourServicePromptBuilder.systemInstructions
            )
            self.session = session

            let stream = session.streamResponse(to: prompt)
            for try await partial in stream {
                explanation = partial.content
            }
        } catch {
            self.error = error.localizedDescription
        }

        isGenerating = false
    }

    /// Generates a streaming explanation of the given Bonjour service type.
    ///
    /// - Parameter serviceType: The service type to explain.
    public func explain(serviceType: BonjourServiceType) async {
        explanation = ""
        error = nil
        isGenerating = true

        let prompt = BonjourServicePromptBuilder.buildPrompt(
            serviceType: serviceType,
            expertiseLevel: expertiseLevel
        )

        do {
            let session = LanguageModelSession(
                instructions: BonjourServicePromptBuilder.serviceTypeSystemInstructions
            )
            self.session = session

            let stream = session.streamResponse(to: prompt)
            for try await partial in stream {
                explanation = partial.content
            }
        } catch {
            self.error = error.localizedDescription
        }

        isGenerating = false
    }
}

#endif
