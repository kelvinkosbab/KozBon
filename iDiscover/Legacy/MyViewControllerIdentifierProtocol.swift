//
//  MyViewControllerIdentifierProtocol.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 2/4/17.
//  Copyright © 2017 Kozinga. All rights reserved.
//

import Foundation
import UIKit

protocol MyViewControllerIdentifierProtocol {}

extension MyViewControllerIdentifierProtocol where Self : UIViewController {
  
  // MARK: - Controller Name
  
  static var name: String {
    return String(describing: Self.self)
  }
  
  var className: String {
    return String(describing: type(of: self))
  }
  
  // MARK: - Storyboards and Identifiers
  
  static var identifier: String {
    return self.name
  }
  
  // MARK: - Accessing controllers from storyboard
  
  static func newViewController(fromStoryboard storyboard: MyStoryboard) -> Self {
    return storyboard.storyboard.instantiateViewController(withIdentifier: self.identifier) as! Self
  }
}

enum MyStoryboard {
  case main, services, bluetooth, info
  
  private var name: String {
    switch self {
    case .main:
      return "Main"
    case .services:
      return "Services"
    case .bluetooth:
      return "Bluetooth"
    case .info:
      return "Info"
    }
  }
  
  var storyboard: UIStoryboard {
    return UIStoryboard(name: self.name, bundle: nil)
  }
}
