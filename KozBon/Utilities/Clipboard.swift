//
//  Clipboard.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 3/21/26.
//  Copyright © 2026 Kozinga. All rights reserved.
//

#if os(macOS)
import AppKit
#else
import UIKit
#endif

// MARK: - Clipboard

enum Clipboard {
    static func copy(_ string: String) {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
        #else
        UIPasteboard.general.string = string
        #endif
    }
}
