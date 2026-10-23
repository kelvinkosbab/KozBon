//
//  ExplainServiceTypeIntent.swift
//  BonjourAppIntents
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import AppIntents
import Foundation
import BonjourAI
import BonjourLocalization
import BonjourModels
import InternetConnectivity

// MARK: - ExplainServiceTypeIntent

/// Speaks a short Insights explanation of a service type, using the
/// AI backend selected in Settings.
public struct ExplainServiceTypeIntent: AppIntent {

    public static let title: LocalizedStringResource = .init("intent_explain_title")

    public static let description = IntentDescription(.init("intent_explain_description"))

    public static let openAppWhenRun: Bool = false

    @Parameter(title: .init("intent_parameter_service_type"))
    public var serviceType: BonjourServiceTypeEntity

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        switch await Self.outcome(fullType: serviceType.id, bridge: .shared) {
        case .explanation(let text):
            return .result(
                value: text,
                dialog: IntentDialog(LocalizedStringResource(stringLiteral: text))
            )
        case .offline:
            throw SiriIntentError(message: Strings.Siri.explanationOffline)
        case .unavailable:
            throw SiriIntentError(message: Strings.Siri.explanationUnavailable)
        }
    }

    // MARK: - Helpers

    /// What an explain request produced.
    enum Outcome: Equatable {
        case explanation(String)
        /// The selected backend is a cloud model and the device is offline.
        case offline
        /// No backend is available, the type is unknown, or generation failed.
        case unavailable
    }

    /// Runs a brief explanation and reports how it went. `serviceTypes`
    /// defaults to the library plus custom types.
    @MainActor
    static func outcome(
        fullType: String,
        bridge: AppIntentsBridge,
        serviceTypes: [BonjourServiceType]? = nil
    ) async -> Outcome {
        guard let serviceType = BonjourServiceType.fetch(serviceTypes: serviceTypes, fullType: fullType),
              let explainer = bridge.makeExplainer?(),
              explainer.isAvailable else {
            return .unavailable
        }
        let isConnected = bridge.isInternetConnected?() ?? true
        guard explainer.connectivityRequirement.isSatisfied(isConnected: isConnected) else {
            return .offline
        }
        // A spoken answer should be short whatever Settings says.
        explainer.responseLength = .brief
        await explainer.explain(serviceType: serviceType)
        guard explainer.error == nil else { return .unavailable }
        let text = SiriPlainText.from(markdown: explainer.explanation)
        return text.isEmpty ? .unavailable : .explanation(text)
    }

    /// A brief explanation as plain text, or `nil` when no backend is
    /// available, the device is offline for a cloud backend, or
    /// generation fails.
    @MainActor
    static func explanation(
        fullType: String,
        bridge: AppIntentsBridge,
        serviceTypes: [BonjourServiceType]? = nil
    ) async -> String? {
        guard case .explanation(let text) = await outcome(
            fullType: fullType,
            bridge: bridge,
            serviceTypes: serviceTypes
        ) else {
            return nil
        }
        return text
    }
}
