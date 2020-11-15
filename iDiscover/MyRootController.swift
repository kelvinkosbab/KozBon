//
//  MyRootController.swift
//  iDiscover
//
//  Created by Kelvin Kosbab on 12/29/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation
import UIKit

class MyRootController: MyTabBarController {
  
  // MARK: - Class Accessors
  
  static func newViewController() -> MyRootController {
    return self.newViewController(fromStoryboard: .main)
  }
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let servicesViewController = self.setupServicesController()
    let bluetoothViewController = self.setupBluetoothController()
    let infoViewController = self.setupInfoController()
    self.viewControllers = [ servicesViewController, bluetoothViewController, infoViewController ]
  }
  
  // MARK: - Controllers
  
  func setupServicesController() -> UIViewController {
    let viewController = MyNavigationController(rootViewController: ServicesViewController.newViewController())
    return viewController
  }
    
    func setupBluetoothController() -> UIViewController {
      let viewController = MyNavigationController(rootViewController: BluetoothViewController.newViewController())
      viewController.title = "Bluetooth"
      viewController.tabBarItem = UITabBarItem(title: "Bluetooth", image: #imageLiteral(resourceName: "iconBluetooth"), selectedImage: nil)
      return viewController
    }
  
  func setupInfoController() -> UIViewController {
    let viewController = MyNavigationController(rootViewController: SettingsViewController.newViewController())
    viewController.title = "Information"
    viewController.tabBarItem = UITabBarItem(title: "Information", image: UIImage(systemName: "info.circle.fill"), selectedImage: nil)
    return viewController
  }
}
