//
//  MyBluetoothService.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 1/28/17.
//  Copyright © 2017 Kozinga. All rights reserved.
//

import Foundation
import CoreBluetooth

class MyBluetoothService : Equatable {
  
  // MARK: Equatable
  
  static func ==(lhs: MyBluetoothService, rhs: MyBluetoothService) -> Bool {
    return lhs.service == rhs.service
  }
  
  // MARK: - Properties and Init
  
  let device: MyBluetoothDevice
  private let service: CBService
  
  init(device: MyBluetoothDevice, service: CBService) {
    self.device = device
    self.service = service
  }
}
