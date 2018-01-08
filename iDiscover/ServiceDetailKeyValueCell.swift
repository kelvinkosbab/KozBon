//
//  ServiceDetailKeyValueCell.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 2/5/17.
//  Copyright © 2017 Kozinga. All rights reserved.
//

import Foundation
import UIKit

class ServiceDetailKeyValueCell : UITableViewCell {
  @IBOutlet weak private var keyLabel: UILabel!
  @IBOutlet weak private var valueLabel: UILabel!
  
  func configure(key: String?, value: String?) {
    self.keyLabel.text = key?.localizedUppercase
    self.valueLabel.text = value
  }
}
