//
//  TableViewCells.swift
//  iDiscover
//
//  Created by Kelvin Kosbab on 1/3/17.
//  Copyright © 2017 Kozinga. All rights reserved.
//

import Foundation
import UIKit

class MyBasicCenterLabelCell: UITableViewCell {
  @IBOutlet weak var titleLabel: UILabel!
}

class NetServiceButtonCell: UITableViewCell {
  private var didPressButton: (() -> Void)? = nil
  @IBOutlet weak var button: UIButton!
  @IBAction private func buttonSelected(_ sender: UIButton) {
    self.didPressButton?()
  }
  func setPressHandler(didPress didPressButton: (() -> Void)? = nil) {
    self.didPressButton = didPressButton
  }
}

class NetServicesTableHeaderCell: UITableViewCell {
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var reloadButton: UIButton!
  @IBOutlet weak var loadingActivityIndicator: UIActivityIndicatorView!
}

class NetServicesTableServiceCell: UITableViewCell {
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var hostLabel: UILabel!
}

class NetServicesTableLoadingCell: UITableViewCell {
  @IBOutlet weak var loadingActivityIndicator: UIActivityIndicatorView!
}

class NetServiceHeaderCell: UITableViewCell {
  @IBOutlet weak var titleLabel: UILabel!
}

class NetServiceKeyValueCell: UITableViewCell {
  @IBOutlet weak var keyLabel: UILabel!
  @IBOutlet weak var valueLabel: UILabel!
}

class NetServiceDetailCell: UITableViewCell {
  @IBOutlet weak var detailLabel: UILabel!
}

class NetServiceAddressCell: UITableViewCell {
  @IBOutlet weak var ipLabel: UILabel!
  @IBOutlet weak var ipLayerProtocolLabel: UILabel!
}

class MyTopLabelBottomButtonCell: UITableViewCell {
  @IBOutlet weak var label: UILabel!
  @IBOutlet weak var button: UIButton!
  private var didPressButton: (() -> Void)? = nil
  @IBAction private func buttonSelected(_ sender: UIButton) {
    self.didPressButton?()
  }
  func setPressHandler(didPress didPressButton: (() -> Void)? = nil) {
    self.didPressButton = didPressButton
  }
}
