//
//  MyNavigationController.swift
//  iDiscover
//
//  Created by Kelvin Kosbab on 12/29/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import UIKit

class MyNavigationController : UINavigationController, PresentableController, MyViewControllerIdentifierProtocol {
  
  // MARK: - PresentableController
  
  var presentedMode: PresentationMode = .navStack
  var transitioningDelegateReference: UIViewControllerTransitioningDelegate? = nil
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.navigationBar.prefersLargeTitles = true
  }
}
