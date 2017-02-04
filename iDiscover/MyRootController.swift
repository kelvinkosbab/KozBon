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
  
  // MARK: - Properties
  
  var servicesSplitViewController: MySplitViewController!
  var bluetoothSplitViewController: MySplitViewController!
  var settingsSplitViewController: MySplitViewController!
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.servicesSplitViewController = self.setupServicesController()
    self.bluetoothSplitViewController = self.setupBluetoothController()
    self.settingsSplitViewController = self.setupSettingsController()
    self.viewControllers = [ self.servicesSplitViewController, self.bluetoothSplitViewController, self.settingsSplitViewController ]
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    self.updateSplitViewWidths()
  }
  
  // MARK: - Orientation
  
  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    if !UIDevice.isPhone {
      self.updateSplitViewWidths(newWidth: size.width)
    }
  }
  
  private func updateSplitViewWidths(newWidth: CGFloat? = nil) {
    if !UIDevice.isPhone {
      let width = newWidth ?? min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
      self.servicesSplitViewController.minimumPrimaryColumnWidth = width / 2
      self.servicesSplitViewController.maximumPrimaryColumnWidth = width / 2
      self.settingsSplitViewController.minimumPrimaryColumnWidth = width / 2
      self.settingsSplitViewController.maximumPrimaryColumnWidth = width / 2
    }
  }
  
  // MARK: - Controllers
  
  func setupServicesController() -> MySplitViewController {
    
    // Configure the master controller
    let servicesMasterViewController = NetServicesTableViewController.newViewController()
    let servicesNavigationController = MyNavigationController(rootViewController: servicesMasterViewController)
    
    // Set up split view for services
    let servicesSplitViewController = MySplitViewController()
    servicesSplitViewController.viewControllers = [ servicesNavigationController ]
    if !UIDevice.isPhone {
      servicesSplitViewController.minimumPrimaryColumnWidth = UIScreen.main.bounds.width / 2
      servicesSplitViewController.maximumPrimaryColumnWidth = UIScreen.main.bounds.width / 2
    }
    servicesSplitViewController.preferredDisplayMode = .allVisible
    servicesSplitViewController.title = "Bonjour"
    servicesSplitViewController.tabBarItem = UITabBarItem(title: "Bonjour", image: #imageLiteral(resourceName: "iconBonjour"), selectedImage: nil)
    return servicesSplitViewController
  }
  
  func setupBluetoothController() -> MySplitViewController {
    
    // Configure the master controller
    let bluetoothMasterViewController = BluetoothViewController.newViewController()
    let bluetoothNavigationController = MyNavigationController(rootViewController: bluetoothMasterViewController)
    
    // Set up split view for services
    let bluetoothSplitViewController = MySplitViewController()
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
  
  func setupSettingsController() -> MySplitViewController {
    
    // Configure the master controller
    let settingsMasterViewController = SettingsTableViewController.newViewController()
    let settingsNavigationController = MyNavigationController(rootViewController: settingsMasterViewController)
    
    // Set up split view for services
    let settingsSplitViewController = MySplitViewController()
    settingsSplitViewController.viewControllers = [ settingsNavigationController ]
    if !UIDevice.isPhone {
      settingsSplitViewController.minimumPrimaryColumnWidth = UIScreen.main.bounds.width / 2
      settingsSplitViewController.maximumPrimaryColumnWidth = UIScreen.main.bounds.width / 2
    }
    settingsSplitViewController.preferredDisplayMode = .allVisible
    settingsSplitViewController.title = "Settings"
    settingsSplitViewController.tabBarItem = UITabBarItem(title: "Settings", image: #imageLiteral(resourceName: "iconTools"), selectedImage: nil)
    return settingsSplitViewController
  }
}
