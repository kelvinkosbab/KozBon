//
//  TabBarItem.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 8/21/23.
//  Copyright © 2023 Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - TabBarItem

enum TabBarItem : BarItem {
    
    case bonjour
    case bluetooth
    case information
    
    var id: String {
        switch self {
        case .bonjour:
            "bonjour"
        case .bluetooth:
            "bluetooth"
        case .information:
            "information"
        }
    }
    
    var titleString: String {
        switch self {
        case .bonjour:
            NSLocalizedString(
                "Bonjour",
                comment: "Bonjour tab title"
            )
        case .bluetooth:
            NSLocalizedString(
                "Bluetooth",
                comment: "Bluetooth tab title"
            )
        case .information:
            NSLocalizedString(
                "Information",
                comment: "Information tab title"
            )
        }
    }
    
    var icon: Image {
        switch self {
        case .bonjour:
            Image.bonjour
        case .bluetooth:
            Image.bluetoothCapsuleFill
        case .information:
            Image.infoCircleFill
        }
    }
    
    var content: AnyView {
        AnyView(BarItemLabel(item: self))
    }
    
    var destination: AnyView? {
        switch self {
        case .bonjour:
            AnyView(BonjourScanForServicesView())
        case .bluetooth:
            AnyView(BluetoothScanForDevicesView())
        case .information:
            AnyView(InformationView())
        }
    }
    
    var isSelectable: Bool {
        return true
    }
}
