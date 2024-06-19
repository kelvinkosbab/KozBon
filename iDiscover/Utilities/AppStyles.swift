//
//  AppStyles.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 8/20/23.
//  Copyright © 2023 Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - Images

extension Image {

    // MARK: - Custom Images

    static var bonjour: Image {
        Image(systemName: "bonjour")
    }

    static var bluetooth: Image {
        Image("bluetooth")
            .renderingMode(.template)
    }

    static var bluetoothCapsuleFill: Image {
        Image("bluetooth.capsule.fill")
            .renderingMode(.template)
    }

    // MARK: - SF Symbols

    static var arrowClockwiseCircleFill: Image {
        Image(systemName: "arrow.clockwise.circle.fill")
    }

    static var arrowUpArrowDownCircleFill: Image {
        Image(systemName: "arrow.up.arrow.down.circle.fill")
    }

    static var chevronRight: Image {
        Image(systemName: "chevron.right")
    }

    static var plusCircleFill: Image {
        Image(systemName: "plus.circle.fill")
    }

    static var plusDiamondFill: Image {
        Image(systemName: "plus.diamond.fill")
    }

    static var listBulletRectanglePortraitFill: Image {
        Image(systemName: "list.bullet.rectangle.portrait.fill")
    }
}
