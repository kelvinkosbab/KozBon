//
//  NetServicesTableViewController.swift
//  Test
//
//  Created by Kelvin Kosbab on 12/26/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation
import UIKit

class NetServicesTableViewController: MyTableViewController {
  
  // MARK: - Class Accessors
  
  static func newController() -> NetServicesTableViewController {
    return self.newController(fromStoryboard: .main, withIdentifier: self.name) as! NetServicesTableViewController
  }
  
  // MARK: - Properties
  
  var reloadButton: UIButton? = nil
  var loadingActivityIndicator: UIActivityIndicatorView? = nil
  
  var services: [MyNetService] = []
  var publishedServices: [MyNetService] = []
  
  var servicesSortType: MyNetServiceSortType? = nil {
    didSet {
      if let sortType = self.servicesSortType {
        self.services = sortType.sorted(services: self.services)
        self.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
      }
    }
  }
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.title = "Network Services"
    
    self.navigationItem.rightBarButtonItem = UIBarButtonItem(text: "Sort", target: self, action: #selector(self.sortButtonSelected(_:)))
    
    self.reloadBrowsingServices()
    self.reloadPublishedServices()
    
    NotificationCenter.default.addObserver(self, selector: #selector(self.netServiceResolveCompleted(_:)), name: .netServiceResolveAddressComplete, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(self.didPublishService(_:)), name: .netServiceDidPublish, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(self.didUnPublishService(_:)), name: .netServiceDidUnPublish, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(self.reloadBrowsingServices), name: .myServiceTypeDidCreateAndSave, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(self.reloadBrowsingServices), name: .UIApplicationWillEnterForeground, object: nil)
  }
  
  // MARK: - Content
  
  var isBrowsingForServces: Bool = false {
    
    didSet {
      if self.isBrowsingForServces != oldValue {
        // Update the header loading content
        if self.isBrowsingForServces {
          self.loadingActivityIndicator?.startAnimating()
          self.loadingActivityIndicator?.isHidden = false
          self.reloadButton?.isHidden = true
        } else {
          self.loadingActivityIndicator?.stopAnimating()
          self.loadingActivityIndicator?.isHidden = true
          self.reloadButton?.isHidden = false
        }
        
        if self.isBrowsingForServces {
          
          // Will start to browse for services
          
          // Update the table view
          self.tableView.beginUpdates()
          
          // Remove any services
          if self.services.count > 0 {
            let currentServicesCount = self.services.count
            var indexPathsToDelete: [IndexPath] = []
            for index in 0..<currentServicesCount {
              indexPathsToDelete.append(IndexPath(row: index, section: 0))
            }
            self.tableView.deleteRows(at: indexPathsToDelete, with: .top)
            
          } else {
            // Remove the no services cell
            let noServicesIndexPath = IndexPath(row: 0, section: 0)
            self.tableView.deleteRows(at: [ noServicesIndexPath ], with: .top)
          }
          self.services = []
          
          // Show the loading row
          let loadingIndexPath = IndexPath(row: 0, section: 0)
          self.tableView.insertRows(at: [ loadingIndexPath ], with: .top)
          
          // Done updating table view
          self.tableView.endUpdates()
          
        } else {
          
          // Done searching for services
          
          // Update the table view
          self.tableView.beginUpdates()
          
          // Hide the loading row
          let loadingIndexPath = IndexPath(row: 0, section: 0)
          self.tableView.deleteRows(at: [ loadingIndexPath ], with: .top)
          
          // Check if there were any discovered services
          if self.services.count > 0 {
            
            // Add disovered services to the table view
            var indexPathsToInsert: [IndexPath] = []
            for index in 0..<self.services.count {
              indexPathsToInsert.append(IndexPath(row: index, section: 0))
            }
            self.tableView.insertRows(at: indexPathsToInsert, with: .top)
            
          } else {
            
            // Add the no services found cell
            let noServicesIndexPath = IndexPath(row: 0, section: 0)
            self.tableView.insertRows(at: [ noServicesIndexPath ], with: .top)
          }
          
          // Done updating table view
          self.tableView.endUpdates()
        }
      }
    }
  }
  
  func reloadBrowsingServices() {
    
    // Update the browsing for services flag
    self.isBrowsingForServces = true
    
    // Start service discovery
    MyBonjourManager.shared.startDiscovery(completion: { (services) in
      
      // Sort and set the discovered services
      if let sortType = self.servicesSortType {
        self.services = sortType.sorted(services: services)
      } else {
        self.services = services
      }
      
      // Update the browsing for services flag
      self.isBrowsingForServces = false
    })
  }
  
  @objc private func reloadPublishedServices() {
    
    // Fetch and sort the published services
    let services = MyBonjourPublishManager.shared.publishedServices
    if let sortType = self.servicesSortType {
      self.publishedServices = sortType.sorted(services: services)
    } else {
      self.publishedServices = services
    }
    self.tableView.reloadSections(IndexSet(integer: self.publishedServicesTableViewSection), with: .automatic)
  }
  
  @objc private func didPublishService(_ notification: Notification) {
    if let service = notification.object as? MyNetService {
      
      // Check if have to remove none cell
      let initialPublishedServicesCount = self.publishedServices.count
      
      // Add the published address
      self.publishedServices.append(service)
      
      // Sort the published services with the additional service
      if let sortType = self.servicesSortType {
        self.publishedServices = sortType.sorted(services: publishedServices)
      }
      
      // Update the table view
      if let index = self.publishedServices.index(of: service) {
        
        // Begin table updates
        self.tableView.beginUpdates()
        
        // Remove none cell if necessary
        if initialPublishedServicesCount == 0 {
          let indexPathToDelete = IndexPath(row: 0, section: self.publishedServicesTableViewSection)
          self.tableView.deleteRows(at: [ indexPathToDelete ], with: .automatic)
        }
        
        // Insert service cell
        let indexPathToInsert = IndexPath(row: index, section: self.publishedServicesTableViewSection)
        self.tableView.insertRows(at: [ indexPathToInsert ], with: .automatic)
        
        // End table updates
        self.tableView.endUpdates()
        
      } else {
        // Error case
        self.reloadPublishedServices()
      }
      
    } else {
      // Error case
      self.reloadPublishedServices()
    }
    
    // Reload browsed services
    self.reloadBrowsingServices()
  }
  
  @objc private func didUnPublishService(_ notification: Notification) {
    if let service = notification.object as? MyNetService, let index = self.publishedServices.index(of: service) {
      
      // Remove the service
      self.publishedServices.remove(at: index)
      
      // Begin table updates
      self.tableView.beginUpdates()
      
      // Update the table view
      let indexPathToDelete = IndexPath(row: index, section: self.publishedServicesTableViewSection)
      self.tableView.deleteRows(at: [ indexPathToDelete ], with: .automatic)
      
      // Insert none cell if necessary
      if self.publishedServices.count == 0 {
        let indexPathToInsert = IndexPath(row: 0, section: self.publishedServicesTableViewSection)
        self.tableView.insertRows(at: [ indexPathToInsert ], with: .automatic)
      }
      
      // End table updates
      self.tableView.endUpdates()
      
    } else {
      // Error case
      self.reloadPublishedServices()
    }
    
    // Reload browsed services
    self.reloadBrowsingServices()
  }
  
  // MARK: - Notifications
  
  @objc private func netServiceResolveCompleted(_ notification: Notification) {
    if let service = notification.object as? MyNetService, let index = self.services.index(of: service) {
      let indexPathToUpdate = IndexPath(row: index, section: 0)
      self.tableView.reloadRows(at: [ indexPathToUpdate ], with: .automatic)
    }
  }
  
  // MARK: - Button Actions
  
  @objc private func reloadButtonSelected(_ sender: UIButton) {
    self.reloadBrowsingServices()
  }
  
  @objc private func sortButtonSelected(_ sender: UIBarButtonItem) {
    
    // Construct sort message
    let message: String?
    if let sortType = self.servicesSortType {
      message = "Currently: \(sortType.string)"
    } else {
      message = nil
    }
    
    // Construct action sheet
    let sortMenu = UIAlertController(title: "Sort By", message: message, preferredStyle: .actionSheet)
    for sortType in MyNetServiceSortType.all {
      sortMenu.addAction(UIAlertAction(title: sortType.string, style: .default, handler: { (_) in
        self.servicesSortType = sortType
      }))
    }
    sortMenu.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    self.present(sortMenu, animated: true, completion: nil)
  }
  
  // MARK: - Table View Helpers
  
  private let availableServicesTableViewSection: Int = 0
  private let expectingSomethingDifferentSection: Int = 1
  private let publishedServicesTableViewSection: Int = 2
  private let publishServiceTableViewSection: Int = 3
  
  // MARK: - UITableView
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 4
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == self.availableServicesTableViewSection {
      if MyBonjourManager.shared.isProcessing {
        return 1
      } else if self.services.count == 0 {
        return 1
      } else {
        return self.services.count
      }
      
    } else if section == self.expectingSomethingDifferentSection {
      return 1
    
    } else if section == self.publishedServicesTableViewSection {
      return self.publishedServices.count == 0 ? 1 : self.publishedServices.count
      
    } else if section == self.publishServiceTableViewSection {
      return 1
    }
    return 0
  }
  
  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    if section == self.expectingSomethingDifferentSection || section == self.publishServiceTableViewSection {
      return 0
    }
    return super.tableView(tableView, heightForHeaderInSection: section)
  }
  
  override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    if section == self.expectingSomethingDifferentSection - 1 || section == self.publishServiceTableViewSection - 1 {
      return 0
    }
    return super.tableView(tableView, heightForFooterInSection: section)
  }
  
  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    if section == self.availableServicesTableViewSection {
      let cell = tableView.dequeueReusableCell(withIdentifier: NetServicesTableHeaderCell.name) as! NetServicesTableHeaderCell
      cell.titleLabel.text = "Discovered Services".uppercased()
      self.reloadButton = cell.reloadButton
      self.reloadButton?.addTarget(self, action: #selector(self.reloadButtonSelected(_:)), for: .touchUpInside)
      self.loadingActivityIndicator = cell.loadingActivityIndicator
      if MyBonjourManager.shared.isProcessing {
        cell.loadingActivityIndicator.startAnimating()
        cell.loadingActivityIndicator.isHidden = false
        cell.reloadButton.isHidden = true
      } else {
        cell.loadingActivityIndicator.stopAnimating()
        cell.loadingActivityIndicator.isHidden = true
        cell.reloadButton.isHidden = false
      }
      return cell.contentView
      
    } else if section == self.publishedServicesTableViewSection {
      let cell = tableView.dequeueReusableCell(withIdentifier: NetServiceHeaderCell.name) as! NetServiceHeaderCell
      cell.titleLabel.text = "Your Published Services".uppercased()
      return cell.contentView
    }
    return super.tableView(tableView, viewForHeaderInSection: section)
  }
  
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if indexPath.section == self.expectingSomethingDifferentSection {
      return 65
    } else if indexPath.section == self.publishServiceTableViewSection {
      return 30
    }
    return super.tableView(tableView, heightForRowAt: indexPath)
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    if indexPath.section == self.availableServicesTableViewSection {
      
      // If services are loading
      if self.isBrowsingForServces {
        let cell = tableView.dequeueReusableCell(withIdentifier: NetServicesTableLoadingCell.name, for: indexPath) as! NetServicesTableLoadingCell
        cell.loadingActivityIndicator.startAnimating()
        return cell
        
      } else if self.services.count == 0 {
        let cell = tableView.dequeueReusableCell(withIdentifier: MyBasicCenterLabelCell.name, for: indexPath) as! MyBasicCenterLabelCell
        cell.titleLabel.text = "No Services Discovered"
        return cell
      }
      
      // Configure service cell
      let service = self.services[indexPath.row]
      let cell = tableView.dequeueReusableCell(withIdentifier: NetServicesTableServiceCell.name, for: indexPath) as! NetServicesTableServiceCell
      cell.nameLabel.text = service.serviceType.name
      cell.hostLabel.text = service.hostName
      return cell
      
    } else if indexPath.section == self.expectingSomethingDifferentSection {
      let cell = tableView.dequeueReusableCell(withIdentifier: MyTopLabelBottomButtonCell.name) as! MyTopLabelBottomButtonCell
      cell.setPressHandler(didPress: {
        
        // Create a service type
        var viewController = CreateServiceTypeTableViewController.newController()
        viewController.presentControllerIn(self, forMode: .splitDetail)
      })
      return cell
      
    } else if indexPath.section == self.publishedServicesTableViewSection {
      
      if self.publishedServices.count == 0 {
        let cell = tableView.dequeueReusableCell(withIdentifier: MyBasicCenterLabelCell.name, for: indexPath) as! MyBasicCenterLabelCell
        cell.titleLabel.text = "No Published Services"
        return cell
      }
      
      // Configure published service cell
      let service = self.publishedServices[indexPath.row]
      let cell = tableView.dequeueReusableCell(withIdentifier: NetServiceAddressCell.name, for: indexPath) as! NetServiceAddressCell
      cell.ipLabel.text = service.serviceType.name
      cell.ipLayerProtocolLabel.text = service.serviceType.fullType
      return cell
      
    } else if indexPath.section == publishServiceTableViewSection {
      let cell = tableView.dequeueReusableCell(withIdentifier: NetServiceButtonCell.name, for: indexPath) as! NetServiceButtonCell
      cell.button.setTitle("Publish a Service", for: .normal)
      cell.setPressHandler(didPress: {
        var viewController = PublishNetServiceSearchViewController.newController()
        viewController.presentControllerIn(self, forMode: .navStack)
      })
      return cell
    }
    return UITableViewCell()
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    
    if indexPath.section == self.availableServicesTableViewSection {
      
      if !self.isBrowsingForServces && self.services.count > 0 {
        let service = self.services[indexPath.row]
        var viewController = ServiceDetailTableViewController.newController(browsedService: service)
        viewController.presentControllerIn(self, forMode: .splitDetail)
      }
      
    } else if indexPath.section == self.publishedServicesTableViewSection {
      
      let service = self.publishedServices[indexPath.row]
      var viewController = ServiceDetailTableViewController.newController(publishedService: service)
      viewController.presentControllerIn(self, forMode: .splitDetail)
    }
  }
}
