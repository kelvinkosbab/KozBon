//
//  Clipboard.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

#if os(macOS)
import AppKit
#else
import UIKit
#endif

// MARK: - Clipboard

/// A platform-agnostic clipboard utility for copying text to the system pasteboard.
///
/// On macOS this uses `NSPasteboard`; on iOS, tvOS, and visionOS it uses `UIPasteboard`.
public enum Clipboard {

    /// Copies the given string to the system pasteboard.
    ///
    /// - Parameter string: The text to place on the clipboard.
    public static func copy(_ string: String) {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
        #else
        UIPasteboard.general.string = string
        #endif
    }
}
