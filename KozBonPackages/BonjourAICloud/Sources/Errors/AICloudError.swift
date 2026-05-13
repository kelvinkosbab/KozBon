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

    /// The provider rejected the supplied credentials (HTTP 401).
    /// The key is invalid, malformed, or revoked — the user
    /// should re-enter a fresh one. Separate from
    /// ``permissionDenied`` because the user-facing remediation
    /// is different: invalid keys mean "get a new key and
    /// re-sign-in"; permission errors mean "your plan doesn't
    /// allow this resource."
    case invalidCredentials(provider: AICloudProvider)

    /// The provider accepted the key but the account doesn't
    /// have permission for the requested resource — typically a
    /// model the account's plan tier doesn't include (HTTP 403).
    /// The chat surface routes this to a deep link to the
    /// provider's plan-management console.
    case permissionDenied(provider: AICloudProvider, message: String?)

    /// The provider rate-limited the request. ``retryAfterSeconds``
    /// carries the server's `Retry-After` header when present.
    case rateLimited(provider: AICloudProvider, retryAfterSeconds: TimeInterval?)

    /// The provider returned a generic server-side error (5xx
    /// other than 529). The opaque message comes from the
    /// provider's response body.
    case serverError(provider: AICloudProvider, message: String?)

    /// The provider is currently overloaded (HTTP 529 for
    /// Anthropic; capacity-saturation errors for other
    /// providers). Distinct from ``serverError`` because the
    /// user-facing remediation includes a status-page link —
    /// the user can check whether it's a wide outage or just
    /// their request.
    case serviceOverloaded(provider: AICloudProvider, message: String?)

    /// The provider rejected the request body as invalid (4xx
    /// other than auth or rate-limit — typically 400, 404, 422).
    /// Common causes: a model identifier that doesn't exist for
    /// this account, a malformed system block, or a required
    /// beta header missing. The provider's actual error string
    /// rides on ``message``, so users and logs see exactly what
    /// the API complained about instead of a bare status code.
    case invalidRequest(provider: AICloudProvider, message: String?)

    /// The provider's account has no credits / no payment
    /// method, so requests are refused even with a valid API
    /// key. A specific carve-out from ``invalidRequest`` because
    /// the user-facing remediation is different — they need to
    /// open the provider's billing console, not fix anything in
    /// the app. The chat surface routes this case to an
    /// actionable banner with a deep link to billing.
    case creditBalanceTooLow(provider: AICloudProvider, message: String?)

    /// The request's prompt + history exceeded the model's
    /// context window (HTTP 400 with a "prompt is too long" or
    /// similar message). Carved out from ``invalidRequest``
    /// because the user-facing fix is in-app — clearing the
    /// chat truncates the history that put the request over
    /// the limit, so subsequent sends fit again.
    case contextWindowExceeded(provider: AICloudProvider, message: String?)

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
        case .permissionDenied(let provider, let message):
            if let message, !message.isEmpty {
                return "\(provider.rawValue) denied access to the requested resource: \(message)"
            }
            return "\(provider.rawValue) denied access to the requested resource."
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
        case .serviceOverloaded(let provider, let message):
            if let message, !message.isEmpty {
                return "\(provider.rawValue) is currently overloaded: \(message)"
            }
            return "\(provider.rawValue) is currently overloaded. Please try again shortly."
        case .invalidRequest(let provider, let message):
            if let message, !message.isEmpty {
                return "\(provider.rawValue) rejected the request: \(message)"
            }
            return "\(provider.rawValue) rejected the request."
        case .creditBalanceTooLow(let provider, let message):
            if let message, !message.isEmpty {
                return "\(provider.rawValue) credit balance too low: \(message)"
            }
            return "\(provider.rawValue) credit balance is too low to access the API."
        case .contextWindowExceeded(let provider, let message):
            if let message, !message.isEmpty {
                return "\(provider.rawValue) context window exceeded: \(message)"
            }
            return "\(provider.rawValue) context window exceeded. Clear the chat to start fresh."
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
