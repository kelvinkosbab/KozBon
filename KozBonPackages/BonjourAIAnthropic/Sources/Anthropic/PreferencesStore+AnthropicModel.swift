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

    /// The user's preferred Claude model, as a typed enum.
    ///
    /// Backed by `aiCloudModelRawValue`. Defaults to
    /// ``AnthropicModel/default`` (`.sonnet`) when no value is
    /// stored. Lives in `BonjourAIAnthropic` so the provider-agnostic
    /// `BonjourAICore` doesn't depend on Anthropic-specific types.
    var aiCloudModel: AnthropicModel {
        get { AnthropicModel.resolved(rawValue: aiCloudModelRawValue) }
        set { aiCloudModelRawValue = newValue.rawValue }
    }
}
