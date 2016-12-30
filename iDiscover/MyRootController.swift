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
    
    let servicesViewController = self.setupServicesController()
    let bluetoothViewController = self.setupBluetoothController()
    self.viewControllers = [ servicesViewController, bluetoothViewController ]
  }
  
  // MARK: - Controllers
  
  func setupServicesController() -> UIViewController {
    
    // Configure the master controller
    let servicesMasterViewController = NetServicesTableViewController.newController()
    let servicesNavigationController = MyNavigationController(rootViewController: servicesMasterViewController)
    
    // Set up split view for services
    let servicesSplitViewController = MySplitViewController()
    servicesSplitViewController.viewControllers = [ servicesNavigationController ]
    if !UIDevice.isPhone {
      servicesSplitViewController.minimumPrimaryColumnWidth = 300
      servicesSplitViewController.maximumPrimaryColumnWidth = 300
    }
    servicesSplitViewController.preferredDisplayMode = .allVisible
    servicesSplitViewController.title = "Bonjour"
    servicesSplitViewController.tabBarItem = UITabBarItem(title: "Bonjour", image: #imageLiteral(resourceName: "iconBonjour"), selectedImage: nil)
    return servicesSplitViewController
  }
  
  func setupBluetoothController() -> UIViewController {
    let bluetoothViewController = BluetoothDevicesTableViewController.newController()
    bluetoothViewController.title = "Bluetooth"
    bluetoothViewController.tabBarItem = UITabBarItem(title: "Bluetooth", image: #imageLiteral(resourceName: "iconBluetooth"), selectedImage: nil)
    return MyNavigationController(rootViewController: bluetoothViewController)
  }
}
