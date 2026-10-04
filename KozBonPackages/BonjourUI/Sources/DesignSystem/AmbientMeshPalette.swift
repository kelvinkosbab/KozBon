//
//  AmbientMeshPalette.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourAICore

// MARK: - AmbientMeshPalette

/// Per-tab colour scheme for ``AmbientMeshBackground``.
///
/// The three browsing tabs anchor on brand blue and vary only their
/// two accents, so moving between them reads as the same water
/// under a slightly different sky rather than as unrelated screens.
///
/// Chat is the exception: it takes the colours of whichever AI
/// backend is answering, the same cue ``AIBackend/accentColor``
/// gives the send button and bubbles, carried into the wash.
enum AmbientMeshPalette: Hashable {

    case discover
    case library
    case preferences
    case chat(AIBackend)

    /// Where each accent sits in the 4×4 mesh. Shared across
    /// palettes so the *shape* of the wash is identical everywhere
    /// and only the hues change.
    ///
    /// `0` is the anchor, `1` and `2` are the palette's accents. The
    /// anchor takes the majority of cells; the accents are scattered
    /// so no two of the same hue are edge-adjacent, which is what
    /// keeps a crest changing colour as it travels.
    static let accentLayout: [Int] = [
        0, 1, 2, 0,
        1, 0, 0, 2,
        2, 0, 1, 0,
        0, 2, 0, 1
    ]

    /// The sixteen mesh hues, before ``AmbientMeshBackground``
    /// applies its travelling alpha.
    var hues: [Color] {
        let accents = self.accents
        return Self.accentLayout.map { accents[$0] }
    }

    /// Phase offset applied to every wave, in radians.
    ///
    /// Distinct per tab so switching tabs doesn't land on the same
    /// frame of the same wave — the wash reads as a different patch
    /// of the same water.
    var phaseOffset: Float {
        switch self {
        case .discover:    0
        case .library:     1.7
        case .preferences: 3.3
        case .chat:        4.9
        }
    }

    /// Anchor hue plus the palette's two accents, indexed by
    /// ``accentLayout``.
    private var accents: [Color] {
        switch self {
        // Cyan and indigo — the widest hue spread, for the tab
        // that carries the most content.
        case .discover:    [.kozBonBlue, .cyan, .indigo]

        // Teal pulls slightly greener than Discover's cyan, which
        // separates the reference list from the live one.
        case .library:     [.kozBonBlue, .teal, .indigo]

        // Coolest and most muted of the four. Settings is a place
        // to read carefully, so the accents sit closest to the
        // anchor.
        case .preferences: [.kozBonBlue, .indigo, .purple]

        case .chat(let backend): Self.chatAccents(for: backend)
        }
    }

    /// Each provider's own brand colours, anchored on the backend's
    /// accent so the wash and the send button agree.
    private static func chatAccents(for backend: AIBackend) -> [Color] {
        switch backend {
        // Apple Intelligence's glow runs blue → purple → pink →
        // orange. Purple and orange take the accent cells, and the
        // mesh's colour smoothing blends pink between them.
        case .appleIntelligence:
            [.kozBonBlue, Color(hex: 0xC959DD), Color(hex: 0xFF9004)]

        // Anthropic's "Kraft" and "Crail" either side of the Claude
        // orange: one lighter, one deeper, so the warm wash still
        // has depth.
        case .anthropic:
            [.kozBonAnthropic, Color(hex: 0xD4A27F), Color(hex: 0xC15F3C)]

        // The three stops of the Gemini spark's gradient.
        case .gemini:
            [.kozBonGemini, Color(hex: 0x9168C0), Color(hex: 0x1BA1E3)]

        // OpenAI's mark is monochrome, so the wash takes ChatGPT's
        // greens: a brighter green and a muted sage.
        case .openai:
            [.kozBonOpenAI, Color(hex: 0x19C37D), Color(hex: 0x74AA9C)]
        }
    }
}

// MARK: - Color + Hex

private extension Color {

    /// An sRGB colour from a `0xRRGGBB` literal — brand palettes are
    /// published as hex.
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

// MARK: - AmbientMeshIntensity

/// How strongly ``AmbientMeshBackground`` reads on a given surface.
enum AmbientMeshIntensity {

    /// The full wash, used on the surface the user is working in.
    case standard

    /// A lighter variant for the secondary surface beside a
    /// standard one.
    ///
    /// On a wide layout — iPad, landscape iPhone, the Duo unfolded,
    /// macOS — the split view shows a list and a detail column at
    /// the same time. Two wide washes at equal strength compete for
    /// attention and make the window read as two unrelated screens,
    /// so the placeholder column ("Select a service") takes this
    /// lighter variant: clearly the same water, clearly the
    /// secondary half of the window.
    case subdued

    /// Multiplier applied to the wash's overall opacity.
    var opacityScale: Double {
        switch self {
        case .standard: 1.0
        case .subdued:  0.5
        }
    }
}
