//
//  MyBluetoothDevice+State.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 1/25/17.
//  Copyright © 2017 Kozinga. All rights reserved.
//

import Foundation
import CoreBluetooth
import UIKit

extension CBPeripheralState {
  
  var isDisconnecting: Bool {
    return self == .disconnecting
  }
  
  var isDisconnected: Bool {
    return self == .disconnected
  }
  
  var isConnecting: Bool {
    return self == .connecting
  }
  
  var isConnected: Bool {
    return self == .connected
  }
  
  var icon: UIImage {
    switch self {
    case .connected:
      return #imageLiteral(resourceName: "icSignal")
    case .connecting:
      return #imageLiteral(resourceName: "icReload")
    case .disconnecting:
      return #imageLiteral(resourceName: "icReload")
    case .disconnected:
      return #imageLiteral(resourceName: "icCross")
    }
  }
}
