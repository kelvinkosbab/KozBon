//
//  MyBluetoothDevice.swift
//  iDiscover
//
//  Created by Kelvin Kosbab on 12/26/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation
import CoreBluetooth

class MyBluetoothDevice: Equatable {
  
  // Equatable
  
  static func ==(lhs: MyBluetoothDevice, rhs: MyBluetoothDevice) -> Bool {
    return lhs.peripheral.identifier == rhs.peripheral.identifier
  }
  
  // MARK: - Properties and Init
  
  let peripheral: CBPeripheral
  
  init(peripheral: CBPeripheral) {
    self.peripheral = peripheral
  }
}
