//
//  PublishedServicesFooterView.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 2/4/17.
//  Copyright © 2017 Kozinga. All rights reserved.
//

import Foundation
import UIKit

protocol PublishedServicesFooterViewDelegate : class {
  func publishedServicesFooterPublishButtonSelected()
}

class PublishedServicesFooterView : UICollectionReusableView {
  @IBOutlet weak private var publishButton: UIButton!
  @IBOutlet weak private var arrowButton: UIButton!
  weak var delegate: PublishedServicesFooterViewDelegate? = nil
  
  @IBAction private func publishButtonSelected(_ sender: UIButton) {
    self.delegate?.publishedServicesFooterPublishButtonSelected()
  }
  
  @IBAction private func arrowButtonSelected(_ sender: UIButton) {
    self.delegate?.publishedServicesFooterPublishButtonSelected()
  }
}
