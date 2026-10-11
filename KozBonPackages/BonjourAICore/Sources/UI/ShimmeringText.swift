//
//  ShimmeringText.swift
//  BonjourAICore
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - ShimmeringText

/// A text view that paints itself in the secondary foreground
/// color, with a narrow bright band that sweeps from leading to
/// trailing across the glyphs in a repeating loop. The band is
/// masked by the text shape so only the letters glow — the
/// surrounding row stays uncolored.
///
/// Respects Reduce Motion: when the user has the system
/// preference enabled, the shimmer animation is suppressed and
/// the text renders in its base secondary color statically.
///
/// Shared by the chat's scanning row and the Insights sheet's
/// "Generating explanation…" capsule.
public struct ShimmeringText: View {

    let text: String

    public init(text: String) {
        self.text = text
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.layoutDirection) private var layoutDirection

    // MARK: - Tuning

    /// Width of the bright band as a fraction of the text's
    /// own width. Smaller values produce a thinner, more
    /// focused glow; larger values look like a wash. 0.4 is
    /// the sweet spot in design review — the highlight reads
    /// clearly without looking like the whole word is
    /// flashing.
    private static let bandWidthFraction: CGFloat = 0.4

    /// Time for one full leading-to-trailing pass of the
    /// shimmer. Slow enough that the eye can follow without
    /// straining; fast enough that the user sees a couple of
    /// loops during the typical 3-second scan window.
    private static let sweepDuration: TimeInterval = 1.4

    /// Explicit opacities rather than `.secondary` / `.primary`:
    /// the Liquid Glass bubble applies vibrancy to hierarchical
    /// styles, which flattened the two into nearly the same tone
    /// and made the band invisible.
    private static let baseOpacity: Double = 0.4

    // MARK: - Body

    public var body: some View {
        if reduceMotion {
            Text(text)
                .foregroundStyle(.secondary)
        } else {
            // Driven by the timeline clock rather than a
            // `repeatForever` started in `onAppear`: the bubble is
            // inserted inside the chat's spring transaction and a
            // matched-geometry morph, which swallowed the
            // state-driven animation and left the text static.
            TimelineView(.animation) { timeline in
                shimmeringText(phase: Self.phase(at: timeline.date))
            }
        }
    }

    /// Progress through the current sweep, `0..<1`.
    private static func phase(at date: Date) -> CGFloat {
        let elapsed = date.timeIntervalSinceReferenceDate
        return CGFloat(elapsed.truncatingRemainder(dividingBy: sweepDuration) / sweepDuration)
    }

    private func shimmeringText(phase: CGFloat) -> some View {
        Text(text)
            .foregroundStyle(Color.primary.opacity(Self.baseOpacity))
            .overlay {
                GeometryReader { geometry in
                    let width = geometry.size.width
                    let bandWidth = width * Self.bandWidthFraction
                    // The band starts fully off the leading edge and
                    // ends fully off the trailing edge, so it slides
                    // through rather than popping in and out.
                    // `offset(x:)` doesn't mirror, so flip it under
                    // right-to-left layouts.
                    let travel = -bandWidth + (width + bandWidth) * phase
                    let direction: CGFloat = layoutDirection == .rightToLeft ? -1 : 1
                    Text(text)
                        .foregroundStyle(Color.primary)
                        // Duplicate of the base text used purely for
                        // the highlight; the indicator supplies the
                        // single accessibility label.
                        .accessibilityHidden(true)
                        .mask(alignment: .leading) {
                            // Feathered edges so the band fades in and
                            // out instead of swiping a hard line.
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [.clear, .black, .clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: bandWidth)
                                .offset(x: travel * direction)
                        }
                }
                .allowsHitTesting(false)
            }
    }
}
