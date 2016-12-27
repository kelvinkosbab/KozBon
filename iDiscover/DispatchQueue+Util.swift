//
//  DispatchQueue+Util.swift
//  Test
//
//  Created by Kelvin Kosbab on 12/26/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation

extension DispatchQueue {
  
  func asyncAfter(after: Double, closure: @escaping () -> ()) {
    self.asyncAfter(deadline: .now() + Double(Int64(after * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
  }
}
