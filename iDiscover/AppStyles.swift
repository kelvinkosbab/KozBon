//
//  AppStyles.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 8/20/23.
//  Copyright © 2023 Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - Colors

extension Color {
    
    static let kozBonBlue: Color = Color.blue // KAK TODO
}

// MARK: - Images

extension Image {
    
    // MARK: - Custom Images
    
    static let bonjour = Image("iconBonjour")
    static let bluetooth = Image("iconBluetooth")
    
    // MARK: - SF Symbols
    
    static let infoCircleFill = Image(systemName: "info.circle.fill")
    static let plusDiamondFill = Image(systemName: "plus.diamond.fill")
    static let listBulletRectanglePortraitFill = Image(systemName: "list.bullet.rectangle.portrait.fill")
}
