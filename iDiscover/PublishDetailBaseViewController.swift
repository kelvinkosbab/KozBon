//
//  PublishDetailBaseViewController.swift
//  iDiscover
//
//  Created by Kelvin Kosbab on 12/30/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation
import UIKit

class PublishDetailBaseViewController: MyViewController {
  
  // MARK: - Class Accessors
  
  static func newController() -> PublishDetailBaseViewController {
    return self.newController(fromStoryboard: "Main", withIdentifier: self.name) as! PublishDetailBaseViewController
  }
}
