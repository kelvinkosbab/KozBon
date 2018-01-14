//
//  ServicesHeaderView.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 2/4/17.
//  Copyright © 2017 Kozinga. All rights reserved.
//

import Foundation
import UIKit

protocol ServicesHeaderViewDelegate : class {
  func servicesHeaderReloadButtonSelected()
}

class ServicesHeaderView : UICollectionReusableView {
  @IBOutlet weak private var titleLabel: UILabel!
  @IBOutlet weak private var reloadButton: UIButton!
  @IBOutlet weak private var activityIndicator: UIActivityIndicatorView!
  weak var delegate: ServicesHeaderViewDelegate? = nil
  
  @IBAction private func reloadButtonSelected(_ sender: UIButton) {
    self.delegate?.servicesHeaderReloadButtonSelected()
  }
  
  func configure(_ delegate: ServicesHeaderViewDelegate?, title: String, isBrowsing: Bool? = nil) {
    self.delegate = delegate
    self.titleLabel.text = title.uppercased()
    if let isBrowsing = isBrowsing {
      self.update(isBrowsing: isBrowsing)
    }
  }
  
  func update(isBrowsing: Bool) {
    if isBrowsing {
      self.activityIndicator.startAnimating()
      self.activityIndicator.isHidden = false
      self.reloadButton.isHidden = true
    } else {
      self.activityIndicator.stopAnimating()
      self.activityIndicator.isHidden = true
      self.reloadButton.isHidden = false
    }
  }
  
  func hideButtonAndSpinner() {
    self.activityIndicator.stopAnimating()
    self.activityIndicator.isHidden = true
    self.reloadButton.isUserInteractionEnabled = false
    self.reloadButton.isHidden = true
  }
}

extension ServicesHeaderView : ServicesViewControllerBrowsingDelegate {
  
  func servicesViewControllerDidUpdateBrowsing(isBrowsing: Bool) {
    self.update(isBrowsing: isBrowsing)
  }
}
