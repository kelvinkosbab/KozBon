//
//  AppleIntelligenceSupport.swift
//  BonjourAI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourLocalization

#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - AppleIntelligenceSupport

/// Utilities for checking whether Apple Intelligence can be supported on this device.
public enum AppleIntelligenceSupport {

    // MARK: - AvailabilityState

    /// The set of states the Apple Intelligence subsystem can be in,
    /// at the granularity the app's UI needs to react to differently.
    ///
    /// Maps the variants of `SystemLanguageModel.Availability.UnavailableReason`
    /// onto the four buckets that drive distinct user-facing flows:
    /// hide AI UI, show a "turn on in Settings" CTA, show a
    /// "downloading…" status, or show a generic unavailable
    /// message. Keeping the enum here means consumers don't import
    /// `FoundationModels` directly to check the state.
    ///
    /// See `apple-foundation-models.md` for the rationale on
    /// distinguishing these reasons rather than collapsing them
    /// into a `Bool` — a user with capable hardware whose Apple
    /// Intelligence is disabled deserves a different surface than
    /// a user on a non-eligible device.
    public enum AvailabilityState: Sendable, Equatable {
        /// On-device Apple Intelligence is ready to use.
        case available
        /// Hardware doesn't support Apple Intelligence (older
        /// device, missing Neural Engine generation, etc.). The
        /// app should hide AI UI entirely — there's no recovery
        /// path the user can take.
        case deviceNotEligible
        /// Hardware supports Apple Intelligence but it's currently
        /// turned off in iOS Settings (Settings → Apple Intelligence
        /// & Siri → Apple Intelligence). The app should keep AI
        /// UI visible and surface a CTA pointing the user at the
        /// system setting.
        case appleIntelligenceDisabled
        /// Hardware and software support Apple Intelligence but the
        /// model is still downloading. The app should keep AI UI
        /// visible and tell the user to wait.
        case modelNotReady
        /// Catch-all for unavailability reasons we don't have a
        /// specific UI flow for (new SDK reasons we haven't seen
        /// yet, transient resource pressure, etc.). Behaves the
        /// same as `appleIntelligenceDisabled` in the UI: keep AI
        /// surface visible, show a generic message.
        case otherUnavailable
    }

    /// The current availability of on-device Apple Intelligence.
    ///
    /// Underlying source: `SystemLanguageModel.default.availability`,
    /// which iOS 26+ exposes. In the iOS Simulator this always
    /// reports `.available` so the chat / Insights UI can be
    /// exercised end-to-end with the lorem-ipsum simulator
    /// implementations.
    public static var availability: AvailabilityState {
        #if targetEnvironment(simulator)
        return .available
        #elseif canImport(FoundationModels)
        if #available(iOS 26, macOS 26, visionOS 26, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                return .available
            case .unavailable(.deviceNotEligible):
                return .deviceNotEligible
            case .unavailable(.appleIntelligenceNotEnabled):
                return .appleIntelligenceDisabled
            case .unavailable(.modelNotReady):
                return .modelNotReady
            case .unavailable:
                return .otherUnavailable
            @unknown default:
                return .otherUnavailable
            }
        }
        return .deviceNotEligible
        #else
        return .deviceNotEligible
        #endif
    }

    /// Whether this device is *capable* of running Apple
    /// Intelligence — that is, the hardware is eligible, even if
    /// it's currently turned off or the model is still downloading.
    ///
    /// `true` when the surface should keep AI UI visible (so the
    /// user can act on whatever's required to enable it).
    /// `false` only on hardware that fundamentally can't run
    /// Apple Intelligence at all — in which case the AI UI hides
    /// entirely. In the iOS Simulator this always returns `true`
    /// so developers can test the AI UI with simulator mocks.
    public static var isDeviceSupported: Bool {
        availability != .deviceNotEligible
    }

    /// A localized message describing why Apple Intelligence isn't
    /// usable right now, or `nil` when it's `.available` or the
    /// device is fundamentally `.deviceNotEligible` (and the AI
    /// UI is hidden anyway).
    ///
    /// Surfaced by the Settings → AI Insights section as a notice
    /// banner so users on capable hardware understand what they
    /// need to do (turn on Apple Intelligence in iOS Settings,
    /// wait for the model to finish downloading, etc.).
    public static var unavailabilityReason: String? {
        switch availability {
        case .available, .deviceNotEligible:
            return nil
        case .appleIntelligenceDisabled:
            return String(localized: Strings.Settings.aiUnavailableNotEnabled)
        case .modelNotReady:
            return String(localized: Strings.Settings.aiUnavailableModelDownloading)
        case .otherUnavailable:
            return String(localized: Strings.Settings.aiUnavailableOther)
        }
    }

    /// Whether the AI features should use simulator mock responses.
    ///
    /// Always `true` in the iOS Simulator, `false` on physical devices.
    public static var isRunningInSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
}
