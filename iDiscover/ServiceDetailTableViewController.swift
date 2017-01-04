//
//  ServiceDetailTableViewController.swift
//  iDiscover
//
//  Created by Kelvin Kosbab on 1/1/17.
//  Copyright © 2017 Kozinga. All rights reserved.
//

import Foundation
import UIKit

class ServiceDetailTableViewController: MyTableViewController {
  
  // MARK: - Class Accessors
  
  static private func newController() -> ServiceDetailTableViewController {
    return self.newController(fromStoryboard: .main, withIdentifier: self.name) as! ServiceDetailTableViewController
  }
  
  static func newController(browsedService service: MyNetService) -> ServiceDetailTableViewController {
    let viewController = self.newController()
    viewController.mode = .browsedService
    viewController.service = service
    viewController.serviceType = service.serviceType
    return viewController
  }
  
  static func newController(publishedService service: MyNetService) -> ServiceDetailTableViewController {
    let viewController = self.newController()
    viewController.mode = .publishedService
    viewController.service = service
    viewController.serviceType = service.serviceType
    return viewController
  }
  
  static func newController(serviceType: MyServiceType) -> ServiceDetailTableViewController {
    let viewController = self.newController()
    viewController.mode = .serviceType
    viewController.service = nil
    viewController.serviceType = serviceType
    return viewController
  }
  
  // MARK: - Properties
  
  enum ServiceDetailMode {
    case browsedService, publishedService, serviceType
    
    var isBrowsedService: Bool {
      return self == .browsedService
    }
    
    var isPublishedService: Bool {
      return self == .publishedService
    }
    
    var isServiceType: Bool {
      return self == .serviceType
    }
  }
  
  var mode: ServiceDetailMode = .browsedService
  var service: MyNetService? = nil
  var serviceType: MyServiceType!
  
  var moreDetailsButton: UIButton? = nil
  
  var isMoreDetails: Bool = false {
    didSet {
      self.moreDetailsButton?.setTitle(self.isMoreDetails ? "Less" : "More", for: .normal)
      if self.isMoreDetails {
        // Show the extra details
        var indexPathsToInsert: [IndexPath] = []
        indexPathsToInsert.append(IndexPath(row: 2, section: 0))
        indexPathsToInsert.append(IndexPath(row: 3, section: 0))
        indexPathsToInsert.append(IndexPath(row: 4, section: 0))
        indexPathsToInsert.append(IndexPath(row: 5, section: 0))
        if let _ = self.serviceType.detail {
          indexPathsToInsert.append(IndexPath(row: 6, section: 0))
        }
        self.tableView.insertRows(at: indexPathsToInsert, with: .top)
        
      } else {
        // Hide the extra details
        var indexPathsToDelete: [IndexPath] = []
        indexPathsToDelete.append(IndexPath(row: 2, section: 0))
        indexPathsToDelete.append(IndexPath(row: 3, section: 0))
        indexPathsToDelete.append(IndexPath(row: 4, section: 0))
        indexPathsToDelete.append(IndexPath(row: 5, section: 0))
        if let _ = self.serviceType.detail {
          indexPathsToDelete.append(IndexPath(row: 6, section: 0))
        }
        self.tableView.deleteRows(at: indexPathsToDelete, with: .top)
      }
    }
  }
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.title = self.serviceType.name
    
