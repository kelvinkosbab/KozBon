//
//  ServiceDetailDescriptionCell.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 2/5/17.
//  Copyright © 2017 Kozinga. All rights reserved.
//

import Foundation
import UIKit

class ServiceDetailDescriptionCell : UITableViewCell {
  @IBOutlet weak private var descriptionLabel: UILabel!
  
  func configure(text: String) {
    self.descriptionLabel.text = text
  }
}
