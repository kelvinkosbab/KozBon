//
//  UIBarButtonItem+Util.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 11/10/20.
//  Copyright © 2020 Kozinga. All rights reserved.
//

import UIKit

extension UIBarButtonItem {
  
  convenience init(text title: String, target: Any? = nil, action: Selector? = nil) {
    self.init(title: title, style: .plain, target: target, action: action)
  }
  
  convenience init(systemItem barButtonSystemItem: UIBarButtonItem.SystemItem, target: Any? = nil, action: Selector? = nil) {
    self.init(barButtonSystemItem: barButtonSystemItem, target: target, action: action)
  }
}