    if let service = self.service {
      NotificationCenter.default.addObserver(self, selector: #selector(self.serviceWasRemoved(_:)), name: .bonjourDidRemoveService, object: service)
      NotificationCenter.default.addObserver(self, selector: #selector(self.serviceWasRemoved(_:)), name: .bonjourDidClearServices, object: nil)
      NotificationCenter.default.addObserver(self, selector: #selector(self.reloadData), name: .netServiceResolveAddressComplete, object: service)
      NotificationCenter.default.addObserver(self, selector: #selector(self.reloadData), name: .netServiceDidPublish, object: service)
      NotificationCenter.default.addObserver(self, selector: #selector(self.reloadData), name: .netServiceDidUnPublish, object: service)
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    // Populate content
    self.reloadData()
    
    // Check if the service has resolved addresses
    if let service = self.service {
      if !service.hasResolvedAddresses {
        service.resolve()
      }
    }
  }
  
  // MARK: - Content
  
  private class ServiceInformationItem {
    let key: String
    let value: String
    let isDetail: Bool
    init(key: String, value: String, isDetail: Bool = false) {
      self.key = key
      self.value = value
      self.isDetail = isDetail
    }
  }
  
  private var serviceInformationSectionItems: [ServiceInformationItem] = []
  
  @objc func reloadData() {
    self.serviceInformationSectionItems = []
    self.serviceInformationSectionItems.append(ServiceInformationItem(key: "Name", value: self.serviceType.name))
    if let service = self.service {
      self.serviceInformationSectionItems.append(ServiceInformationItem(key: "Hostname", value: service.hostName))
    }
    self.serviceInformationSectionItems.append(ServiceInformationItem(key: "Full Type", value: self.serviceType.fullType))
    self.serviceInformationSectionItems.append(ServiceInformationItem(key: "Type", value: self.serviceType.type))
    self.serviceInformationSectionItems.append(ServiceInformationItem(key: "Layer", value: self.serviceType.transportLayer.string))
    if let service = self.service {
      self.serviceInformationSectionItems.append(ServiceInformationItem(key: "Domain", value: service.service.domain))
    }
    if let detail = self.serviceType.detail {
      self.serviceInformationSectionItems.append(ServiceInformationItem(key: "Detail", value: detail, isDetail: true))
    }
    self.tableView.reloadData()
  }
  
  // MARK: - Notifications
  
  @objc private func serviceWasRemoved(_ notification: Notification) {
    self.dismissController()
  }
  
  // MARK: - Actions
  
  @objc private func moreDetailsButtonSelected(_ sender: UIButton) {
    self.isMoreDetails = !self.isMoreDetails
  }
  
  // MARK: - UITableView
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    if self.mode.isPublishedService {
      return 2
    } else if self.mode.isBrowsedService {
      return 2
    }
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
    // Information section
    if section == 0 {
      if let _ = self.service, !self.isMoreDetails {
        return 2
      } else {
        return self.serviceInformationSectionItems.count
      }
    }
    
    // The service was published by this device
    if self.mode.isPublishedService {
      return 1
    }
    
    // The service was discovered by this device
    if self.mode.isBrowsedService, let service = self.service {
      if service.isResolving {
        return 1
      } else if !service.isResolving && service.addresses.count == 0 {
        return 1
      }
      return service.addresses.count
    }
    
    return 0
  }
  
  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    
    if section == 0 {
      let cell = tableView.dequeueReusableCell(withIdentifier: NetServicesTableHeaderCell.name) as! NetServicesTableHeaderCell
      cell.titleLabel.text = "Information".uppercased()
      if let _ = self.service {
        cell.loadingActivityIndicator.stopAnimating()
        cell.loadingActivityIndicator.isHidden = true
        self.moreDetailsButton = cell.reloadButton
        cell.reloadButton.setTitle(self.isMoreDetails ? "Less" : "More", for: .normal)
        cell.reloadButton.addTarget(self, action: #selector(self.moreDetailsButtonSelected(_:)), for: .touchUpInside)
      } else {
        cell.loadingActivityIndicator.stopAnimating()
        cell.loadingActivityIndicator.isHidden = true
        cell.reloadButton.isHidden = true
        cell.reloadButton.removeTarget(nil, action: nil, for: .allEvents)
      }
      return cell.contentView
    }
    
    // Section > 0
    
    // The service was published by this device
    if self.mode.isPublishedService {
      let cell = tableView.dequeueReusableCell(withIdentifier: NetServiceHeaderCell.name) as! NetServiceHeaderCell
      cell.titleLabel.text = "Actions".uppercased()
      return cell.contentView
    }
    
    // The service was discovered by this device
    if self.mode.isBrowsedService, let service = self.service {
      // Addresses
      let cell = tableView.dequeueReusableCell(withIdentifier: NetServiceHeaderCell.name) as! NetServiceHeaderCell
      let addressesString = "Addresses".uppercased()
      cell.titleLabel.text = service.hostName == "NA" ? addressesString : "\(addressesString) : \(service.hostName)"
      return cell.contentView
    }
    
    return nil
  }
  
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if indexPath.section == 0 {
      
      // Check if this is the detail row
      let item = self.serviceInformationSectionItems[indexPath.row]
      if item.isDetail {
        return item.value.getLabelHeight(width: self.tableView.bounds.width - 16, font: UIFont.systemFont(ofSize: 13))
      }
    }
    return super.tableView(tableView, heightForRowAt: indexPath)
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    // Information section
    if indexPath.section == 0 {
      let item = self.serviceInformationSectionItems[indexPath.row]
      if item.isDetail {
        let cell = tableView.dequeueReusableCell(withIdentifier: NetServiceDetailCell.name, for: indexPath) as! NetServiceDetailCell
        cell.detailLabel.text = item.value
        return cell
        
      } else {
        // Key-value cell
        let cell = tableView.dequeueReusableCell(withIdentifier: NetServiceKeyValueCell.name, for: indexPath) as! NetServiceKeyValueCell
        cell.keyLabel.text = item.key.uppercased()
        cell.valueLabel.text = item.value
        return cell
      }
    }
    
    // The service was published by this device
    if self.mode.isPublishedService, let service = self.service {
      let cell = tableView.dequeueReusableCell(withIdentifier: MyBasicCenterLabelCell.name, for: indexPath) as! MyBasicCenterLabelCell
      cell.titleLabel.textColor = UIColor.blue
      
      // Determine if the service is currently published
      var isCurrentlyPublished: Bool = false
      for publishedService in MyBonjourPublishManager.shared.publishedServices {
        if service == publishedService {
          isCurrentlyPublished = true
          break
        }
      }
      cell.titleLabel.text = isCurrentlyPublished ? "Un-Publish Service" : "Publish Service"
      return cell
    }
    
    // The service was discovered by this device
    if self.mode.isBrowsedService, let service = self.service {
      
      if service.isResolving {
        let cell = tableView.dequeueReusableCell(withIdentifier: NetServicesTableLoadingCell.name, for: indexPath) as! NetServicesTableLoadingCell
        cell.loadingActivityIndicator.startAnimating()
        cell.loadingActivityIndicator.isHidden = false
        return cell
        
      } else if !service.isResolving && service.addresses.count == 0 {
        let cell = tableView.dequeueReusableCell(withIdentifier: MyBasicCenterLabelCell.name, for: indexPath) as! MyBasicCenterLabelCell
        cell.titleLabel.text = "No Addresses Resolved"
        return cell
      }
      
      let address = service.addresses[indexPath.row]
      let cell = tableView.dequeueReusableCell(withIdentifier: NetServiceAddressCell.name, for: indexPath) as! NetServiceAddressCell
      cell.ipLabel.text = address.fullAddress
      cell.ipLayerProtocolLabel.text = address.internetProtocol.string
      return cell
    }
    
    return UITableViewCell()
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    
    if self.mode.isPublishedService && indexPath.section == 1, let service = self.service {
      
      // Determine if the service is currently published
      var isCurrentlyPublished: Bool = false
      for publishedService in MyBonjourPublishManager.shared.publishedServices {
        if service == publishedService {
          isCurrentlyPublished = true
          break
        }
      }
      
      if isCurrentlyPublished {
        MyLoadingManager.showLoading()
        service.unPublish(completion: {
          MyLoadingManager.hideLoading()
          self.tableView.reloadData()
        })
        
      } else {
        MyLoadingManager.showLoading()
        service.publish(publishServiceSuccess: {
          MyLoadingManager.hideLoading()
          self.tableView.reloadData()
        }, publishServiceFailure: {
          MyLoadingManager.hideLoading()
          self.tableView.reloadData()
        })
      }
    }
  }
}
