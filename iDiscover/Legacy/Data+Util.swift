//
//  Data+Util.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 6/13/24.
//  Copyright © 2024 Kozinga. All rights reserved.
//

import Foundation

extension Data {

  var hexValue: String {
    var str = String()
    let len = self.count
    let p = (self as NSData).bytes.bindMemory(to: UInt8.self, capacity: len)
    for i in 0...len - 1 {
      str += String(format: "%02.2X", p[i])
    }
    return str
  }
}
