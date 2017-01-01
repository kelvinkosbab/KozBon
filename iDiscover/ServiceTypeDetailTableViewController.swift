//
//  ServiceTypeDetailTableViewController.swift
//  iDiscover
//
//  Created by Kelvin Kosbab on 12/31/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation
import UIKit

class ServiceTypeDetailTableViewController: MyTableViewController {
  
  // MARK: - Class Accessors
  
  static func newController(serviceType: MyServiceType) -> ServiceTypeDetailTableViewController {
    let viewController = self.newController(fromStoryboard: .settings, withIdentifier: self.name) as! ServiceTypeDetailTableViewController
    viewController.serviceType = serviceType
    return viewController
  }
  
  // MARK: - Properties
  
  var serviceType: MyServiceType!
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.title = self.serviceType.name
  }
  
  // MARK: - Content
  
  func updateServiceTypeContent() {
    self.tableView.reloadData()
  }
  
  // MARK: - UITableView
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.serviceType.detail != nil ? 5 : 4
  }
  
  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let cell = tableView.dequeueReusableCell(withIdentifier: NetServicesTableHeaderCell.name) as! NetServicesTableHeaderCell
    cell.titleLabel.text = "Information".uppercased()
    cell.loadingActivityIndicator.stopAnimating()
    cell.loadingActivityIndicator.isHidden = true
    cell.reloadButton.isHidden = true
    return cell.contentView
  }
  
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if indexPath.section == 0 && indexPath.row == 4, let detail = self.serviceType.detail {
      return detail.getLabelHeight(width: self.tableView.bounds.width - 16, font: UIFont.systemFont(ofSize: 13))
    }
    return super.tableView(tableView, heightForRowAt: indexPath)
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if indexPath.row == 0 {
      let cell = tableView.dequeueReusableCell(withIdentifier: NetServiceKeyValueCell.name, for: indexPath) as! NetServiceKeyValueCell
      cell.keyLabel.text = "Full Type".uppercased()
      cell.valueLabel.text = self.serviceType.fullType
      return cell
      
    } else if indexPath.row == 1 {
      let cell = tableView.dequeueReusableCell(withIdentifier: NetServiceKeyValueCell.name, for: indexPath) as! NetServiceKeyValueCell
      cell.keyLabel.text = "Name".uppercased()
      cell.valueLabel.text = self.serviceType.name
      return cell
      
    } else if indexPath.row == 2 {
      let cell = tableView.dequeueReusableCell(withIdentifier: NetServiceKeyValueCell.name, for: indexPath) as! NetServiceKeyValueCell
      cell.keyLabel.text = "Type".uppercased()
      cell.valueLabel.text = self.serviceType.type
      return cell
      
    } else if indexPath.row == 3 {
      let cell = tableView.dequeueReusableCell(withIdentifier: NetServiceKeyValueCell.name, for: indexPath) as! NetServiceKeyValueCell
      cell.keyLabel.text = "Layer".uppercased()
      cell.valueLabel.text = self.serviceType.transportLayer.string
      return cell
    }
    
    let cell = tableView.dequeueReusableCell(withIdentifier: NetServiceDetailCell.name, for: indexPath) as! NetServiceDetailCell
    cell.detailLabel.text = self.serviceType.detail
    return cell
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
  }
}
