//
//  CBPeripheralState+Util.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 9/15/23.
//  Copyright © 2023 Kozinga. All rights reserved.
//

import Foundation
import CoreBluetooth

// MARK: - CBPeripheralState

extension CBPeripheralState {

    var string: String {
        switch self {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting"
        case .disconnected:
            return "Disconnected"
        case .disconnecting:
            return "Disconnecting"
        @unknown default:
            fatalError("Unsupported bluetooth peripheral state: \(self)")
        }
    }
}
