//
//  ServiceDetailSimpleHeaderCell.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 2/5/17.
//  Copyright © 2017 Kozinga. All rights reserved.
//

import Foundation
import UIKit

class ServiceDetailSimpleHeaderCell : UITableViewCell {
  @IBOutlet weak private var titleLabel: UILabel!
  
  func configure(title: String) {
    self.titleLabel.text = title.uppercased()
  }
}
