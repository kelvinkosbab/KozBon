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
    return self.newController(fromStoryboard: .main, withIdentifier: self.name) as! MyRootController
  }
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let servicesViewController = self.setupServicesController()
    let settingsViewController = self.setupSettingsController()
    self.viewControllers = [ servicesViewController, settingsViewController ]
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
  
  func setupSettingsController() -> UIViewController {
    
    // Configure the master controller
    let settingsMasterViewController = SettingsTableViewController.newController()
    let settingsNavigationController = MyNavigationController(rootViewController: settingsMasterViewController)
    
    // Set up split view for services
    let settingsSplitViewController = MySplitViewController()
    settingsSplitViewController.viewControllers = [ settingsNavigationController ]
    if !UIDevice.isPhone {
      settingsSplitViewController.minimumPrimaryColumnWidth = 300
      settingsSplitViewController.maximumPrimaryColumnWidth = 300
    }
    settingsSplitViewController.preferredDisplayMode = .allVisible
    settingsSplitViewController.title = "Settings"
    settingsSplitViewController.tabBarItem = UITabBarItem(title: "Settings", image: #imageLiteral(resourceName: "iconTools"), selectedImage: nil)
    return settingsSplitViewController
  }
}
