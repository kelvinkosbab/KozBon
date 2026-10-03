//
//  TypingIndicator.swift
//  BonjourAICore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - TypingIndicator

/// A three-dot pulsing indicator shown while an AI response is being generated.
///
/// Provides clear visual feedback that the model is still working, even when
/// streaming pauses between token chunks. Dots ripple leading-to-trailing in
/// the style of the Apple Messages typing bubble.
///
/// Respects `accessibilityReduceMotion` by falling back to a static row of dots.
///
/// The pill is Liquid Glass rather than a material: the chat sits on
/// an animated colour wash, and `.ultraThinMaterial` let so much of
/// it through that the dots read as part of the background. Glass
/// carries its own edge and shadow, so the indicator separates from
/// whatever happens to be behind it.
public struct TypingIndicator: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Per-dot animation flag. Each dot's flag is flipped independently after
    /// a staggered delay, so each dot has its own repeating cycle that never
    /// re-syncs with the others — this is what produces the traveling wave.
    ///
    /// We can't use `.animation(...).delay(index * interval)` with
    /// `.repeatForever` because SwiftUI only applies the delay to the first
    /// cycle, causing all three dots to snap back into phase on subsequent
    /// cycles and "flash" together instead of rippling.
    @State private var isPulsing: [Bool] = Array(repeating: false, count: Self.dotCount)

    /// Number of dots in the indicator.
    private static let dotCount = 3

    /// The diameter of each dot in points.
    private let dotSize: CGFloat = 7

    /// Duration of a single pulse (one direction). With `autoreverses: true`
    /// the full cycle is `pulseDuration * 2`.
    private let pulseDuration: Double = 0.5

    /// Time between the start of one dot's cycle and the next. Picks a value
    /// that clearly separates the dots within the full `pulseDuration * 2`
    /// cycle so the wave is visible.
    private let staggerInterval: Double = 0.2

    public init() {}

    public var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<Self.dotCount, id: \.self) { index in
                Circle()
                    // `.primary`, not `.secondary` — secondary over a
                    // translucent pill on a coloured background left
                    // the dots barely legible at the bottom of their
                    // pulse.
                    .fill(Color.primary)
                    .frame(width: dotSize, height: dotSize)
                    .opacity(opacity(for: index))
                    .scaleEffect(scale(for: index))
            }
        }
        // Vertical padding is noticeably larger than before so the capsule
        // reads as a proper pill instead of a thin sliver — at vpad=8 the
        // capsule was ~22pt tall and felt cramped against the dots.
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .platformGlassBackground(in: Capsule())
        .padding(.top, 6)
        .onAppear {
            startAnimating()
        }
    }

    // MARK: - Per-Dot Style

    /// Scale carries the wave; opacity only shades it. The old
    /// 0.3 trough left the resting dots reading as grey-on-grey
    /// against the pill, so every dot now stays firmly legible and
    /// the ripple shows as size rather than near-disappearance.
    private func opacity(for index: Int) -> Double {
        if reduceMotion { return 0.85 }
        return isPulsing[index] ? 1.0 : 0.65
    }

    private func scale(for index: Int) -> CGFloat {
        if reduceMotion { return 1.0 }
        return isPulsing[index] ? 1.0 : 0.55
    }

    // MARK: - Animation

    /// Kicks off each dot's own `repeatForever` cycle after a staggered delay.
    ///
    /// Because each dot's animation starts at a different absolute time and
    /// then repeats independently, their phases stay offset forever — giving
    /// the traveling-wave look of the iMessage typing indicator.
    private func startAnimating() {
        guard !reduceMotion else { return }
        for index in 0..<Self.dotCount {
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(Double(index) * staggerInterval))
                withAnimation(
                    .easeInOut(duration: pulseDuration).repeatForever(autoreverses: true)
                ) {
                    isPulsing[index] = true
                }
            }
        }
    }
}
