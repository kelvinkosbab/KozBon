//
//  AppStyles.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - Images

extension Image {

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
