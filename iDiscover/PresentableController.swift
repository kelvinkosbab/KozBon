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

protocol PresentableController {
  var presentedMode: PresentationMode { get set }
}

extension PresentableController where Self : UIViewController {
  
  mutating func presentControllerIn(_ parentController: UIViewController, forMode mode: PresentationMode, completion: (() -> Void)? = nil) {
    self.presentedMode = mode
    switch mode {
    case .modal:
      let navigationController = MyNavigationController(rootViewController: self)
      navigationController.modalPresentationStyle = .formSheet //.currentContext
      parentController.present(navigationController, animated: true, completion: completion)
    case .navStack:
      parentController.navigationController?.pushViewController(self, animated: true)
      self.hidesBottomBarWhenPushed = true
      completion?()
    case .splitDetail:
      if let splitViewController = parentController.splitViewController {
        let navigationController = MyNavigationController(rootViewController: self)
        splitViewController.showDetailViewController(navigationController, sender: self)
      } else {
        self.presentControllerIn(parentController, forMode: .navStack)
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
      if let index = self.splitViewController?.viewControllers.index(of: self) {
        self.splitViewController?.viewControllers.remove(at: index)
      } else {
        self.splitViewController?.viewControllers.removeLast()
      }
      completion?()
    }
  }
}
