//
//  BluetoothDeviceDetailViewController.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 1/7/18.
//  Copyright © 2018 Kozinga. All rights reserved.
//

import UIKit

class BluetoothDeviceDetailViewController : MyTableViewController {
  
  // MARK: - Class Accessors
  
  private static func newViewController() -> BluetoothDeviceDetailViewController {
    return self.newViewController(fromStoryboard: .main)
  }
  
  static func newViewController(device: MyBluetoothDevice) -> BluetoothDeviceDetailViewController {
    let viewController = self.newViewController()
    viewController.device = device
    return viewController
  }
  
  // MARK: - Properties
  
  var device: MyBluetoothDevice? = nil
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.title = self.device?.name
    
    if self.navigationController?.viewControllers.first == self {
      self.navigationItem.leftBarButtonItem = UIBarButtonItem(text: "Done", target: self, action: #selector(self.doneButtonSelected(_:)))
    }
  }
  
  // MARK: - Content
  
  func reloadContent() {
    
  }
  
  // MARK: - Actions
  
  @objc private func doneButtonSelected(_ sender: UIBarButtonItem) {
    self.dismissController()
  }
}

// MARK: - MyBluetoothDeviceDelegate

extension BluetoothDeviceDetailViewController : MyBluetoothDeviceDelegate {
  
  func didUpdate(_ device: MyBluetoothDevice) {
    self.reloadContent()
  }
}
