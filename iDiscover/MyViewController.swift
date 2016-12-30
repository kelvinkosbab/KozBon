//
//  MyViewController.swift
//  iDiscover
//
//  Created by Kelvin Kosbab on 12/29/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation
import UIKit

class MyViewController: UIViewController {
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.navigationItem.backBarButtonItem = UIBarButtonItem(text: "")
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
}
