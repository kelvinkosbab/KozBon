//
//  MyClassProtocol.swift
//  Test
//
//  Created by Kelvin Kosbab on 12/25/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation
import UIKit

protocol MyClassProtocol {}
extension MyClassProtocol {
  
  static var name: String {
    return String(describing: Self.self)
  }
  
  var className: String {
    return String(describing: type(of: self))
  }
}

extension NSObject : MyClassProtocol {}
extension Int : MyClassProtocol {}
extension Float : MyClassProtocol {}
extension Double : MyClassProtocol {}
extension String : MyClassProtocol {}
