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
    
//    let servicesViewController = MyNavigationController(rootViewController: ServicesViewController.newViewController())
//    servicesViewController.tabBarItem = UITabBarItem(
//        title: "Bonjour",
//        image: #imageLiteral(resourceName: "iconBonjour"),
//        selectedImage: nil
//    )
    
    let bluetoothViewController = MyNavigationController(rootViewController: BluetoothViewController.newViewController())
    bluetoothViewController.tabBarItem = UITabBarItem(title: "Bluetooth", image: #imageLiteral(resourceName: "iconBluetooth"), selectedImage: nil)
    
    let infoViewController = MyNavigationController(rootViewController: SettingsViewController.newViewController())
    infoViewController.tabBarItem = UITabBarItem(title: "Information", image: UIImage(systemName: "info.circle.fill"), selectedImage: nil)
    
    self.viewControllers = [
//        servicesViewController,
        bluetoothViewController,
        infoViewController
    ]
  }
}
