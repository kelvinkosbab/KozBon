//
//  AICloudError.swift
//  BonjourAICloud
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

// MARK: - AICloudError

/// Unified error surface for everything in ``BonjourAICloud``.
///
/// Provider-specific failures (Anthropic rate limit, OpenAI auth
/// rejection, etc.) collapse into these cases so consumers in
/// `BonjourUI` and `AppCore` can pattern-match a single type
/// regardless of which provider produced the error.
///
/// Each case carries enough context to localize a user-facing
/// message — exposed via ``localizedDescription`` — without
/// leaking the underlying SDK's error types into UI code.
public enum AICloudError: Error, Sendable, Equatable {

    /// No API key is configured for the selected provider. The
    /// Settings screen should route the user to the sign-in
    /// affordance.
    case missingCredentials(provider: AICloudProvider)

    /// The provider rejected the supplied credentials. The user
    /// should re-enter their key.
    case invalidCredentials(provider: AICloudProvider)

    /// The provider rate-limited the request. ``retryAfterSeconds``
    /// carries the server's `Retry-After` header when present.
    case rateLimited(provider: AICloudProvider, retryAfterSeconds: TimeInterval?)

    /// The provider returned a server-side error (5xx, transient
    /// model unavailability, etc.). The opaque message comes from
    /// the provider's response body.
    case serverError(provider: AICloudProvider, message: String?)

    /// The provider rejected the request body as invalid (4xx
    /// other than auth or rate-limit — typically 400, 404, 422).
    /// Common causes: a model identifier that doesn't exist for
    /// this account, a malformed system block, or a required
    /// beta header missing. The provider's actual error string
    /// rides on ``message``, so users and logs see exactly what
    /// the API complained about instead of a bare status code.
    case invalidRequest(provider: AICloudProvider, message: String?)

    /// The user's device couldn't reach the provider's API at all
    /// (no network, DNS failure, TLS rejection).
    case networkUnavailable

    /// The provider's streamed response couldn't be decoded.
    /// Surfaces only on SDK / protocol regressions; useful to
    /// distinguish from real server errors during diagnosis.
    case decodingFailure(message: String)

    /// The Keychain refused a read or write. The raw
    /// `OSStatus` is preserved for `os_log`-side diagnostics; the
    /// user-facing message is generic.
    case keychainFailure(status: OSStatus)

    /// The request was cancelled (task cancellation or user
    /// dismissed the chat surface). Distinguished from errors so
    /// the UI doesn't surface a banner for a deliberate cancel.
    case cancelled

    /// Catch-all when the provider returned an HTTP error the
    /// switch above didn't classify. The original status code is
    /// preserved for logging.
    case unexpectedStatus(provider: AICloudProvider, statusCode: Int)
}

// MARK: - LocalizedError

extension AICloudError: LocalizedError {

    /// Returns a generic, English-only description for use in
    /// `os.Logger` calls and crash reports. The localized,
    /// user-facing string lives in the call site (the Settings
    /// view, the chat error banner) and is built from
    /// `BonjourLocalization.Strings`.
    ///
    /// Keeping the localized string out of the error type means
    /// the error remains a pure value — no `Bundle` lookups, no
    /// locale-sensitive output. Tests can compare cases directly
    /// without worrying about the simulator's current locale.
    public var errorDescription: String? {
        switch self {
        case .missingCredentials(let provider):
            return "No API key is configured for \(provider.rawValue)."
        case .invalidCredentials(let provider):
            return "The API key for \(provider.rawValue) was rejected."
        case .rateLimited(let provider, let retry):
            if let retry {
                return "\(provider.rawValue) is rate-limited. Retry after \(Int(retry))s."
            }
            return "\(provider.rawValue) is rate-limited."
        case .serverError(let provider, let message):
            if let message, !message.isEmpty {
                return "\(provider.rawValue) returned a server error: \(message)"
            }
            return "\(provider.rawValue) returned a server error."
        case .invalidRequest(let provider, let message):
            if let message, !message.isEmpty {
                return "\(provider.rawValue) rejected the request: \(message)"
            }
            return "\(provider.rawValue) rejected the request."
        case .networkUnavailable:
            return "Network unavailable."
        case .decodingFailure(let message):
            return "Failed to decode response: \(message)"
        case .keychainFailure(let status):
            return "Keychain operation failed (\(status))."
        case .cancelled:
            return "Request cancelled."
        case .unexpectedStatus(let provider, let statusCode):
            return "\(provider.rawValue) returned unexpected status \(statusCode)."
        }
    }
}
