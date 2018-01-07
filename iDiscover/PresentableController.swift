//
//  PresentableController.swift
//  iDiscover
//
//  Created by Kelvin Kosbab on 12/30/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation
import UIKit

enum PresentationMode {
  case modal, navStack, splitDetail
}

protocol PresentableController : class {
  var presentedMode: PresentationMode { get set }
  var transitioningDelegateReference: UIViewControllerTransitioningDelegate? { get set }
}

extension PresentableController where Self : UIViewController {
  
  func presentControllerIn(_ parentController: UIViewController, forMode mode: PresentationMode, inNavigationController: Bool = true, phoneModalTransitionStyle modalTransitionStyle: UIModalTransitionStyle? = nil, completion: (() -> Void)? = nil) {
    self.presentedMode = mode
    switch mode {
      
    case .modal:
      let viewController = inNavigationController ? MyNavigationController(rootViewController: self) : self
      viewController.modalPresentationStyle = .formSheet
      if let modalTransitionStyle = modalTransitionStyle {
        viewController.modalTransitionStyle = modalTransitionStyle
      }
      parentController.present(viewController, animated: true, completion: completion)
      
    case .navStack:
      self.hidesBottomBarWhenPushed = true
      parentController.navigationController?.pushViewController(self, animated: true)
      completion?()
      
    case .splitDetail:
      
      // Check if on phone vs pad. If phone proceed with default navStack behavior
      if UIDevice.isPhone {
        self.presentControllerIn(parentController, forMode: .navStack, completion: completion)
        
      } else {
        // Present in split view detail controller
        if let splitViewController = parentController.splitViewController {
          let viewController = inNavigationController ? MyNavigationController(rootViewController: self) : self
          splitViewController.showDetailViewController(viewController, sender: self)
        } else {
          self.presentControllerIn(parentController, forMode: .navStack, completion: completion)
        }
      }
    }
  }
  
  func dismissController(completion: (() -> Void)? = nil){
    switch self.presentedMode {
      
    case .modal:
      self.presentingViewController?.dismiss(animated: true, completion: completion)
      
    case .navStack:
      _ = self.navigationController?.popViewController(animated: true)
      completion?()
      
    case .splitDetail:
      if let splitViewController = self.splitViewController {
        if let index = splitViewController.viewControllers.index(of: self) {
          splitViewController.viewControllers.remove(at: index)
        } else {
          
          // Look for self embedded in a navigation controller
          for controller in splitViewController.viewControllers {
            var found = false
            if let navigationController = controller as? UINavigationController {
              for subController in navigationController.viewControllers {
                if self == subController {
                  found = true
                  break
                }
              }
            }
            
            if found, let index = splitViewController.viewControllers.index(of: controller) {
              splitViewController.viewControllers.remove(at: index)
              break
            }
          }
        }
      } else {
        // Default navStack behavior
        _ = self.navigationController?.popViewController(animated: true)
      }
      completion?()
    }
  }
}
