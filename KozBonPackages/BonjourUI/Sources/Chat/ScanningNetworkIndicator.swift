//
//  ScanningNetworkIndicator.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
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
struct ScanningNetworkIndicator: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack {
            ShimmeringText(text: String(localized: Strings.Chat.scanningNetwork))
                .font(.subheadline)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        // The scan happens for a known reason — the user asked a
        // live-state question — so a static-text status read
        // gives screen-reader users the right context. The
        // shimmer is purely visual and adds no semantic value
        // for VoiceOver; treating the row as one static-text
        // element keeps the announcement tight.
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: Strings.Chat.scanningNetwork))
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
    @State private var animate = false

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

    // MARK: - Body

    var body: some View {
        if reduceMotion {
            Text(text)
                .foregroundStyle(.secondary)
        } else {
            shimmeringBody
        }
    }

    private var shimmeringBody: some View {
        Text(text)
            .foregroundStyle(.secondary)
            .overlay {
                GeometryReader { geometry in
                    let width = geometry.size.width
                    let bandWidth = width * Self.bandWidthFraction
                    // The bright band starts fully off the
                    // leading edge (offset = -bandWidth) and ends
                    // fully off the trailing edge (offset =
                    // width). That keeps the highlight from
                    // popping in/out abruptly — it slides smoothly
                    // through the text region.
                    Text(text)
                        .foregroundStyle(.primary)
                        // Hidden from the accessibility tree —
                        // it's a duplicate of the base text used
                        // purely for the shimmer overlay. The
                        // outer indicator already supplies one
                        // explicit label via
                        // `.accessibilityLabel(...)`; without
                        // this hide the duplicate Text lingers
                        // in the tree as dead weight.
                        .accessibilityHidden(true)
                        .mask {
                            // The mask is a soft-edged
                            // rectangular band. Where the
                            // gradient is opaque, the .primary
                            // overlay shows through; where it's
                            // clear, the base .secondary text
                            // shows. The two flanking clear
                            // stops feather the leading and
                            // trailing edges so the band fades
                            // in/out rather than swiping a hard
                            // line across.
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [.clear, .black, .clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: bandWidth)
                                .offset(x: animate ? width : -bandWidth)
                        }
                }
                // Tell the GeometryReader not to grab vertical
                // space — without this, the reader expands to
                // fill the chat row's height and the band's
                // vertical alignment drifts.
                .allowsHitTesting(false)
            }
            .onAppear {
                // Kick off the repeating sweep on the first
                // body render. SwiftUI captures the animation
                // configuration at this withAnimation call;
                // toggling `animate` again later does nothing
                // because the value is already in its end
                // state. That's the desired behavior — the
                // indicator only renders while the scan is in
                // flight, so a single onAppear is enough.
                withAnimation(
                    .linear(duration: Self.sweepDuration)
                        .repeatForever(autoreverses: false)
                ) {
                    animate = true
                }
            }
    }
}
