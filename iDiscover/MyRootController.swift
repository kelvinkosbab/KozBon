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
  
  // MARK: - Properties
  
  var servicesSplitViewController: MySplitViewController!
  var settingsSplitViewController: MySplitViewController!
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.servicesSplitViewController = self.setupServicesController()
    self.settingsSplitViewController = self.setupSettingsController()
    self.viewControllers = [ self.servicesSplitViewController, self.settingsSplitViewController ]
    
//    NotificationCenter.default.addObserver(self, selector: #selector(self.didRotate), name: .UIDeviceOrientationDidChange, object: nil)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    self.updateSplitViewWidths()
  }
  
  // MARK: - Orientation
  
  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    self.updateSplitViewWidths(newWidth: min(size.width, size.height))
  }
  
//  @objc private func didRotateOrientation() {
//    self.updateSplitViewWidths()
//  }
  
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
    let servicesMasterViewController = NetServicesTableViewController.newController()
    let servicesNavigationController = MyNavigationController(rootViewController: servicesMasterViewController)
    
    // Set up split view for services
    let servicesSplitViewController = MySplitViewController()
    servicesSplitViewController.viewControllers = [ servicesNavigationController ]
    if !UIDevice.isPhone {
      let minimum = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
      servicesSplitViewController.minimumPrimaryColumnWidth = minimum / 2
      servicesSplitViewController.maximumPrimaryColumnWidth = minimum / 2
    }
    servicesSplitViewController.preferredDisplayMode = .allVisible
    servicesSplitViewController.title = "Bonjour"
    servicesSplitViewController.tabBarItem = UITabBarItem(title: "Bonjour", image: #imageLiteral(resourceName: "iconBonjour"), selectedImage: nil)
    return servicesSplitViewController
  }
  
  func setupSettingsController() -> MySplitViewController {
    
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
