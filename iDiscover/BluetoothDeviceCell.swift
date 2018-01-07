//
//  BluetoothDeviceCell.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 1/28/17.
//  Copyright © 2017 Kozinga. All rights reserved.
//

import Foundation
import UIKit

class BluetoothDeviceCell : UITableViewCell {
  @IBOutlet weak private var titleLabel: UILabel!
  @IBOutlet weak private var detailLabel: UILabel!
  
  var device: MyBluetoothDevice? = nil
  
  func configure(device: MyBluetoothDevice) {
    self.device = device
    device.delegate = self
    self.titleLabel.text = device.name
    self.detailLabel.text  = "Total Services: \(device.services.count)"
  }
}

// MARK: - MyBluetoothDeviceDelegate

extension BluetoothDeviceCell : MyBluetoothDeviceDelegate {
  
  func didUpdate(_ device: MyBluetoothDevice) {
    self.configure(device: device)
  }
}
