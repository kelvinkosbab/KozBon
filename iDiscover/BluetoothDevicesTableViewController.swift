//
//  BluetoothDevicesTableViewController.swift
//  iDiscover
//
//  Created by Kelvin Kosbab on 12/29/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation
import UIKit

class BluetoothDevicesTableViewController: MyTableViewController {
  
  // MARK: - Class Accessors
  
  static func newController() -> BluetoothDevicesTableViewController {
    return self.newController(fromStoryboard: "Main", withIdentifier: self.name) as! BluetoothDevicesTableViewController
  }
  
  // MARK: - Properties
  
  // MARK: - Lifecycle
}
