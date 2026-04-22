//
//  TypingIndicator.swift
//  BonjourAI
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
    private let dotSize: CGFloat = 6

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
                    .fill(Color.secondary)
                    .frame(width: dotSize, height: dotSize)
                    .opacity(opacity(for: index))
                    .scaleEffect(scale(for: index))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .padding(.top, 6)
        .onAppear {
            startAnimating()
        }
    }

    // MARK: - Per-Dot Style

    private func opacity(for index: Int) -> Double {
        if reduceMotion { return 0.6 }
        return isPulsing[index] ? 1.0 : 0.3
    }

    private func scale(for index: Int) -> CGFloat {
        if reduceMotion { return 1.0 }
        return isPulsing[index] ? 1.0 : 0.6
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
