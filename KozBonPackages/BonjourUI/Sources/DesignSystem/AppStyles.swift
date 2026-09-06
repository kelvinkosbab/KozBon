//
//  AppStyles.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourCore

// MARK: - Colors

public extension Color {
    /// KozBon brand blue. Used as the global tint and as the
    /// accent for AI surfaces when the user is on the on-device
    /// Apple Intelligence backend.
    ///
    /// Light: #2980B9, Dark: #3498DB
    static let kozBonBlue = Color(.kozBonBlue)

    /// Anthropic Claude brand orange. Used as the accent for AI
    /// surfaces (chat send button, suggestion-chip backgrounds,
    /// chat-tab tint and icon) when the user has selected the
    /// Anthropic backend, so the surface telegraphs which
    /// provider is answering before they even read the response.
    ///
    /// Approximation of Anthropic's published "Cara" brand orange
    /// (#CC785C). We render it as a single value across light /
    /// dark — the brand color has no light / dark variant in
    /// Anthropic's guidelines, but we lighten slightly in dark
    /// mode so it doesn't read muddy against a dark background.
    /// Light: #CC785C, Dark: #E89B82
    static let kozBonAnthropic = Color(.kozBonAnthropic)

    /// GitHub Models brand mark. Used as the accent for AI
    /// surfaces when the user has selected the GitHub backend.
    ///
    /// Microsoft's published "Copilot purple" (#8534F3). Lifted
    /// modestly in dark mode (#9444FF) — enough to keep purple
    /// icons legible on dark backgrounds (≥AA Large at 3.64:1)
    /// while keeping white-text-on-purple comfortably AA Normal
    /// at 4.65:1 for the chat send button and user message
    /// bubble (which are the dominant uses of the accent).
    /// Light: #8534F3, Dark: #9444FF
    static let kozBonGitHub = Color(.kozBonGitHub)

    /// Google Gemini brand mark. Used as the accent for AI
    /// surfaces when the user has selected the Gemini backend.
    ///
    /// Google's published blues rather than the logo's
    /// blue-to-purple gradient, which a single accent token can't
    /// express: #1A73E8 light, #8AB4F8 dark — the pair Google
    /// itself ships for the two modes, so contrast is already
    /// tuned (white-on-#1A73E8 is 4.68:1, AA Normal; #8AB4F8 on a
    /// dark ground is 8.6:1).
    ///
    /// Distinct enough from ``kozBonBlue`` (#2980B9, a muted
    /// steel) not to blur the on-device-vs-Gemini cue — the two
    /// differ in saturation more than hue, and the icon differs
    /// as well.
    /// Light: #1A73E8, Dark: #8AB4F8
    static let kozBonGemini = Color(.kozBonGemini)
}

#if canImport(UIKit)
import UIKit

extension UIColor {
    static let kozBonBlue = UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            return UIColor(
                red: 0x34 / 255.0,
                green: 0x98 / 255.0,
                blue: 0xDB / 255.0,
                alpha: 1.0
            )
        default:
            return UIColor(
                red: 0x29 / 255.0,
                green: 0x80 / 255.0,
                blue: 0xB9 / 255.0,
                alpha: 1.0
            )
        }
    }

    static let kozBonAnthropic = UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            return UIColor(
                red: 0xE8 / 255.0,
                green: 0x9B / 255.0,
                blue: 0x82 / 255.0,
                alpha: 1.0
            )
        default:
            return UIColor(
                red: 0xCC / 255.0,
                green: 0x78 / 255.0,
                blue: 0x5C / 255.0,
                alpha: 1.0
            )
        }
    }

    static let kozBonGitHub = UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            return UIColor(
                red: 0x94 / 255.0,
                green: 0x44 / 255.0,
                blue: 0xFF / 255.0,
                alpha: 1.0
            )
        default:
            return UIColor(
                red: 0x85 / 255.0,
                green: 0x34 / 255.0,
                blue: 0xF3 / 255.0,
                alpha: 1.0
            )
        }
    }

    static let kozBonGemini = UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            return UIColor(
                red: 0x8A / 255.0,
                green: 0xB4 / 255.0,
                blue: 0xF8 / 255.0,
                alpha: 1.0
            )
        default:
            return UIColor(
                red: 0x1A / 255.0,
                green: 0x73 / 255.0,
                blue: 0xE8 / 255.0,
                alpha: 1.0
            )
        }
    }
}
#elseif canImport(AppKit)
import AppKit

extension NSColor {
    static let kozBonBlue = NSColor(name: nil) { appearance in
        if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            return NSColor(
                red: 0x34 / 255.0,
                green: 0x98 / 255.0,
                blue: 0xDB / 255.0,
                alpha: 1.0
            )
        } else {
            return NSColor(
                red: 0x29 / 255.0,
                green: 0x80 / 255.0,
                blue: 0xB9 / 255.0,
                alpha: 1.0
            )
        }
    }

    static let kozBonAnthropic = NSColor(name: nil) { appearance in
        if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            return NSColor(
                red: 0xE8 / 255.0,
                green: 0x9B / 255.0,
                blue: 0x82 / 255.0,
                alpha: 1.0
            )
        } else {
            return NSColor(
                red: 0xCC / 255.0,
                green: 0x78 / 255.0,
                blue: 0x5C / 255.0,
                alpha: 1.0
            )
        }
    }

    static let kozBonGitHub = NSColor(name: nil) { appearance in
        if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            return NSColor(
                red: 0x94 / 255.0,
                green: 0x44 / 255.0,
                blue: 0xFF / 255.0,
                alpha: 1.0
            )
        } else {
            return NSColor(
                red: 0x85 / 255.0,
                green: 0x34 / 255.0,
                blue: 0xF3 / 255.0,
                alpha: 1.0
            )
        }
    }

    static let kozBonGemini = NSColor(name: nil) { appearance in
        if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            return NSColor(
                red: 0x8A / 255.0,
                green: 0xB4 / 255.0,
                blue: 0xF8 / 255.0,
                alpha: 1.0
            )
        } else {
            return NSColor(
                red: 0x1A / 255.0,
                green: 0x73 / 255.0,
                blue: 0xE8 / 255.0,
                alpha: 1.0
            )
        }
    }
}
#endif
