//
//  String+Util.swift
//  iDiscover
//
//  Created by Kelvin Kosbab on 12/27/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation
import UIKit

extension String {
  
  // MARK: - UILabels
  
  func getLabelHeight(forLabel label: UILabel) -> CGFloat {
    let width = label.bounds.width
    let font = label.font
    return self.getLabelHeight(width: width, font: font!)
  }
  
  func getLabelHeight(width: CGFloat, font: UIFont) -> CGFloat {
    let constraintRect = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
    let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: font], context: nil)
    return boundingBox.height + 20
  }
  
  // MARK: - Helpers
  
  var trimmed: String {
    return self.trimmingCharacters(in: .whitespaces)
  }
  
  var urlEncoded: String? {
    return self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
  }
  
  func contains(_ string: String) -> Bool {
    return self.range(of: string) != nil
  }
  
  func containsIgnoreCase(_ string: String) -> Bool {
    return self.lowercased().range(of: string.lowercased()) != nil
  }
  
  var containsWhitespace: Bool {
    if let _ = self.rangeOfCharacter(from: .whitespacesAndNewlines) {
      return true
    }
    return false
  }
  
  var containsAlphanumerics: Bool {
    if let _ = self.rangeOfCharacter(from: .alphanumerics) {
      return true
    }
    return false
  }
  
  var containsDecimalDigits: Bool {
    if let _ = self.rangeOfCharacter(from: .decimalDigits) {
      return true
    }
    return false
  }
  
  var convertToDouble: Double? {
    return NumberFormatter().number(from: self)?.doubleValue
  }
  
  var convertToInt: Int? {
    return NumberFormatter().number(from: self)?.intValue
  }
  
  // MARK: - Subscript Operations
  
  subscript (i: Int) -> Character? {
    if let stringIndex = self.index(self.startIndex, offsetBy: i, limitedBy: self.endIndex) {
      return self[stringIndex]
    }
    return nil
  }
  
  subscript (i: Int) -> String {
    return String(self[i])
  }
}
