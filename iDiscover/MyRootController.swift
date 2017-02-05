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
    let settingsViewController = self.setupSettingsController()
    self.viewControllers = [ servicesViewController, publishedServicesViewController, settingsViewController ]
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
  
  func setupSettingsController() -> UIViewController {
    let viewController = MyNavigationController(rootViewController: SettingsViewController.newViewController())
    viewController.title = "Settings"
    viewController.tabBarItem = UITabBarItem(title: "Settings", image: #imageLiteral(resourceName: "iconTools"), selectedImage: nil)
    return viewController
  }
  
  func setupBluetoothController() -> UISplitViewController {
    
    // Configure the master controller
    let bluetoothMasterViewController = BluetoothViewController.newViewController()
    let bluetoothNavigationController = MyNavigationController(rootViewController: bluetoothMasterViewController)
    
    // Set up split view for services
    let bluetoothSplitViewController = UISplitViewController()
    bluetoothSplitViewController.viewControllers = [ bluetoothNavigationController ]
    if !UIDevice.isPhone {
      bluetoothSplitViewController.minimumPrimaryColumnWidth = UIScreen.main.bounds.width / 2
      bluetoothSplitViewController.maximumPrimaryColumnWidth = UIScreen.main.bounds.width / 2
    }
    bluetoothSplitViewController.preferredDisplayMode = .allVisible
    bluetoothSplitViewController.title = "Bluetooth"
    bluetoothSplitViewController.tabBarItem = UITabBarItem(title: "Bluetooth", image: #imageLiteral(resourceName: "iconBluetooth"), selectedImage: nil)
    return bluetoothSplitViewController
  }
}
