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
  static let identifier: String = "NetServicesTableHeaderCell"
  @IBOutlet weak var titleLabel: UILabel!
}

class NetServicesTableServiceCell: UITableViewCell {
  static let identifier: String = "NetServicesTableServiceCell"
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var typeLabel: UILabel!
  @IBOutlet weak var protocolLabel: UILabel!
}

class NetServicesTableLoadingCell: UITableViewCell {
  static let identifier: String = "NetServicesTableLoadingCell"
  @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
}

class NetServicesTableViewController: UITableViewController {
  
  // MARK: - Class Accessors
  
  static func getController() -> NetServicesTableViewController {
    return self.newController(fromStoryboard: "Main", withIdentifier: "NetServicesTableViewController") as! NetServicesTableViewController
  }
  
  // MARK: - Properties
  
  var services: [MyNetService] = []
  
  var isProcessingServices: Bool = false
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.title = "Network Services"
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    self.reloadAllServices()
  }
  
  // MARK: - Content
  
  func reloadAllServices() {
    self.services = []
    self.isProcessingServices = true
    self.tableView.reloadData()
    MyBonjourDiscoveryService.shared.startDiscovery { (services) in
      self.isProcessingServices = false
      self.services = services
      self.tableView.reloadData()
    }
  }
  
  // MARK: - Button Actions
  
  @IBAction func reloadButtonSelected(_ sender: UIButton) {
    self.reloadAllServices()
  }
  
  @objc func refreshButtonSelected(_ sender: UIBarButtonItem) {
    self.reloadAllServices()
  }
  
  // MARK: - UITableView
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.isProcessingServices ? 1 : self.services.count
  }
  
  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let cell = tableView.dequeueReusableCell(withIdentifier: "NetServicesTableHeaderCell") as! NetServicesTableHeaderCell
    cell.titleLabel.text = "Available Services".uppercased()
    return cell
  }
  
  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 40
  }
  
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 50
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    // If services are loading
    if self.isProcessingServices {
      let cell = tableView.dequeueReusableCell(withIdentifier: "NetServicesTableLoadingCell", for: indexPath) as! NetServicesTableLoadingCell
      cell.activityIndicator.startAnimating()
      return cell
    }
    
    // Configure service cell
    let service = self.services[indexPath.row]
    let cell = tableView.dequeueReusableCell(withIdentifier: "NetServicesTableServiceCell", for: indexPath) as! NetServicesTableServiceCell
    cell.nameLabel.text = service.serviceType.name
    cell.typeLabel.text = service.serviceType.type
    cell.protocolLabel.text = service.serviceType.transportLayer.string.uppercased()
    return cell
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
  }
}
