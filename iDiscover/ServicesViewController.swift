//
//  ServicesViewController.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 2/4/17.
//  Copyright © 2017 Kozinga. All rights reserved.
//

import Foundation
import UIKit

class ServicesViewController : MyCollectionViewController {
  
  // MARK: - Class Accessors
  
  static func newViewController() -> ServicesViewController {
    return self.newViewController(fromStoryboard: .main)
  }
  
  override var defaultViewTitle: String? {
    return "Bonjour Services"
  }
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
}
