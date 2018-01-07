//
//  UIViewController+Util.swift
//  Test
//
//  Created by Kelvin Kosbab on 12/26/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
  
  // MARK: - Accessing Controllers from Storyboard
  
  static func newStoryboardController(fromStoryboardWithName storyboard: String, withIdentifier identifier: String) -> UIViewController {
    let storyboard = UIStoryboard(name: storyboard, bundle: nil)
    return storyboard.instantiateViewController(withIdentifier: identifier)
  }
  
  // MARK: - Alerts
  
  func showDisappearingAlertDialog(title: String, message: String? = nil, didDismiss: (() -> Void)? = nil) {
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    self.present(alertController, animated: true) {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
        self?.dismiss(animated: true, completion: didDismiss)
      }
    }
  }
  
  // MARK: - Adding child view controller helpers
  
  func addChildViewController(_ childViewController: UIViewController, intoView: UIView) {
    childViewController.view.translatesAutoresizingMaskIntoConstraints = false
    self.addChildViewController(childViewController)
    childViewController.view.frame = intoView.frame
    intoView.addSubview(childViewController.view)
    childViewController.didMove(toParentViewController: self)
    
    // Set up constraints for the embedded controller
    let top = NSLayoutConstraint(item: childViewController.view, attribute: .top, relatedBy: .equal, toItem: intoView, attribute: .top, multiplier: 1, constant: 0)
    let bottom = NSLayoutConstraint(item: childViewController.view, attribute: .bottom, relatedBy: .equal, toItem: intoView, attribute: .bottom, multiplier: 1, constant: 0)
    let leading = NSLayoutConstraint(item: childViewController.view, attribute: .leading, relatedBy: .equal, toItem: intoView, attribute: .leading, multiplier: 1, constant: 0)
    let trailing = NSLayoutConstraint(item: childViewController.view, attribute: .trailing, relatedBy: .equal, toItem: intoView, attribute: .trailing, multiplier: 1, constant: 0)
    intoView.addConstraints([ top, bottom, leading, trailing ])
    self.view.layoutIfNeeded()
  }
  
  // MARK: - Hiding Tab Bar
  
  func showTabBar(completion: (() -> Void)? = nil) {
    if let tabBarController = self.tabBarController {
      let tabBarFrame = tabBarController.tabBar.frame
      let heightOffset = tabBarFrame.size.height
      UIView.animate(withDuration: 0.3, animations: {
        let tabBarNewY = tabBarFrame.origin.y - heightOffset
        tabBarController.tabBar.frame = CGRect(x: tabBarFrame.origin.x, y: tabBarNewY, width: tabBarFrame.size.width, height: tabBarFrame.size.height)
      }, completion: { (_) in
        tabBarController.tabBar.isUserInteractionEnabled = true
        completion?()
      })
    }
  }
  
  func hideTabBar(completion: (() -> Void)? = nil) {
    if let tabBarController = self.tabBarController {
      tabBarController.tabBar.isUserInteractionEnabled = false
      let tabBarFrame = tabBarController.tabBar.frame
      let heightOffset = tabBarFrame.size.height
      UIView.animate(withDuration: 0.3, animations: {
        let tabBarNewY = tabBarFrame.origin.y + heightOffset
        tabBarController.tabBar.frame = CGRect(x: tabBarFrame.origin.x, y: tabBarNewY, width: tabBarFrame.size.width, height: tabBarFrame.size.height)
      }, completion: { (_) in
        completion?()
      })
    }
  }
}
