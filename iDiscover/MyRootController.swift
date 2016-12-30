//
//  MyRootController.swift
//  iDiscover
//
//  Created by Kelvin Kosbab on 12/29/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation
import UIKit

class MyRootController: UITabBarController {
  
  // MARK: - Class Accessors
  
  static func newController() -> MyRootController {
    return self.newController(fromStoryboard: "Main", withIdentifier: self.name) as! MyRootController
  }
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let servicesViewController = NetServicesTableViewController.newController()
    servicesViewController.title = "Bonjour"
    servicesViewController.tabBarItem = UITabBarItem(title: "Bonjour", image: #imageLiteral(resourceName: "iconBonjour"), selectedImage: nil)
    let servicesController = MyNavigationController(rootViewController: servicesViewController)
    
    let bluetoothViewController = BluetoothDevicesTableViewController.newController()
    bluetoothViewController.title = "Bluetooth"
    bluetoothViewController.tabBarItem = UITabBarItem(title: "Bluetooth", image: #imageLiteral(resourceName: "iconBluetooth"), selectedImage: nil)
    let bluetoothController = MyNavigationController(rootViewController: bluetoothViewController)
    
    self.viewControllers = [ servicesController, bluetoothController ]
  }
}
