//
//  NetServiceDetailViewController.swift
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

class NetServiceDetailViewController: MyTableViewController {
  
  // MARK: - Class Accessors
  
  static func newController(service: MyNetService) -> NetServiceDetailViewController {
    let viewController = self.newController(fromStoryboard: .main, withIdentifier: self.name) as! NetServiceDetailViewController
    viewController.service = service
    return viewController
  }
  
  // MARK: - Properties
  
  var moreDetailsButton: UIButton? = nil
  
  var service: MyNetService!
  var isMoreDetails: Bool = false {
    didSet {
      self.moreDetailsButton?.setTitle(self.isMoreDetails ? "Less" : "More", for: .normal)
      if self.isMoreDetails {
        // Show the extra details
        var indexPathsToInsert: [IndexPath] = []
        indexPathsToInsert.append(IndexPath(row: 2, section: 0))
        indexPathsToInsert.append(IndexPath(row: 3, section: 0))
        indexPathsToInsert.append(IndexPath(row: 4, section: 0))
        if let _ = self.service.serviceType.detail {
          indexPathsToInsert.append(IndexPath(row: 5, section: 0))
        }
        self.tableView.insertRows(at: indexPathsToInsert, with: .top)
        
      } else {
        // Hide the extra details
        var indexPathsToDelete: [IndexPath] = []
        indexPathsToDelete.append(IndexPath(row: 2, section: 0))
        indexPathsToDelete.append(IndexPath(row: 3, section: 0))
        indexPathsToDelete.append(IndexPath(row: 4, section: 0))
        if let _ = self.service.serviceType.detail {
          indexPathsToDelete.append(IndexPath(row: 5, section: 0))
        }
        self.tableView.deleteRows(at: indexPathsToDelete, with: .top)
      }
    }
  }
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.title = self.service.serviceType.name
    
    NotificationCenter.default.addObserver(self, selector: #selector(self.serviceWasRemoved(_:)), name: .bonjourDidRemoveService, object: self.service)
    NotificationCenter.default.addObserver(self, selector: #selector(self.serviceWasRemoved(_:)), name: .bonjourDidClearServices, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(self.netServiceResolveCompleted(_:)), name: .netServiceResolveAddressComplete, object: self.service)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    // Check if the service has resolved addresses
    if !self.service.hasResolvedAddresses {
      self.service.resolve {
        self.tableView.reloadData()
      }
    }
  }
  
  // MARK: - Notifications
  
  @objc private func serviceWasRemoved(_ notification: Notification) {
    self.dismissController()
  }
  
  @objc private func netServiceResolveCompleted(_ notification: Notification) {
    self.tableView.reloadData()
  }
  
  // MARK: - Actions
  
  @objc private func moreDetailsButtonSelected(_ sender: UIButton) {
    self.isMoreDetails = !isMoreDetails
  }
  
  // MARK: - UITableView
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 2
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    // Information section
    if section == 0 && self.isMoreDetails {
      return self.service.serviceType.detail != nil ? 6 : 5
    } else if section == 0 && !self.isMoreDetails {
      return 2
    
    // Addresses section
    } else if self.service.isResolving {
      return 1
    } else if !self.service.isResolving && self.service.addresses.count == 0 {
      return 1
    }
    return self.service.addresses.count
  }
  
  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    if section == 0 {
      let cell = tableView.dequeueReusableCell(withIdentifier: NetServicesTableHeaderCell.name) as! NetServicesTableHeaderCell
      cell.titleLabel.text = "Information".uppercased()
      cell.loadingActivityIndicator.stopAnimating()
      cell.loadingActivityIndicator.isHidden = true
      self.moreDetailsButton = cell.reloadButton
      cell.reloadButton.setTitle(self.isMoreDetails ? "Less" : "More", for: .normal)
      cell.reloadButton.addTarget(self, action: #selector(self.moreDetailsButtonSelected(_:)), for: .touchUpInside)
      return cell.contentView
    }
    
    // Addresses
    let cell = tableView.dequeueReusableCell(withIdentifier: NetServiceHeaderCell.name) as! NetServiceHeaderCell
    let addressesString = "Addresses".uppercased()
    cell.titleLabel.text = self.service.hostName == "NA" ? addressesString : "\(addressesString) : \(self.service.hostName)"
    return cell.contentView
  }
  
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if indexPath.section == 0 && indexPath.row == 5, let detail = self.service.serviceType.detail {
      return detail.getLabelHeight(width: self.tableView.bounds.width - 16, font: UIFont.systemFont(ofSize: 13))
    }
    return super.tableView(tableView, heightForRowAt: indexPath)
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    // Information section 0
    if indexPath.section == 0 {
      if indexPath.row == 0 {
        let cell = tableView.dequeueReusableCell(withIdentifier: NetServiceKeyValueCell.name, for: indexPath) as! NetServiceKeyValueCell
        cell.keyLabel.text = "Hostname".uppercased()
        cell.valueLabel.text = self.service.hostName
        return cell
        
      } else if indexPath.row == 1 {
        let cell = tableView.dequeueReusableCell(withIdentifier: NetServiceKeyValueCell.name, for: indexPath) as! NetServiceKeyValueCell
        cell.keyLabel.text = "Full Type".uppercased()
        cell.valueLabel.text = self.service.serviceType.fullType
        return cell
        
      } else if indexPath.row == 2 {
        let cell = tableView.dequeueReusableCell(withIdentifier: NetServiceKeyValueCell.name, for: indexPath) as! NetServiceKeyValueCell
        cell.keyLabel.text = "Name".uppercased()
        cell.valueLabel.text = self.service.serviceType.name
        return cell
        
      } else if indexPath.row == 3 {
        let cell = tableView.dequeueReusableCell(withIdentifier: NetServiceKeyValueCell.name, for: indexPath) as! NetServiceKeyValueCell
        cell.keyLabel.text = "Type".uppercased()
        cell.valueLabel.text = self.service.serviceType.type
        return cell
        
      } else if indexPath.row == 4 {
        let cell = tableView.dequeueReusableCell(withIdentifier: NetServiceKeyValueCell.name, for: indexPath) as! NetServiceKeyValueCell
        cell.keyLabel.text = "Layer".uppercased()
        cell.valueLabel.text = self.service.serviceType.transportLayer.string
        return cell
      }
      
      let cell = tableView.dequeueReusableCell(withIdentifier: NetServiceDetailCell.name, for: indexPath) as! NetServiceDetailCell
      cell.detailLabel.text = self.service.serviceType.detail
      return cell
    } else
    
    // Addresses section 1
    
    if self.service.isResolving {
      let cell = tableView.dequeueReusableCell(withIdentifier: NetServicesTableLoadingCell.name, for: indexPath) as! NetServicesTableLoadingCell
      cell.loadingActivityIndicator.startAnimating()
      cell.loadingActivityIndicator.isHidden = false
      return cell
      
    } else if !self.service.isResolving && self.service.addresses.count == 0 {
      let cell = tableView.dequeueReusableCell(withIdentifier: NetServiceDetailCell.name, for: indexPath) as! NetServiceDetailCell
      cell.detailLabel.text = "NA"
      return cell
    }
    
    let address = self.service.addresses[indexPath.row]
    let cell = tableView.dequeueReusableCell(withIdentifier: NetServiceAddressCell.name, for: indexPath) as! NetServiceAddressCell
    cell.ipLabel.text = address.fullAddress
    cell.ipLayerProtocolLabel.text = address.internetProtocol.string
    return cell
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
  }
}
