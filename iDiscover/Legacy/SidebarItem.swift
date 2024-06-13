//
//  SidebarItem.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 8/21/23.
//  Copyright © 2023 Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - SidebarItem

enum SidebarItem: BarItem {

    case bonjourScanForActiveServices
    case bonjourSupportedServices
    case bonjourCreateService
    case bluetooth
    case appInformation

    var id: String {
        switch self {
        case .bonjourScanForActiveServices:
            "bonjour"
        case .bonjourSupportedServices:
            "bonjourSupportedServices"
        case .bonjourCreateService:
            "bonjourCreateService"
        case .bluetooth:
            "bluetooth"
        case .appInformation:
            "appInformation"
        }
    }

    var titleString: String {
        switch self {
        case .bonjourScanForActiveServices:
            NSLocalizedString(
                "Scan for Active Services",
                comment: "Scan for Active Services tab title"
            )
        case .bonjourSupportedServices:
            NSLocalizedString(
                "Supported Bonjour Services",
                comment: "Supported Bonjour Services tab title"
            )
        case .bonjourCreateService:
            NSLocalizedString(
                "Broadcast a Bonjour Service",
                comment: "Broadcast a Bonjour Service tab title"
            )
        case .bluetooth:
            NSLocalizedString(
                "Bluetooth",
                comment: "Bluetooth tab title"
            )
        case .appInformation:
            NSLocalizedString(
                "App Information",
                comment: "Information tab title"
            )
        }
    }

    var icon: Image {
        switch self {
        case .bonjourScanForActiveServices:
            Image.bonjour
        case .bonjourSupportedServices:
            Image.listBulletRectanglePortraitFill
        case .bonjourCreateService:
            Image.plusDiamondFill
        case .bluetooth:
            Image.bluetoothCapsuleFill
        case .appInformation:
            Image.infoCircleFill
        }
    }

    var content: AnyView {
        switch self {
        case .bonjourScanForActiveServices:
            AnyView(BarItemLabel(item: self))
        case .bonjourSupportedServices:
            AnyView(BarItemLabel(item: self))
        case .bonjourCreateService:
            AnyView(BarItemLabel(item: self))
        case .bluetooth:
            AnyView(BarItemLabel(item: self))
        case .appInformation:
            AnyView(Text("KAK TODO - appInformation"))
        }
    }

    var destination: AnyView? {
        switch self {
        case .bonjourScanForActiveServices:
            AnyView(BonjourScanForServicesView())
        case .bonjourSupportedServices:
            AnyView(Text("supportedServiceTypes"))
        case .bonjourCreateService:
            AnyView(Text("createBonjourServiceType"))
        case .bluetooth:
            AnyView(BluetoothScanForDevicesView())
        case .appInformation:
            nil
        }
    }

    var isSelectable: Bool {
        switch self {
        case .appInformation:
            return false
        default:
            return true
        }
    }
}
