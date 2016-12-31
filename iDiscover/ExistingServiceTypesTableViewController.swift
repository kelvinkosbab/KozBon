//
//  ExistingServiceTypesTableViewController.swift
//  iDiscover
//
//  Created by Kelvin Kosbab on 12/31/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation
import UIKit

class ExistingServiceTypesTableViewController: MyTableViewController, UISearchResultsUpdating, UISearchBarDelegate {
  
  // MARK: - Class Accessors
  
  static func newController() -> ExistingServiceTypesTableViewController {
    return self.newController(fromStoryboard: .settings, withIdentifier: self.name) as! ExistingServiceTypesTableViewController
  }
  
  // MARK: - Properties
  
  var serviceTypes: [MyServiceType] = []
  var filteredServiceTypes: [MyServiceType] = []
  let searchController = UISearchController(searchResultsController: nil)
  var serviceTypeDetailViewController: ServiceTypeDetailTableViewController? = nil
  
  private var isFiltered: Bool {
    if self.searchController.isActive, let text = self.searchController.searchBar.text, !text.isEmpty {
      return true
    }
    return false
  }
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.title = "All Service Types"
    
    // Setup the Search Controller
    self.searchController.searchResultsUpdater = self
    self.searchController.searchBar.delegate = self
    self.definesPresentationContext = true
    self.searchController.dimsBackgroundDuringPresentation = false
    self.tableView.tableHeaderView = self.searchController.searchBar
    
    // Populate existing service types
    self.serviceTypes = MyServiceType.tcpServiceTypes.sorted { (serviceType1: MyServiceType, serviceType2: MyServiceType) -> Bool in
      return serviceType1.name < serviceType2.name
    }
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    self.serviceTypeDetailViewController?.dismissController()
  }
  
  // MARK: - Search Controller
  
  func filterContent(forSearchText searchText: String? = nil) {
    if let text = searchText {
      self.filteredServiceTypes = self.serviceTypes.filter({ (serviceType: MyServiceType) -> Bool in
        let isInName = serviceType.name.containsIgnoreCase(text)
        let isInType = serviceType.fullType.containsIgnoreCase(text)
        var isInDetail = false
        if let detail = serviceType.detail {
          isInDetail = detail.containsIgnoreCase(text)
        }
        return isInName || isInType || isInDetail
      })
    } else {
      self.searchController.searchBar.text = ""
    }
    self.tableView.reloadData()
  }
  
  // MARK: - UISearchResultsUpdating
  
  func updateSearchResults(for searchController: UISearchController) {
    if let text = searchController.searchBar.text, !text.isEmpty {
      self.filterContent(forSearchText: text)
    }
  }
  
  // MARK: - UISearchBarDelegate
  
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    if searchText.isEmpty {
      self.filterContent()
    }
  }
  
  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    self.filterContent()
  }
  
  // MARK: - UITableView
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if self.isFiltered {
      return self.filteredServiceTypes.count
    }
    return self.serviceTypes.count
  }
  
  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 0
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let service = self.isFiltered ? self.filteredServiceTypes[indexPath.row] : self.serviceTypes[indexPath.row]
    let cell = tableView.dequeueReusableCell(withIdentifier: PublishNetServiceCell.name, for: indexPath) as! PublishNetServiceCell
    cell.nameLabel.text = service.name
    cell.typeLabel.text = service.fullType
    return cell
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    
    let serviceType = self.isFiltered ? self.filteredServiceTypes[indexPath.row] : self.serviceTypes[indexPath.row]
    var viewController = ServiceTypeDetailTableViewController.newController(serviceType: serviceType)
    if UIDevice.isPhone {
      viewController.presentControllerIn(self, forMode: .navStack)
      
    } else if let serviceTypeDetailViewController = self.serviceTypeDetailViewController {
      
      // Already showing a existing service type detail
      serviceTypeDetailViewController.serviceType = serviceType
      serviceTypeDetailViewController.updateServiceTypeContent()
      
    } else {
      self.serviceTypeDetailViewController = viewController
      viewController.presentControllerIn(self, forMode: .splitDetail, completion: nil)
    }
  }
}
