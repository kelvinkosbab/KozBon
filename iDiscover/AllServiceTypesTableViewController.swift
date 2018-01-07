//
//  AllServiceTypesTableViewController.swift
//  iDiscover
//
//  Created by Kelvin Kosbab on 12/31/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation
import UIKit

class AllServiceTypesTableViewController: MyTableViewController, UISearchResultsUpdating, UISearchBarDelegate {
  
  // MARK: - Class Accessors
  
  static func newViewController() -> AllServiceTypesTableViewController {
    return self.newViewController(fromStoryboard: .services)
  }
  
  // MARK: - Properties
  
  var serviceTypes: [MyServiceType] = []
  var filteredServiceTypes: [MyServiceType] = []
  let searchController = UISearchController(searchResultsController: nil)
  
  private var isFiltered: Bool {
    let scope = MyServiceTypeScope.allScopes[self.searchController.searchBar.selectedScopeButtonIndex]
    if self.searchController.isActive, let text = self.searchController.searchBar.text, !text.isEmpty {
      return true
    } else if !scope.isAll {
      return true
    }
    return false
  }
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.title = "All Service Types"
    
    if self.navigationController?.viewControllers.first == self {
      self.navigationItem.leftBarButtonItem = UIBarButtonItem(text: "Done", target: self, action: #selector(self.doneButtonSelected(_:)))
    }
    
    // Setup the Search Controller
    self.searchController.searchResultsUpdater = self
    self.searchController.searchBar.delegate = self
    self.definesPresentationContext = true
    self.searchController.dimsBackgroundDuringPresentation = false
    self.searchController.searchBar.scopeButtonTitles = MyServiceTypeScope.allScopeTitles
    self.tableView.tableHeaderView = self.searchController.searchBar
    
    // Populate existing service types
    self.serviceTypes = MyServiceType.fetchAll().sorted { (serviceType1: MyServiceType, serviceType2: MyServiceType) -> Bool in
      return serviceType1.name < serviceType2.name
    }
  }
  
  // MARK: - Button Actions
  
  @objc func doneButtonSelected(_ sender: UIBarButtonItem) {
    self.dismissController()
  }
  
  // MARK: - Search Controller
  
  func filterContent(searchText: String? = nil, scope: MyServiceTypeScope = .all) {
    
    self.filteredServiceTypes = self.serviceTypes.filter { (serviceType: MyServiceType) -> Bool in
      
      // Check category match
      let categoryMatch = (scope.isAll) || (scope.isBuiltIn && serviceType.isBuiltIn) || (scope.isCreated && serviceType.hasPersistentCopy)
      if categoryMatch {
        
        // Check text match
        if let text = searchText, !text.isEmpty {
          let isInName = serviceType.name.containsIgnoreCase(text)
          let isInType = serviceType.fullType.containsIgnoreCase(text)
          var isInDetail = false
          if let detail = serviceType.detail {
            isInDetail = detail.containsIgnoreCase(text)
          }
          return isInName || isInType || isInDetail
          
        } else {
          return true
        }
      }
      return false
    }
    self.tableView.reloadData()
  }
  
  // MARK: - UISearchResultsUpdating
  
  func updateSearchResults(for searchController: UISearchController) {
    let scope = MyServiceTypeScope.allScopes[searchController.searchBar.selectedScopeButtonIndex]
    self.filterContent(searchText: searchController.searchBar.text, scope: scope)
  }
  
  // MARK: - UISearchBarDelegate
  
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    if searchText.isEmpty {
      let scope = MyServiceTypeScope.allScopes[searchBar.selectedScopeButtonIndex]
      self.filterContent(scope: scope)
    }
  }
  
  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    let scope = MyServiceTypeScope.allScopes[searchBar.selectedScopeButtonIndex]
    self.filterContent(scope: scope)
  }
  
  func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
    let scope = MyServiceTypeScope.allScopes[selectedScope]
    self.filterContent(searchText: searchBar.text, scope: scope)
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
    let viewController = ServiceDetailTableViewController.newViewController(serviceType: serviceType)
    viewController.presentControllerIn(self, forMode: .navStack)
  }
}
