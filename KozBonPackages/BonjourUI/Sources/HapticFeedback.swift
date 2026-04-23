//
//  HapticFeedback.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// MARK: - HapticFeedbackStyle

/// A cross-platform, framework-agnostic haptic kind that the rest of the
/// app can request without knowing whether UIKit's feedback generators,
/// `CHHapticEngine`, or nothing at all is available on the current system.
///
/// Each case maps to a specific UIKit feedback generator on iOS and is a
/// no-op on platforms without haptics.
public enum HapticFeedbackStyle: Sendable, Hashable {

    // MARK: Impact

    /// Subtle tap — use for ambient feedback (e.g. per-sentence streaming).
    case light

    /// Standard tap — use for confirming discrete actions (e.g. submit).
    case medium

    /// Strong tap — use for impactful events (e.g. drop/drag completion).
    case heavy

    /// Softer, damped tap.
    case soft

    /// Sharper, stiffer tap.
    case rigid

    // MARK: Selection

    /// A one-off click used when a selection actively changes (e.g.
    /// cycling through a picker value).
    case selection

    // MARK: Notification

    /// Confirms a successful outcome (e.g. form submitted).
    case success

    /// Warns about a recoverable issue (e.g. input validation warning).
    case warning

    /// Signals a failure (e.g. send failed).
    case error
}

// MARK: - HapticFeedbackProviding

/// Abstraction over the haptic-feedback subsystem so views and view
/// models can request haptics without directly depending on
/// `UIImpactFeedbackGenerator` or any other platform API.
///
/// Inject via ``EnvironmentValues/hapticFeedback`` in views:
///
/// ```swift
/// @Environment(\.hapticFeedback) private var haptic
///
/// Button("Refresh") {
///     haptic.play(.light)
///     viewModel.reload()
/// }
/// ```
///
/// Or pass into view models through their initializer, defaulting to the
/// system implementation for production:
///
/// ```swift
/// final class MyViewModel {
///     private let haptic: any HapticFeedbackProviding
///     init(haptic: any HapticFeedbackProviding = SystemHapticFeedback()) {
///         self.haptic = haptic
///     }
/// }
/// ```
///
/// The protocol is `@MainActor`-isolated so conforming types can freely
/// call platform APIs (UIKit feedback generators are main-thread-only)
/// without every call site needing its own actor hop.
@MainActor
public protocol HapticFeedbackProviding: Sendable {

    /// Plays the requested haptic. No-op on platforms without haptic
    /// hardware (macOS, tvOS, visionOS).
    func play(_ style: HapticFeedbackStyle)
}

// MARK: - SystemHapticFeedback

/// The production ``HapticFeedbackProviding`` that routes through UIKit's
/// feedback generators on iOS and silently does nothing on other
/// platforms. Safe to instantiate anywhere — each call builds a fresh
/// generator so there's no shared state to worry about.
public struct SystemHapticFeedback: HapticFeedbackProviding {

    public init() {}

    public func play(_ style: HapticFeedbackStyle) {
        #if os(iOS)
        switch style {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .soft:
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        case .rigid:
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        case .selection:
            UISelectionFeedbackGenerator().selectionChanged()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        #endif
    }
}

// MARK: - MockHapticFeedback

/// Test/preview double that records every requested haptic style without
/// playing anything on the hardware. Use from Swift Testing suites to
/// assert which haptics a view model fires, or from SwiftUI previews to
/// avoid spurious taps during Xcode's live-preview rendering.
///
/// ```swift
/// @Test func submittingFiresMediumImpact() async {
///     let haptic = MockHapticFeedback()
///     let viewModel = ComposeViewModel(haptic: haptic)
///     await viewModel.submit("hi")
///     #expect(haptic.playedStyles == [.medium])
/// }
/// ```
@MainActor
public final class MockHapticFeedback: HapticFeedbackProviding {

    /// Ordered list of styles passed to ``play(_:)`` since the mock was
    /// created. Inspect this from tests; call ``reset()`` between
    /// assertions if you want independent readings.
    public private(set) var playedStyles: [HapticFeedbackStyle] = []

    public init() {}

    public func play(_ style: HapticFeedbackStyle) {
        playedStyles.append(style)
    }

    /// Clears the recorded history. Intended for tests that run multiple
    /// "act + assert" cycles against the same mock instance.
    public func reset() {
        playedStyles.removeAll()
    }
}

// MARK: - Environment Injection

private struct HapticFeedbackKey: @preconcurrency EnvironmentKey {
    @MainActor static var defaultValue: any HapticFeedbackProviding {
        SystemHapticFeedback()
    }
}

public extension EnvironmentValues {

    /// The haptic-feedback provider for the current view hierarchy. Read
    /// via `@Environment(\.hapticFeedback)` in views; override in tests,
    /// previews, or feature flags by applying
    /// `.environment(\.hapticFeedback, MockHapticFeedback())`.
    var hapticFeedback: any HapticFeedbackProviding {
        get { self[HapticFeedbackKey.self] }
        set { self[HapticFeedbackKey.self] = newValue }
    }
}
