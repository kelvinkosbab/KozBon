//
//  UIDevice+Util.swift
//  iDiscover
//
//  Created by Kelvin Kosbab on 12/30/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation
import UIKit

extension UIDevice {
  
  static var isPhone: Bool {
    return UIDevice.current.userInterfaceIdiom == .phone
  }
  
  static var isPad: Bool {
    return UIDevice.current.userInterfaceIdiom == .pad
  }
  
  static var isTv: Bool {
    return UIDevice.current.userInterfaceIdiom == .tv
  }
  
  static var isCarPlay: Bool {
    return UIDevice.current.userInterfaceIdiom == .carPlay
  }
}
