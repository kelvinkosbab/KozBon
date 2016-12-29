//
//  NetServicesTableViewController.swift
//  Test
//
//  Created by Kelvin Kosbab on 12/26/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation
import UIKit

class NetServicesTableHeaderCell: UITableViewCell {
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var reloadButton: UIButton!
  @IBOutlet weak var loadingImageView: UIImageView!
}

class NetServicesTableServiceCell: UITableViewCell {
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var typeLabel: UILabel!
  @IBOutlet weak var protocolLabel: UILabel!
}

class NetServicesTableLoadingCell: UITableViewCell {
  @IBOutlet weak var loadingImageView: UIImageView!
}

class NetServicesTableViewController: MyTableViewController {
  
  // MARK: - Class Accessors
  
  static func newController() -> NetServicesTableViewController {
    return self.newController(fromStoryboard: "Main", withIdentifier: self.name) as! NetServicesTableViewController
  }
  
  // MARK: - Properties
  
  var reloadButton: UIButton? = nil
  
  var services: [MyNetService] = []
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.title = "Network Services"
    
    self.reloadAllServices()
  }
  
  // MARK: - Content
  
  func reloadAllServices() {
    self.services = []
    MyBonjourManager.shared.startDiscovery(completion: { (services) in
      self.services = services
      self.tableView.reloadData()
    }) { 
      self.tableView.reloadData()
    }
  }
  
  // MARK: - Button Actions
  
  @objc private func reloadButtonSelected(_ sender: UIButton) {
    self.reloadAllServices()
  }
  
  // MARK: - UITableView
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return MyBonjourManager.shared.isSearching ? 1 : self.services.count
  }
  
  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let cell = tableView.dequeueReusableCell(withIdentifier: NetServicesTableHeaderCell.name) as! NetServicesTableHeaderCell
    cell.titleLabel.text = "Available Services".uppercased()
    self.reloadButton = cell.reloadButton
    self.reloadButton?.addTarget(self, action: #selector(self.reloadButtonSelected(_:)), for: .touchUpInside)
    if MyBonjourManager.shared.isSearching {
      cell.loadingImageView.image = UIImage.gif(name: "dotLoadingGif")
      cell.loadingImageView.isHidden = false
      cell.reloadButton.isHidden = true
    } else {
      cell.loadingImageView.isHidden = true
      cell.reloadButton.isHidden = false
    }
    return cell.contentView
  }
  
  override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    let cell = tableView.dequeueReusableCell(withIdentifier: NetServiceFooterCell.name) as! NetServiceFooterCell
    for subview in cell.subviews {
      subview.alpha = MyBonjourManager.shared.isSearching ? 0.0 : 1.0
    }
    return cell.contentView
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    // If services are loading
    if MyBonjourManager.shared.isSearching {
      let cell = tableView.dequeueReusableCell(withIdentifier: NetServicesTableLoadingCell.name, for: indexPath) as! NetServicesTableLoadingCell
      cell.loadingImageView.image = UIImage.gif(name: "dotLoadingGif")
      return cell
    }
    
    // Configure service cell
    let service = self.services[indexPath.row]
    let cell = tableView.dequeueReusableCell(withIdentifier: NetServicesTableServiceCell.name, for: indexPath) as! NetServicesTableServiceCell
    cell.nameLabel.text = service.serviceType.name
    cell.typeLabel.text = service.serviceType.type
    cell.protocolLabel.text = service.serviceType.transportLayer.string.uppercased()
    return cell
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    
    if !MyBonjourManager.shared.isSearching {
      let service = self.services[indexPath.row]
      let viewController = NetServiceViewController.newController(service: service)
      self.show(viewController, sender: self)
    }
  }
}
