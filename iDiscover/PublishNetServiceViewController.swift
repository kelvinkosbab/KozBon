//
//  PublishNetServiceViewController.swift
//  iDiscover
//
//  Created by Kelvin Kosbab on 12/29/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation
import UIKit

class PublishNetServiceViewController: MyTableViewController {
  
  // MARK: - Class Accessors
  
  static func newController() -> PublishNetServiceViewController {
    return self.newController(fromStoryboard: "Main", withIdentifier: self.name) as! PublishNetServiceViewController
  }
}
