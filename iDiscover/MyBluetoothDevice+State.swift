//
//  MyBluetoothDevice+State.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 1/25/17.
//  Copyright © 2017 Kozinga. All rights reserved.
//

import Foundation
import CoreBluetooth

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
}
