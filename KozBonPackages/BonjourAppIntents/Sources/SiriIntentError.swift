//
//  SiriIntentError.swift
//  BonjourAppIntents
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - SiriIntentError

/// An action failure Siri reads aloud and Shortcuts shows as the
/// error, instead of a generic "there was a problem".
struct SiriIntentError: Error, CustomLocalizedStringResourceConvertible {

    /// Already localized through `Strings.Siri`.
    let message: String

    var localizedStringResource: LocalizedStringResource {
        LocalizedStringResource(stringLiteral: message)
    }
}
