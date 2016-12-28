//
//  NetServiceViewController.swift
//  iDiscover
//
//  Created by Kelvin Kosbab on 12/27/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation
import UIKit

class NetServiceHeaderCell: UITableViewCell {
  @IBOutlet weak var titleLabel: UILabel!
}

class NetServiceFooterCell: UITableViewCell {
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
  @IBOutlet weak var portLabel: UILabel!
  @IBOutlet weak var ipLayerProtocolLabel: UILabel!
}

class NetServiceViewController: MyTableViewController {
  
  // MARK: - Class Accessors
  
  static func newController(service: MyNetService) -> NetServiceViewController {
    let viewController = self.newController(fromStoryboard: "Main", withIdentifier: self.name) as! NetServiceViewController
    viewController.service = service
    return viewController
  }
  
  // MARK: - Properties
  
  var service: MyNetService!
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.title = self.service.serviceType.netServiceType
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    NotificationCenter.default.addObserver(self, selector: #selector(self.serviceWasRemoved(_:)), name: .bonjourDidRemoveService, object: self.service)
    NotificationCenter.default.addObserver(self, selector: #selector(self.serviceWasRemoved(_:)), name: .bonjourDidClearServices, object: nil)
    
    // Check if the service has resolved addresses
    if !self.service.hasResolvedAddresses {
      self.service.resolve(didResolveAddress: {
        self.tableView.reloadData()
      }, didNotResolveAddress: {
        self.tableView.reloadData()
      })
      self.tableView.reloadData()
    }
  }
  
  // MARK: - Notifications
  
  @objc private func serviceWasRemoved(_ notification: Notification) {
    if let navigationController = self.navigationController {
      navigationController.popViewController(animated: true)
    } else {
      self.dismiss(animated: true, completion: nil)
    }
  }
  
  // MARK: - UITableView
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 2
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == 0 {
      // Information section
      return self.service.serviceType.detail != nil ? 5 : 4
    } else if self.service.isResolving {
      return 1
    } else if !self.service.isResolving && self.service.addresses.count == 0 {
      return 1
    }
    return self.service.addresses.count
  }
  
  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let cell = tableView.dequeueReusableCell(withIdentifier: NetServiceHeaderCell.name) as! NetServiceHeaderCell
    cell.titleLabel.text = section == 0 ? "Information".uppercased() : "Discovered Addresses".uppercased()
    return cell
  }
  
  override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    let cell = tableView.dequeueReusableCell(withIdentifier: NetServiceFooterCell.name) as! NetServiceFooterCell
    if section == 1 {
      for subview in cell.subviews {
        subview.alpha = MyBonjourManager.shared.isSearching ? 0.0 : 1.0
      }
    }
    return cell
  }
  
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if indexPath.section == 0 && indexPath.row == 4, let detail = self.service.serviceType.detail {
      return detail.getLabelHeight(width: self.tableView.bounds.width - 16, font: UIFont.systemFont(ofSize: 13))
    }
    return super.tableView(tableView, heightForRowAt: indexPath)
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    // Information section 0
    if indexPath.section == 0 {
      if indexPath.row == 0 {
        let cell = tableView.dequeueReusableCell(withIdentifier: NetServiceKeyValueCell.name, for: indexPath) as! NetServiceKeyValueCell
        cell.keyLabel.text = "Name".uppercased()
        cell.valueLabel.text = self.service.serviceType.name
        return cell
        
      } else if indexPath.row == 1 {
        let cell = tableView.dequeueReusableCell(withIdentifier: NetServiceKeyValueCell.name, for: indexPath) as! NetServiceKeyValueCell
        cell.keyLabel.text = "Type".uppercased()
        cell.valueLabel.text = self.service.serviceType.type
        return cell
        
      } else if indexPath.row == 2 {
        let cell = tableView.dequeueReusableCell(withIdentifier: NetServiceKeyValueCell.name, for: indexPath) as! NetServiceKeyValueCell
        cell.keyLabel.text = "Layer".uppercased()
        cell.valueLabel.text = self.service.serviceType.transportLayer.string
        return cell
      } else if indexPath.row == 3 {
        let cell = tableView.dequeueReusableCell(withIdentifier: NetServiceKeyValueCell.name, for: indexPath) as! NetServiceKeyValueCell
        cell.keyLabel.text = "Full Type".uppercased()
        cell.valueLabel.text = self.service.serviceType.netServiceType
        return cell
      }
      
      let cell = tableView.dequeueReusableCell(withIdentifier: NetServiceDetailCell.name, for: indexPath) as! NetServiceDetailCell
      cell.detailLabel.text = self.service.serviceType.detail
      return cell
    } else
    
    // Addresses section 1
    
    if self.service.isResolving {
      let cell = tableView.dequeueReusableCell(withIdentifier: NetServicesTableLoadingCell.name, for: indexPath) as! NetServicesTableLoadingCell
      cell.loadingImageView.image = UIImage.gif(name: "dotLoadingGif")
      return cell
      
    } else if !self.service.isResolving && self.service.addresses.count == 0 {
      let cell = tableView.dequeueReusableCell(withIdentifier: NetServiceDetailCell.name, for: indexPath) as! NetServiceDetailCell
      cell.detailLabel.text = "NA"
      return cell
    }
    
    let address = self.service.addresses[indexPath.row]
    let cell = tableView.dequeueReusableCell(withIdentifier: NetServiceAddressCell.name, for: indexPath) as! NetServiceAddressCell
    cell.ipLabel.text = address.ip
    cell.portLabel.text = "\(address.port)"
    cell.ipLayerProtocolLabel.text = address.internetProtocol.string
    return cell
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
  }
}
