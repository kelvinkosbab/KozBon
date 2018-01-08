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
    let publishedServicesViewController = self.setupPublishedServicesController()
    let bluetoothViewController = self.setupBluetoothController()
    let infoViewController = self.setupInfoController()
    self.viewControllers = [ servicesViewController, publishedServicesViewController, bluetoothViewController, infoViewController ]
  }
  
  // MARK: - Controllers
  
  func setupServicesController() -> UIViewController {
    let viewController = MyNavigationController(rootViewController: ServicesViewController.newViewController())
    viewController.title = "Bonjour"
    viewController.tabBarItem = UITabBarItem(title: "Bonjour", image: #imageLiteral(resourceName: "iconBonjour"), selectedImage: nil)
    return viewController
  }
  
  func setupPublishedServicesController() -> UIViewController {
    let viewController = MyNavigationController(rootViewController: PublishedServicesViewController.newViewController())
    viewController.title = "Publish"
    viewController.tabBarItem = UITabBarItem(title: "Publish", image: #imageLiteral(resourceName: "icPublish"), selectedImage: nil)
    return viewController
  }
  
  func setupInfoController() -> UIViewController {
    let viewController = MyNavigationController(rootViewController: SettingsViewController.newViewController())
    viewController.title = "Information"
    viewController.tabBarItem = UITabBarItem(title: "Information", image: #imageLiteral(resourceName: "icInfo"), selectedImage: nil)
    return viewController
  }
  
  func setupBluetoothController() -> UIViewController {
    let viewController = MyNavigationController(rootViewController: BluetoothViewController.newViewController())
    viewController.title = "Bluetooth"
    viewController.tabBarItem = UITabBarItem(title: "Bluetooth", image: #imageLiteral(resourceName: "iconBluetooth"), selectedImage: nil)
    return viewController
  }
}
