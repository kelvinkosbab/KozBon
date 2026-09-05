//
//  PreferencesStore+AnthropicModel.swift
//  BonjourAIAnthropic
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourStorage
import BonjourAICore

// MARK: - PreferencesStore Bridge

public extension PreferencesStore {

    /// The user's preferred Claude model, as the raw API
    /// identifier sent in a request's `model` field.
    ///
    /// Deliberately a `String` rather than the ``AnthropicModel``
    /// enum. The catalog is fetched at runtime from
    /// `GET /v1/models`, so a perfectly valid selection —
    /// `claude-opus-5`, say — routinely won't correspond to any
    /// case compiled into this binary. Round-tripping through
    /// `AnthropicModel.resolved(rawValue:)` here would silently
    /// discard exactly those newer models and snap the user back
    /// to whatever generation shipped with the app, which is the
    /// bug that made the picker feel frozen in time.
    ///
    /// The only normalization applied is emptiness: a blank or
    /// whitespace-only stored value falls back to
    /// ``AnthropicModel/default``. Deciding that a *non-empty*
    /// identifier is invalid requires the authoritative catalog,
    /// so that judgement lives in
    /// ``AnthropicModelCatalog/resolvedSelection(for:)`` — which
    /// only reassigns when it has a live list proving the model
    /// is gone.
    ///
    /// Lives in `BonjourAIAnthropic` so the provider-agnostic
    /// `BonjourAICore` doesn't depend on Anthropic-specific types.
    var aiCloudModelIdentifier: String {
        get {
            let stored = aiCloudModelRawValue.trimmingCharacters(in: .whitespacesAndNewlines)
            return stored.isEmpty ? AnthropicModel.default.rawValue : stored
        }
        set { aiCloudModelRawValue = newValue }
    }
}
