//
//  ScanningNetworkIndicator.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourAI
import BonjourLocalization

// MARK: - ScanningNetworkIndicator

/// Transient row rendered in the chat thread during the
/// fresh-scan window — the ~3 seconds between the user's
/// question and the AI's first streamed token, while
/// `BonjourOneShotScanner` gathers live network data for the
/// assistant's context block. Renders "Scanning network…" with
/// a bright band sweeping leading-to-trailing across the text,
/// so the chat surface doesn't read as frozen during the scan
/// (particularly important on the cloud backend where network
/// latency stacks onto the scan time).
///
/// Mounts inline as a list row (not a banner) so it visually
/// occupies the slot the assistant's typing-indicator bubble
/// will appear in after the scan completes. Swapping one
/// indicator for the other lands the assistant bubble in the
/// same place the scan row was, keeping the scroll position
/// stable across the transition.
///
/// Wears the same glass capsule as ``TypingIndicator`` (padding,
/// shape, top inset) so the chat view can morph this bubble into
/// the typing bubble when the scan hands off to generation.
struct ScanningNetworkIndicator: View {

    var body: some View {
        ShimmeringText(text: String(localized: Strings.Chat.scanningNetwork))
            .font(.subheadline)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .platformGlassBackground(in: Capsule())
            .padding(.top, 6)
            // The scan happens for a known reason — the user asked a
            // live-state question — so a static-text status read
            // gives screen-reader users the right context. The
            // shimmer is purely visual and adds no semantic value
            // for VoiceOver; treating the row as one static-text
            // element keeps the announcement tight.
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Strings.Chat.scanningNetwork)
            .accessibilityAddTraits(.isStaticText)
            // Actively announce the scan status when the indicator
            // mounts. Without this, VoiceOver users get visual
            // feedback that their message was sent (their bubble
            // lands) but no auditory feedback during the ~3-second
            // scan window — the surface feels dead until the
            // assistant's first streamed token finally arrives.
            // The announcement fires once per mount; SwiftUI
            // unmounts the indicator when the scan finishes, so the
            // announcement doesn't loop.
            .onAppear {
                AccessibilityNotification.Announcement(
                    String(localized: Strings.Chat.scanningNetwork)
                ).post()
            }
    }
}

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
private struct ShimmeringText: View {

    let text: String

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

    var body: some View {
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
