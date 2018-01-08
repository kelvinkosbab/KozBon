//
//  MyBluetoothManager+State.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 1/7/18.
//  Copyright © 2018 Kozinga. All rights reserved.
//

import Foundation
import CoreBluetooth

enum MyBluetoothManagerState {
  case poweredOff, poweredOn, resetting, unauthorized, unknown, unsupported
  
  static func convert(cbMManagerState state: CBManagerState) -> MyBluetoothManagerState {
    switch state {
    case .poweredOff: return .poweredOff
    case .poweredOn: return .poweredOn
    case .resetting: return .resetting
    case .unauthorized: return .unauthorized
    case .unknown: return .unknown
    case .unsupported: return .unsupported
    }
  }
}

extension CBManagerState {
  
  var string: String {
    switch self {
    case .poweredOff: return "Powered Off"
    case .poweredOn: return "Powered On"
    case .resetting: return "Resetting"
    case .unauthorized: return "Unauthorized"
    case .unknown: return "Unknown"
    case .unsupported: return "Unsupported"
    }
  }
  
  var isScanning: Bool {
    return self != .unknown && self != .unsupported && self != .poweredOff
  }
}
