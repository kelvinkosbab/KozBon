//
//  UIBarButtonItem+Util.swift
//  iDiscover
//
//  Created by Kelvin Kosbab on 12/29/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation
import UIKit

extension UIBarButtonItem {
  
  convenience init(text title: String, target: Any? = nil, action: Selector? = nil) {
    self.init(title: title, style: .plain, target: target, action: action)
    self.setFont()
  }
  
  convenience init(systemItem barButtonSystemItem: UIBarButtonItem.SystemItem, target: Any? = nil, action: Selector? = nil) {
    self.init(barButtonSystemItem: barButtonSystemItem, target: target, action: action)
    self.setFont()
  }
  
  private func setFont() {
    self.setTitleTextAttributes([ NSAttributedString.Key.font : UIFont.systemFont(ofSize: 15) ], for: .normal)
  }
}
