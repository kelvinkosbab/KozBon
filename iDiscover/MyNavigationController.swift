//
//  MyNavigationController.swift
//  iDiscover
//
//  Created by Kelvin Kosbab on 12/29/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation
import UIKit

class MyNavigationController: UINavigationController {
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.styleTitleText()
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  // MARK: - Styles
  
  func styleTitleText() {
    self.navigationBar.titleTextAttributes = [ NSFontAttributeName : UIFont.systemFont(ofSize: 18) ]
  }
}
