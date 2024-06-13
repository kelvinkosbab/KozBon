//
//  MyViewController.swift
//  iDiscover
//
//  Created by Kelvin Kosbab on 12/29/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation
import UIKit

class MyViewController: UIViewController, PresentableController, MyViewControllerIdentifierProtocol {

  // MARK: - PresentableController

  var presentedMode: PresentationMode = .navStack
  var transitioningDelegateReference: UIViewControllerTransitioningDelegate?

  // MARK: - Status Bar

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }
}
