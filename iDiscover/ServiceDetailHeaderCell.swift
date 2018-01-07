//
//  ServiceDetailHeaderCell.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 2/5/17.
//  Copyright © 2017 Kozinga. All rights reserved.
//

import Foundation
import UIKit

protocol ServiceDetailButtonHeaderCellDelegate : class {
  func serviceDetailMoreLessButtonSelected()
}

class ServiceDetailButtonHeaderCell : UITableViewCell {
  @IBOutlet weak private var titleLabel: UILabel!
  @IBOutlet weak private var moreLessButton: UIButton!
  @IBOutlet weak private var arrowButton: UIButton!
  private weak var delegate: ServiceDetailButtonHeaderCellDelegate? = nil
  
  func configure(_ delegate: ServiceDetailButtonHeaderCellDelegate?, title: String, isShowingMore: Bool = false) {
    self.delegate = delegate
    self.titleLabel.text = title.uppercased()
    self.configure(isShowingMore: isShowingMore)
  }
  
  func configure(isShowingMore: Bool) {
    self.moreLessButton.setTitle(isShowingMore ? "Less" : "More", for: .normal)
    self.arrowButton.setBackgroundImage(isShowingMore ? #imageLiteral(resourceName: "icChevronDown") : #imageLiteral(resourceName: "icChevronUp"), for: .normal)
  }
  
  @IBAction func moreLessButtonSelected(_ sender: UIButton) {
    self.delegate?.serviceDetailMoreLessButtonSelected()
  }
  
  @IBAction func arrowButtonSelected(_ sender: UIButton) {
    self.delegate?.serviceDetailMoreLessButtonSelected()
  }
}

extension ServiceDetailButtonHeaderCell : ServiceDetailMoreLessDelegate {
  
  func serviceDetailDidUpdateMoreLess(isShowingMore: Bool) {
    self.configure(isShowingMore: isShowingMore)
  }
}
