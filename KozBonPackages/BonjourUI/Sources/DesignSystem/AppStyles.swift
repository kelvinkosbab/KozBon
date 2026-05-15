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
    /// Microsoft's published "Copilot purple" (#8534F3) — same
    /// hue used across Copilot product surfaces. Lifted toward
    /// higher lightness in dark mode (#A872FF) so contrast
    /// against a dark background stays comfortably AA, since
    /// the base value sits right at the threshold.
    /// Light: #8534F3, Dark: #A872FF
    static let kozBonGitHub = Color(.kozBonGitHub)
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
                red: 0xA8 / 255.0,
                green: 0x72 / 255.0,
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
                red: 0xA8 / 255.0,
                green: 0x72 / 255.0,
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
}
#endif
