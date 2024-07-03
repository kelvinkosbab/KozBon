//
//  CBManagerState+Util.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 1/7/18.
//  Copyright © 2018 Kozinga. All rights reserved.
//

import Foundation
import CoreBluetooth

// MARK: - CBManagerState+Util

extension CBManagerState {

    var string: String {
        switch self {
        case .poweredOff:
            return NSLocalizedString("Powered Off", comment: "Bluetooth powered off state")
        case .poweredOn:
            return NSLocalizedString("Powered On", comment: "Bluetooth powered on state")
        case .resetting:
            return NSLocalizedString("Resetting", comment: "Bluetooth resetting state")
        case .unauthorized:
            return NSLocalizedString("Unauthorized", comment: "Bluetooth unauthorized state")
        case .unknown:
            return NSLocalizedString("Unknown", comment: "Bluetooth unknown state")
        case .unsupported:
            return NSLocalizedString("Unsupported", comment: "Bluetooth unsupported state")
        @unknown default:
            fatalError("Unsupported bluetooth manager state: \(self)")
        }
    }

    var isScanning: Bool {
        return self != .unknown && self != .unsupported && self != .poweredOff
    }
}
