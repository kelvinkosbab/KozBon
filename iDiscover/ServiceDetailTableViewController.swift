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
  
  static private func newViewController() -> ServiceDetailTableViewController {
    return self.newViewController(fromStoryboard: .services)
  }
  
  static func newViewController(browsedService service: MyNetService) -> ServiceDetailTableViewController {
    let viewController = self.newViewController()
    viewController.mode = .browsedService
    viewController.service = service
    viewController.serviceType = service.serviceType
    return viewController
  }
  
  static func newViewController(publishedService service: MyNetService) -> ServiceDetailTableViewController {
    let viewController = self.newViewController()
    viewController.mode = .publishedService
    viewController.service = service
    viewController.serviceType = service.serviceType
    return viewController
  }
  
  static func newViewController(serviceType: MyServiceType) -> ServiceDetailTableViewController {
    let viewController = self.newViewController()
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
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.title = self.serviceType.name
    
    if self.navigationController?.viewControllers.first == self {
      self.navigationItem.leftBarButtonItem = UIBarButtonItem(text: "Done", target: self, action: #selector(self.doneButtonSelected(_:)))
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
    
    if let service = self.service {
      NotificationCenter.default.addObserver(self, selector: #selector(self.serviceWasRemoved(_:)), name: .bonjourDidRemoveService, object: service)
      NotificationCenter.default.addObserver(self, selector: #selector(self.serviceWasRemoved(_:)), name: .bonjourDidClearServices, object: nil)
      NotificationCenter.default.addObserver(self, selector: #selector(self.reloadData), name: .netServiceResolveAddressComplete, object: service)
      NotificationCenter.default.addObserver(self, selector: #selector(self.reloadData), name: .netServiceDidPublish, object: service)
      NotificationCenter.default.addObserver(self, selector: #selector(self.reloadData), name: .netServiceDidUnPublish, object: service)
    }
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    
    NotificationCenter.default.removeObserver(self)
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
  
  @objc private func doneButtonSelected(_ sender: UIBarButtonItem) {
    self.dismissController()
  }
  
  // MARK: - UITableView
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    if self.mode.isPublishedService {
      return 2
    } else if self.mode.isBrowsedService {
      if let service = self.service, service.dataRecords.count > 0 {
        return 3
      }
      return 2
    }
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
    // Information section
    if section == 0 {
      return self.serviceInformationSectionItems.count
    }
    
    // The service was published by this device
    if self.mode.isPublishedService {
      return 1
    }
    
    // The service was discovered by this device
    if self.mode.isBrowsedService, let service = self.service {
      if section == 1 {
        // Addresses section
        if service.isResolving {
          return 1
        } else if !service.isResolving && service.addresses.count == 0 {
          return 1
        }
        return service.addresses.count
        
      } else if section == 2 {
        return service.dataRecords.count
      }
    }
    
    return 0
  }
  
  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    
    if section == 0 {
      let cell = tableView.dequeueReusableCell(withIdentifier: ServiceDetailButtonHeaderCell.name) as! ServiceDetailButtonHeaderCell
      cell.configure(title: "Information")
      return cell.contentView
    }
    
    // Section > 0
    
    // The service was published by this device
    if self.mode.isPublishedService {
      if section == 1 {
        let cell = tableView.dequeueReusableCell(withIdentifier: ServiceDetailSimpleHeaderCell.name) as! ServiceDetailSimpleHeaderCell
        cell.configure(title: "Actions")
        return cell.contentView
      }
    }
    
    // The service was discovered by this device
    if self.mode.isBrowsedService, let service = self.service {
      
      if section == 1 {
        // Addresses
        let cell = tableView.dequeueReusableCell(withIdentifier: ServiceDetailSimpleHeaderCell.name) as! ServiceDetailSimpleHeaderCell
        cell.configure(title: service.hostName == "NA" ? "Addresses" : "Addresses : \(service.hostName)")
        return cell.contentView
        
      } else if section == 2 {
        // Data Records
        let cell = tableView.dequeueReusableCell(withIdentifier: ServiceDetailSimpleHeaderCell.name) as! ServiceDetailSimpleHeaderCell
        cell.configure(title: "TXT Records")
        return cell.contentView
      }
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
        let cell = tableView.dequeueReusableCell(withIdentifier: ServiceDetailDescriptionCell.name, for: indexPath) as! ServiceDetailDescriptionCell
        cell.configure(text: item.value)
        return cell
        
      } else {
        // Key-value cell
        let cell = tableView.dequeueReusableCell(withIdentifier: ServiceDetailKeyValueCell.name, for: indexPath) as! ServiceDetailKeyValueCell
        cell.configure(key: item.key, value: item.value)
        return cell
      }
    }
    
    // The service was published by this device
    if self.mode.isPublishedService, let service = self.service {
      let cell = tableView.dequeueReusableCell(withIdentifier: ServiceDetailSimpleCell.name, for: indexPath) as! ServiceDetailSimpleCell
      cell.configure(textColor: .blue)
      
      // Determine if the service is currently published
      var isCurrentlyPublished: Bool = false
      for publishedService in MyBonjourPublishManager.shared.publishedServices {
        if service == publishedService {
          isCurrentlyPublished = true
          break
        }
      }
      cell.configure(title: isCurrentlyPublished ? "Un-Publish Service" : "Publish Service")
      return cell
    }
    
    // The service was discovered by this device
    if self.mode.isBrowsedService, let service = self.service {
      
      if indexPath.section == 1 {
        
        // Addresses section
        if service.isResolving {
          let cell = tableView.dequeueReusableCell(withIdentifier: ServiceDetailLoadingCell.name, for: indexPath) as! ServiceDetailLoadingCell
          cell.activityIndicator.startAnimating()
          cell.activityIndicator.isHidden = false
          return cell
          
        } else if !service.isResolving && service.addresses.count == 0 {
          
          let cell = tableView.dequeueReusableCell(withIdentifier: ServiceDetailSimpleCell.name, for: indexPath) as! ServiceDetailSimpleCell
          cell.configure(title: "No Addresses Resolved")
          cell.configure(textColor: .black)
          return cell
        }
        
        let address = service.addresses[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ServiceDetailAddressCell.name, for: indexPath) as! ServiceDetailAddressCell
        cell.configure(title: address.fullAddress, detail: address.internetProtocol.string)
        return cell
        
      } else if indexPath.section == 2 {
        
        // Data records section
        let record = service.dataRecords[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ServiceDetailKeyValueCell.name, for: indexPath) as! ServiceDetailKeyValueCell
        cell.configure(key: record.key, value: record.value)
        return cell
      }
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
        service.unPublish { [weak self] in
          MyLoadingManager.hideLoading()
          self?.tableView.reloadData()
        }
        
      } else {
        MyLoadingManager.showLoading()
        service.publish(publishServiceSuccess: { [weak self] in
          MyLoadingManager.hideLoading()
          self?.tableView.reloadData()
        }, publishServiceFailure: { [weak self] in
          MyLoadingManager.hideLoading()
          self?.tableView.reloadData()
        })
      }
    }
  }
}
