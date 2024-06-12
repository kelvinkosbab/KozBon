//
//  SettingsKeyValueCell.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 2/5/17.
//  Copyright © 2017 Kozinga. All rights reserved.
//

import Foundation
import UIKit

class SettingsKeyValueCell : UICollectionViewCell {
  @IBOutlet weak private var containerView: UIView!
  @IBOutlet weak private var keyLabel: UILabel!
  @IBOutlet weak private var valueLabel: UILabel!
  
  func configure(key: String, value: String) {
    self.keyLabel.text = key.uppercased()
    self.valueLabel.text = value
  }
}
