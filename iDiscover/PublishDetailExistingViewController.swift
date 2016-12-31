//
//  PublishDetailExistingViewController.swift
//  iDiscover
//
//  Created by Kelvin Kosbab on 12/30/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation
import UIKit

class PublishDetailExistingViewController: MyTableViewController {
  
  // MARK: - Class Accessors
  
  static func newController(withServiceType serviceType: MyServiceType) -> PublishDetailExistingViewController {
    let viewController = self.newController(fromStoryboard: "Main", withIdentifier: self.name) as! PublishDetailExistingViewController
    viewController.serviceType = serviceType
    return viewController
  }
  
  // MARK: - Properties
  
  @IBOutlet weak var portTextField: UITextField!
  
  var serviceType: MyServiceType!
  
  // MARK: - Lifecycle
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    self.updateServiceContent()
  }
  
  // MARK: - Content
  
  func updateServiceContent() {
    self.title = self.serviceType.fullType
  }
}
