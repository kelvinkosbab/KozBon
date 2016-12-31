//
//  SettingsTableViewController.swift
//  iDiscover
//
//  Created by Kelvin Kosbab on 12/31/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation
import UIKit

class SettingsTableViewController: MyTableViewController {
  
  // MARK: - Class Accessors
  
  static func newController() -> SettingsTableViewController {
    return self.newController(fromStoryboard: .settings, withIdentifier: self.name) as! SettingsTableViewController
  }
}
