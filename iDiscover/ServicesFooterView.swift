//
//  ServicesFooterView.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 2/4/17.
//  Copyright © 2017 Kozinga. All rights reserved.
//

import Foundation
import UIKit

protocol ServicesFooterViewDelegate : class {
  func servicesFooterSpecifyButtonSelected()
}

class ServicesFooterView : UICollectionReusableView {
  @IBOutlet weak private var textLabel: UILabel!
  @IBOutlet weak private var arrowButton: UIButton!
  @IBOutlet weak private var specifyButton: UIButton!
  weak var delegate: ServicesFooterViewDelegate? = nil
  
  @IBAction private func specifyButtonSelected(_ sender: UIButton) {
    self.delegate?.servicesFooterSpecifyButtonSelected()
  }
  
  @IBAction private func arrowButtonSelected(_ sender: UIButton) {
    self.delegate?.servicesFooterSpecifyButtonSelected()
  }
}
