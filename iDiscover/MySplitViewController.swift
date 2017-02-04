//
//  MySplitViewController.swift
//  iDiscover
//
//  Created by Kelvin Kosbab on 12/30/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation
import UIKit

class MySplitViewController : UISplitViewController, PresentableController, MyViewControllerIdentifierProtocol {
  
  // MARK: - PresentableController
  
  var presentedMode: PresentationMode = .navStack
  var transitioningDelegateReference: UIViewControllerTransitioningDelegate? = nil
  
  // MARK: - Lifecycle
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  // MARK: - Status Bar
  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }
}
