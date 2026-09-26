//
//  AmbientMeshBackground.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - AmbientMeshBackground

/// A slowly rolling colour wash painted behind a screen's content.
///
/// ``AmbientMeshWave`` supplies the geometry and alpha; this view
/// binds them to a palette and a clock. Rendering is a pure function
/// of elapsed time rather than `withAnimation` state, which is what
/// lets the whole thing freeze to a fixed frame instead of blanking
/// when motion is suppressed.
///
/// Frozen (not hidden) under Reduce Motion, Low Power Mode, or a
/// backgrounded scene. Whether the wash is drawn *at all* is
/// ``AmbientMeshBackgroundModifier``'s decision — it owns the user
/// preference and the accessibility settings that conflict outright.
struct AmbientMeshBackground: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    /// Per-tab hues and wave phase.
    let palette: AmbientMeshPalette

    /// How strongly the wash reads. Defaults to
    /// ``AmbientMeshIntensity/standard``.
    var intensity: AmbientMeshIntensity = .standard

    /// Mirrors `ProcessInfo.isLowPowerModeEnabled`, refreshed from
    /// the power-state notification. Seeded at init so the first
    /// frame is already correct on a device that launches in Low
    /// Power Mode.
    @State private var isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled

    // MARK: - Tuning

    /// 30fps, not the display's native rate. The wave periods are
    /// long enough (4–7s) that the dropped frames don't show as
    /// stepping, and they're the entire point on a screen that also
    /// runs a continuous Bonjour scan.
    private static let frameInterval: TimeInterval = 1.0 / 30.0

    /// Overall strength of the wash at
    /// ``AmbientMeshIntensity/standard``. The list itself is still
    /// the content, so this stays short of anything that would read
    /// as a coloured background — but well above a scrim.
    private static let washOpacity: Double = 0.55

    // MARK: - Body

    var body: some View {
        TimelineView(.animation(minimumInterval: Self.frameInterval, paused: isPaused)) { context in
            let time = isPaused ? 0 : context.date.timeIntervalSinceReferenceDate

            MeshGradient(
                width: AmbientMeshWave.resolution,
                height: AmbientMeshWave.resolution,
                points: AmbientMeshWave.points(at: time, phase: palette.phaseOffset),
                colors: colors(at: time),
                background: .clear,
                smoothsColors: true
            )
        }
        .opacity(Self.washOpacity * intensity.opacityScale)
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
    ///
    /// Pauses on `.background` only, not on `.inactive`. An
    /// unfocused window, a Stage Manager side panel, and a
    /// simulator the developer isn't clicking on are all
    /// `.inactive` while fully on screen — freezing there just
    /// looks broken. A backgrounded scene isn't rendering anyway.
    private var isPaused: Bool {
        reduceMotion || isLowPowerMode || scenePhase == .background
    }

    // MARK: - Colour

    /// The palette's sixteen hues carrying the travelling alpha at a
    /// given time.
    private func colors(at time: TimeInterval) -> [Color] {
        let alphas = AmbientMeshWave.alphas(at: time, phase: palette.phaseOffset)
        return zip(palette.hues, alphas).map { $0.opacity($1) }
    }
}

// MARK: - Previews

// These previews mount the view directly, bypassing
// `AmbientMeshBackgroundModifier` — so the preference and the
// accessibility suppression aren't in play here. The frozen state
// isn't previewable either: Reduce Motion is a read-only environment
// value with no canvas variant, so it needs the Settings toggle on a
// device or simulator.

#Preview("Ambient Mesh - Discover") {
    AmbientMeshBackground(palette: .discover)
}

#Preview("Ambient Mesh - All Palettes") {
    // Side by side, to check the four tabs read as variations on one
    // palette rather than as four different apps.
    VStack(spacing: 0) {
        AmbientMeshBackground(palette: .discover)
        AmbientMeshBackground(palette: .library)
        AmbientMeshBackground(palette: .preferences)
        AmbientMeshBackground(palette: .chat)
    }
}

#Preview("Ambient Mesh - Dark") {
    AmbientMeshBackground(palette: .discover)
        .preferredColorScheme(.dark)
}

#Preview("Ambient Mesh - Behind Content") {
    // Mirrors the production mount. Worth checking row text stays
    // legible against the brightest part of the gradient.
    NavigationStack {
        List {
            ForEach(0..<12, id: \.self) { index in
                TitleDetailStackView(
                    title: "Sample Service \(index)",
                    detail: "_sample._tcp · 192.168.1.\(index)"
                )
            }
        }
        .ambientMeshPalette(.discover)
        .ambientMeshBackground()
        .navigationTitle(Text(verbatim: "Discover"))
    }
}
