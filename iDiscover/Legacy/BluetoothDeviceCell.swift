//
//  BluetoothDeviceCell.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 1/28/17.
//  Copyright © 2017 Kozinga. All rights reserved.
//

import Foundation
import UIKit

class BluetoothDeviceCell: UITableViewCell {
  @IBOutlet weak private var titleLabel: UILabel!
  @IBOutlet weak private var detailLabel: UILabel!

  weak var device: BluetoothDevice?

  func configure(device: BluetoothDevice) {
    self.device = device
      self.configure(title: device.name, detail: device.uuid.uuidString)
  }

  func configure(title: String?, detail: String?) {
    self.titleLabel.text = title
    self.detailLabel.text = detail
  }
}
