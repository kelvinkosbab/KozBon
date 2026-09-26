//
//  AmbientMeshPalette.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - AmbientMeshPalette

/// Per-tab colour scheme for ``AmbientMeshBackground``.
///
/// Every palette anchors on brand blue and varies only its two
/// accents, so moving between tabs reads as the same water under a
/// slightly different sky rather than as four unrelated screens.
enum AmbientMeshPalette {

    case discover
    case library
    case preferences
    case chat

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

        // Brightest of the four, matching the chat surface's own
        // glass tinting.
        case .chat:        [.kozBonBlue, .cyan, .teal]
        }
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
