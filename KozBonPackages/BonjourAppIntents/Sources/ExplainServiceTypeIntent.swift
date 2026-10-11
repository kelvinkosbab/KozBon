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
        guard let text = await Self.explanation(fullType: serviceType.id, bridge: .shared) else {
            throw SiriIntentError(message: Strings.Siri.explanationUnavailable)
        }
        return .result(
            value: text,
            dialog: IntentDialog(LocalizedStringResource(stringLiteral: text))
        )
    }

    // MARK: - Helpers

    /// A brief explanation as plain text, or `nil` when no backend is
    /// available or generation fails.
    @MainActor
    static func explanation(fullType: String, bridge: AppIntentsBridge) async -> String? {
        guard let serviceType = BonjourServiceType.fetch(fullType: fullType),
              let explainer = bridge.makeExplainer?(),
              explainer.isAvailable else {
            return nil
        }
        // A spoken answer should be short whatever Settings says.
        explainer.responseLength = .brief
        await explainer.explain(serviceType: serviceType)
        guard explainer.error == nil else { return nil }
        let text = SiriPlainText.from(markdown: explainer.explanation)
        return text.isEmpty ? nil : text
    }
}
