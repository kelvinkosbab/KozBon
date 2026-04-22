//
//  DesignTokens.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - Semantic Design Tokens
//
// Named constants for spacing, sizing, corner radius, and stroke width based on
// a 4pt grid. Using numeric suffixes (`.space16`, `.size16`) makes the intended
// point value obvious at the call site while still decoupling it from the raw
// literal — we can globally adjust a token later without a project-wide
// find-and-replace.
//
// Namespaces (pick the one that matches your intent — today they share values
// but keeping them separate lets us scale them independently in the future):
//
// - `.space*`  — whitespace, padding, `HStack`/`VStack` spacing
// - `.size*`   — fixed widths/heights (icons, avatars, touch targets)
// - `.radius*` — corner radius on shapes, cards, material capsules
// - `.stroke*` — border and divider widths
//
// Example usage:
//
// ```swift
// VStack(spacing: .space12) { ... }
//     .padding(.space16)
//     .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: .radius12))
//     .overlay(
//         RoundedRectangle(cornerRadius: .radius12)
//             .stroke(Color.secondary, lineWidth: .stroke1)
//     )
//
// Image(systemName: "antenna")
//     .frame(width: .size24, height: .size24)
// ```
//
// All tokens are defined on `CGFloat` because every SwiftUI layout API
// (`padding`, `frame(width:height:)`, `cornerRadius`, `lineWidth`, stack
// `spacing`) takes `CGFloat` — so the tokens drop in wherever you'd otherwise
// write a numeric literal.

// MARK: - Spacing

public extension CGFloat {

    /// 2pt whitespace.
    static let space2: CGFloat = 2

    /// 4pt whitespace.
    static let space4: CGFloat = 4

    /// 6pt whitespace.
    static let space6: CGFloat = 6

    /// 8pt whitespace.
    static let space8: CGFloat = 8

    /// 10pt whitespace.
    static let space10: CGFloat = 10

    /// 12pt whitespace.
    static let space12: CGFloat = 12

    /// 14pt whitespace.
    static let space14: CGFloat = 14

    /// 16pt whitespace — the canonical baseline for row padding, card
    /// padding, and section spacing.
    static let space16: CGFloat = 16

    /// 20pt whitespace.
    static let space20: CGFloat = 20

    /// 24pt whitespace.
    static let space24: CGFloat = 24

    /// 28pt whitespace.
    static let space28: CGFloat = 28

    /// 32pt whitespace.
    static let space32: CGFloat = 32

    /// 40pt whitespace.
    static let space40: CGFloat = 40

    /// 48pt whitespace.
    static let space48: CGFloat = 48

    /// 56pt whitespace.
    static let space56: CGFloat = 56

    /// 64pt whitespace.
    static let space64: CGFloat = 64

    /// 80pt whitespace.
    static let space80: CGFloat = 80

    /// 96pt whitespace.
    static let space96: CGFloat = 96
}

// MARK: - Sizes

public extension CGFloat {

    /// 4pt element dimension — sub-icon detail.
    static let size4: CGFloat = 4

    /// 6pt element dimension — typing indicator dot, micro glyph.
    static let size6: CGFloat = 6

    /// 8pt element dimension.
    static let size8: CGFloat = 8

    /// 12pt element dimension — badge, pill detail.
    static let size12: CGFloat = 12

    /// 14pt element dimension.
    static let size14: CGFloat = 14

    /// 16pt element dimension — small icon, inline glyph.
    static let size16: CGFloat = 16

    /// 20pt element dimension — inline icon.
    static let size20: CGFloat = 20

    /// 24pt element dimension — list icon, menu icon.
    static let size24: CGFloat = 24

    /// 28pt element dimension.
    static let size28: CGFloat = 28

    /// 32pt element dimension — toolbar icon, small avatar.
    static let size32: CGFloat = 32

    /// 40pt element dimension.
    static let size40: CGFloat = 40

    /// 44pt element dimension — Apple HIG minimum touch target.
    static let size44: CGFloat = 44

    /// 48pt element dimension — medium avatar.
    static let size48: CGFloat = 48

    /// 56pt element dimension.
    static let size56: CGFloat = 56

    /// 64pt element dimension — large avatar.
    static let size64: CGFloat = 64

    /// 80pt element dimension.
    static let size80: CGFloat = 80

    /// 96pt element dimension.
    static let size96: CGFloat = 96

    /// 120pt element dimension — hero illustration.
    static let size120: CGFloat = 120
}

// MARK: - Corner Radius

public extension CGFloat {

    /// 2pt corner radius — hairline rounding.
    static let radius2: CGFloat = 2

    /// 4pt corner radius — form controls.
    static let radius4: CGFloat = 4

    /// 6pt corner radius — chips, badges.
    static let radius6: CGFloat = 6

    /// 8pt corner radius — small cards.
    static let radius8: CGFloat = 8

    /// 10pt corner radius — iOS default continuous rounded rectangle.
    static let radius10: CGFloat = 10

    /// 12pt corner radius — cards, sheets, message bubbles.
    static let radius12: CGFloat = 12

    /// 16pt corner radius — large cards.
    static let radius16: CGFloat = 16

    /// 20pt corner radius — featured cards.
    static let radius20: CGFloat = 20

    /// 24pt corner radius — hero surfaces.
    static let radius24: CGFloat = 24

    /// 32pt corner radius.
    static let radius32: CGFloat = 32
}

// MARK: - Stroke Widths

public extension CGFloat {

    /// 0.5pt stroke — hairline divider (matches UIKit separator weight).
    static let strokeHairline: CGFloat = 0.5

    /// 1pt stroke — default border.
    static let stroke1: CGFloat = 1

    /// 2pt stroke.
    static let stroke2: CGFloat = 2

    /// 3pt stroke.
    static let stroke3: CGFloat = 3

    /// 4pt stroke — emphasis / focus ring.
    static let stroke4: CGFloat = 4
}
