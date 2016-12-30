//
//  PublishDetailCreateViewController.swift
//  iDiscover
//
//  Created by Kelvin Kosbab on 12/30/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation
import UIKit

class PublishDetailCreateViewController: MyTableViewController {
  
  // MARK: - Class Accessors
  
  static func newController() -> PublishDetailCreateViewController {
    return self.newController(fromStoryboard: "Main", withIdentifier: self.name) as! PublishDetailCreateViewController
  }
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.title = "Create a Service"
  }
}
