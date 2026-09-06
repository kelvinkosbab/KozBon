//
//  PreferencesStore+AICloudModel.swift
//  BonjourAICore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourStorage

// MARK: - PreferencesStore Bridge

public extension PreferencesStore {

    /// The user's preferred model for `provider`, as the raw API
    /// identifier sent in a request.
    ///
    /// Deliberately a `String` rather than a provider's model enum.
    /// Catalogs are fetched at runtime, so a perfectly valid
    /// selection — `claude-opus-5`, say — routinely won't correspond
    /// to any case compiled into this binary. Round-tripping through
    /// an enum here would silently discard exactly those newer
    /// models and snap the user back to whatever generation shipped
    /// with the app, which is the bug that made the picker feel
    /// frozen in time.
    ///
    /// The only normalization applied is emptiness: a blank or
    /// whitespace-only stored value falls back to
    /// ``AICloudProvider/defaultModelIdentifier``. Deciding that a
    /// *non-empty* identifier is invalid requires the authoritative
    /// catalog, so that judgement lives in each provider's catalog
    /// type — which only reassigns when it has a live list proving
    /// the model is gone.
    ///
    /// - Parameter provider: Whose slot to read. Each provider keeps
    ///   its own, so switching backends and back preserves both
    ///   choices.
    func aiCloudModelIdentifier(for provider: AICloudProvider) -> String {
        let stored = rawModelValue(for: provider)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return stored.isEmpty ? provider.defaultModelIdentifier : stored
    }

    /// Records the user's model choice for `provider`.
    func setAICloudModelIdentifier(_ identifier: String, for provider: AICloudProvider) {
        switch provider {
        case .anthropic:
            aiCloudModelRawValue = identifier
        case .gemini:
            aiGeminiModelRawValue = identifier
        case .github:
            // Retired provider — nothing reads this back.
            break
        }
    }

    /// The model identifier for whichever backend is selected right
    /// now, so routing and change-observation don't each have to
    /// re-derive the provider.
    ///
    /// On the on-device backend there is no cloud model to speak of;
    /// this reads the Anthropic slot so the property stays
    /// non-optional. Nothing consumes it in that state — the
    /// factories only reach for a model once they've routed to a
    /// cloud provider.
    var aiCloudModelIdentifier: String {
        get { aiCloudModelIdentifier(for: aiBackend.cloudProvider ?? .anthropic) }
        set { setAICloudModelIdentifier(newValue, for: aiBackend.cloudProvider ?? .anthropic) }
    }

    /// Raw, un-defaulted storage access — the one place that knows
    /// which `UserPreferences` field belongs to which provider.
    private func rawModelValue(for provider: AICloudProvider) -> String {
        switch provider {
        case .anthropic:
            return aiCloudModelRawValue
        case .gemini:
            return aiGeminiModelRawValue
        case .github:
            return ""
        }
    }
}
