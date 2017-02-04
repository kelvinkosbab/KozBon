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
    
    self.styleTitleText()
    self.styleColors()
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  // MARK: - Status Bar
  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }
  
  // MARK: - Styles
  
  func styleTitleText(font: UIFont = UIFont.systemFont(ofSize: 18)) {
    self.navigationBar.titleTextAttributes = [ NSFontAttributeName : font ]
  }
  
  func styleColors(barColor: UIColor = UIColor(hex: "007AFF"), fontColor: UIColor = UIColor.white) {
    self.navigationBar.barTintColor = barColor
    self.navigationBar.tintColor = fontColor
    self.navigationBar.titleTextAttributes = [ NSForegroundColorAttributeName: fontColor ]
  }
}
