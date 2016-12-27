//
//  MyControllerProtocol.swift
//  Test
//
//  Created by Kelvin Kosbab on 12/26/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
  
  static func newController(fromStoryboard storyboard: String, withIdentifier identifier: String) -> UIViewController {
    let storyboard = UIStoryboard(name: storyboard, bundle: nil)
    return storyboard.instantiateViewController(withIdentifier: identifier)
  }
}
