//
//  AmbientMeshBackground.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - AmbientMeshBackground

/// A slow, low-frequency colour wash painted behind a screen's
/// content.
///
/// The mesh control points drift on independent sine waves with
/// periods of roughly 50–80 seconds, so the motion reads as
/// atmosphere rather than animation — there is no loop a user can
/// perceive and nothing that competes with the list in front of it.
///
/// Rendering is a pure function of elapsed time rather than
/// `withAnimation` state, which is what lets the whole thing freeze
/// to a fixed frame instead of blanking when motion is suppressed.
///
/// Suppressed entirely under Increase Contrast, and frozen (not
/// hidden) under Reduce Motion, Low Power Mode, or when the scene
/// is not active.
struct AmbientMeshBackground: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.scenePhase) private var scenePhase

    /// Mirrors `ProcessInfo.isLowPowerModeEnabled`, refreshed from
    /// the power-state notification. Seeded at init so the first
    /// frame is already correct on a device that launches in Low
    /// Power Mode.
    @State private var isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled

    // MARK: - Tuning

    /// Deliberately ~20fps, not the display's native rate. The wash
    /// is low-frequency enough that nobody can tell, and the frames
    /// we skip are the entire point on a screen that also runs a
    /// continuous Bonjour scan.
    private static let frameInterval: TimeInterval = 1.0 / 20.0

    /// Overall strength of the wash. Low by design — the list is the
    /// content and this must never compete with row text for
    /// attention or contrast.
    private static let washOpacity: Double = 0.30

    /// How far an interior control point may drift from its resting
    /// position, in unit-square coordinates. Corners never move, so
    /// the mesh always covers the full frame.
    private static let driftAmplitude: Float = 0.09

    // MARK: - Body

    var body: some View {
        if colorSchemeContrast == .increased {
            // Increase Contrast is a legibility request. Any tint
            // behind the content works against it, so there's no
            // "reduced" version worth keeping here.
            Color.clear
        } else {
            wash
        }
    }

    private var wash: some View {
        TimelineView(.animation(minimumInterval: Self.frameInterval, paused: isPaused)) { context in
            MeshGradient(
                width: 3,
                height: 3,
                points: Self.points(at: isPaused ? 0 : context.date.timeIntervalSinceReferenceDate),
                colors: Self.colors,
                background: .clear,
                smoothsColors: true
            )
        }
        .opacity(Self.washOpacity)
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onReceive(
            NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange)
        ) { _ in
            isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        }
    }

    /// Frozen rather than hidden: a still mesh is a pleasant
    /// gradient, so suppressing motion costs the user nothing
    /// visually.
    private var isPaused: Bool {
        reduceMotion || isLowPowerMode || scenePhase != .active
    }

    // MARK: - Geometry

    /// The nine control points of the 3×3 mesh at a given time.
    ///
    /// Pure and deterministic so it can be unit-tested without a
    /// rendering pass, and so `paused` can freeze the wash by simply
    /// pinning `time` to zero.
    ///
    /// The four corners are pinned. If they drifted, the mesh would
    /// pull away from the frame edges and expose the background
    /// through the gap.
    ///
    /// - Parameter time: Elapsed time in seconds. Any stable
    ///   reference epoch works; only differences matter.
    static func points(at time: TimeInterval) -> [SIMD2<Float>] {
        func drift(phase: Double, speed: Double) -> Float {
            0.5 + Self.driftAmplitude * Float(sin(time * speed + phase))
        }

        // Mutually prime-ish speeds keep the points from returning to
        // a shared configuration, so the wash never visibly repeats.
        return [
            SIMD2(0, 0),
            SIMD2(drift(phase: 0.0, speed: 0.121), 0),
            SIMD2(1, 0),

            SIMD2(0, drift(phase: 1.3, speed: 0.097)),
            SIMD2(drift(phase: 2.1, speed: 0.083), drift(phase: 3.4, speed: 0.109)),
            SIMD2(1, drift(phase: 4.2, speed: 0.113)),

            SIMD2(0, 1),
            SIMD2(drift(phase: 5.0, speed: 0.131), 1),
            SIMD2(1, 1)
        ]
    }

    /// Brand blue carries the wash; the cyan and indigo corners add
    /// just enough hue travel to keep it from reading as a flat
    /// scrim. Per-colour alpha does the shaping — `washOpacity` then
    /// scales the whole thing.
    private static let colors: [Color] = [
        Color.kozBonBlue.opacity(0.45), Color.cyan.opacity(0.20), Color.kozBonBlue.opacity(0.50),
        Color.indigo.opacity(0.28), Color.kozBonBlue.opacity(0.60), Color.cyan.opacity(0.22),
        Color.kozBonBlue.opacity(0.55), Color.indigo.opacity(0.30), Color.kozBonBlue.opacity(0.40)
    ]
}
