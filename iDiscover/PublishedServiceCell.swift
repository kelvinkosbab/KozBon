//
//  PublishedServiceCell.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 2/5/17.
//  Copyright © 2017 Kozinga. All rights reserved.
//

import Foundation
import UIKit

class PublishedServiceCell : UICollectionViewCell {
  @IBOutlet weak private var containerView: UIView!
  @IBOutlet weak private var titleLabel: UILabel!
  @IBOutlet weak private var detailLabel: UILabel!
  private var service: MyNetService? = nil
  
  func configure(service: MyNetService) {
    self.service = service
    self.titleLabel.text = service.serviceType.name
    self.detailLabel.text = "Published"
    service.delegate = self
  }
}

extension PublishedServiceCell : MyNetServiceDelegate {
  
  func serviceDidResolveAddress(_ service: MyNetService) {
    self.configure(service: service)
  }
}
