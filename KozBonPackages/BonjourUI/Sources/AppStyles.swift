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
    /// KozBon brand blue color with light/dark mode support.
    ///
    /// Light: #2980B9, Dark: #3498DB
    static let kozBonBlue = Color(.kozBonBlue)
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
}
#endif

