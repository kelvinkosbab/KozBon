//
//  DesignTokens.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - Semantic Design Tokens
//
// Named constants for spacing, sizing, and corner radius. The numeric
// suffix makes the point value obvious at the call site while keeping it
// decoupled from the raw literal, so a token can be retuned globally
// without a project-wide find-and-replace.
//
// - `.space*`  — whitespace, padding, `HStack`/`VStack` spacing
// - `.size*`   — fixed widths/heights (icons, touch targets)
// - `.radius*` — corner radius on shapes, cards, material capsules
//
// This is intentionally only the set that's in use. The file previously
// published a full 4pt scale (51 tokens across four namespaces) of which
// six were ever referenced; the rest were dead public API on `CGFloat`.
// Add a rung when a call site needs it, not in anticipation.
//
// All tokens extend `CGFloat` because every SwiftUI layout API
// (`padding`, `frame(width:height:)`, `cornerRadius`, stack `spacing`)
// takes `CGFloat`, so they drop in wherever a numeric literal would go.

// MARK: - Spacing

public extension CGFloat {

    /// 6pt whitespace.
    static let space6: CGFloat = 6

    /// 8pt whitespace.
    static let space8: CGFloat = 8

    /// 14pt whitespace.
    static let space14: CGFloat = 14
}

// MARK: - Sizes

public extension CGFloat {

    /// 32pt element dimension — toolbar icon, small avatar.
    static let size32: CGFloat = 32

    /// 44pt element dimension — Apple HIG minimum touch target.
    static let size44: CGFloat = 44
}

// MARK: - Corner Radius

public extension CGFloat {

    /// 20pt corner radius — featured cards, input capsules.
    static let radius20: CGFloat = 20
}
