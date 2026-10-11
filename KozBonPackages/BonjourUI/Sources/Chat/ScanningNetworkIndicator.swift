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
