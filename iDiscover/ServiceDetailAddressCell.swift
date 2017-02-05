//
//  ServiceDetailAddressCell.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 2/5/17.
//  Copyright © 2017 Kozinga. All rights reserved.
//

import Foundation
import UIKit

class ServiceDetailAddressCell : UITableViewCell {
  @IBOutlet weak private var titleLabel: UILabel!
  @IBOutlet weak private var detailLabel: UILabel!
  
  func configure(title: String, detail: String) {
    self.titleLabel.text = title
    self.detailLabel.text = detail
  }
}
