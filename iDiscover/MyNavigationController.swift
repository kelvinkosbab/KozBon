//
//  MyNavigationController.swift
//  iDiscover
//
//  Created by Kelvin Kosbab on 12/29/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation
import UIKit

class MyNavigationController : UINavigationController, PresentableController, MyViewControllerIdentifierProtocol {
  
  // MARK: - PresentableController
  
  var presentedMode: PresentationMode = .navStack
  var transitioningDelegateReference: UIViewControllerTransitioningDelegate? = nil
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.navigationBar.isTranslucent = false
    
    if #available(iOS 11.0, *) {
      self.navigationBar.prefersLargeTitles = true
    }
    
    self.styleNavigationBar()
  }
  
  // MARK: - Status Bar
  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }
  
  // MARK: - Styles
  
  func styleNavigationBar(barColor: UIColor = UIColor(hex: "007AFF"), fontColor: UIColor = .white, font: UIFont = UIFont.systemFont(ofSize: 18)) {
    self.navigationBar.barTintColor = barColor
    self.navigationBar.tintColor = fontColor
    self.navigationBar.titleTextAttributes = [ .foregroundColor : fontColor, .font : font ]
    if #available(iOS 11.0, *) {
      self.navigationBar.largeTitleTextAttributes = [ .foregroundColor : fontColor ]
    }
  }
}
