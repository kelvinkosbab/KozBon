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
    let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
    return boundingBox.height + 20
  }

  // MARK: - Helpers

    var trimmed: String {
        self.trimmingCharacters(in: .whitespaces)
    }

    func containsIgnoreCase(_ string: String) -> Bool {
        self.lowercased().range(of: string.lowercased()) != nil
    }

    var containsWhitespace: Bool {
        self.rangeOfCharacter(from: .whitespacesAndNewlines) != nil
    }

    var containsAlphanumerics: Bool {
        self.rangeOfCharacter(from: .alphanumerics) != nil
  }

    var containsDecimalDigits: Bool {
        self.rangeOfCharacter(from: .decimalDigits) != nil
    }
    
    var convertToInt: Int? {
        NumberFormatter().number(from: self)?.intValue
    }
}
