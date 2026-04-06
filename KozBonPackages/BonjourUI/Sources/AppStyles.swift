//
//  AppStyles.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI

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

// MARK: - Images

public extension Image {

    // MARK: - Custom Images

    static var bluetooth: Image {
        Image("bluetooth")
            .renderingMode(.template)
    }

    static var bluetoothCapsuleFill: Image {
        Image("bluetooth.capsule.fill")
            .renderingMode(.template)
    }

    // MARK: - SF Symbols

    static var bonjour: Image {
        Image(systemName: "bonjour")
    }

    static var arrowUpArrowDownCircleFill: Image {
        Image(systemName: "arrow.up.arrow.down.circle.fill")
    }

    static var plusCircleFill: Image {
        Image(systemName: "plus.circle.fill")
    }
}
