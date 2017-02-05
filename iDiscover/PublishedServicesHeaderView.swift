//
//  PublishedServicesHeaderView.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 2/4/17.
//  Copyright © 2017 Kozinga. All rights reserved.
//

import Foundation
import UIKit

class PublishedServicesHeaderView : UICollectionReusableView {
  @IBOutlet weak private var titleLabel: UILabel!
  
  func configure(title: String) {
    self.titleLabel.text = title.uppercased()
  }
}
