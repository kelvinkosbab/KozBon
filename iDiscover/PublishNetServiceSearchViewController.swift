//
//  PublishNetServiceSearchViewController.swift
//  iDiscover
//
//  Created by Kelvin Kosbab on 12/29/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation
import UIKit

extension Notification.Name {
  static let publishNetServiceSearchShouldDismiss = Notification.Name(rawValue: "\(PublishNetServiceSearchViewController.name).publishNetServiceSearchShouldDismiss")
}

class PublishNetServiceCell: UITableViewCell {
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var typeLabel: UILabel!
}

class PublishNetServiceSearchViewController: MyTableViewController, UISearchResultsUpdating, UISearchBarDelegate {
  
  // MARK: - Class Accessors
  
  static func newController() -> PublishNetServiceSearchViewController {
    return self.newController(fromStoryboard: .main, withIdentifier: self.name) as! PublishNetServiceSearchViewController
  }
  
  // MARK: - Properties
  
  var serviceTypes: [MyServiceType] = []
  var filteredServiceTypes: [MyServiceType] = []
  let searchController = UISearchController(searchResultsController: nil)
  var publishDetailBaseController: PublishDetailBaseViewController? = nil
  
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
    
    self.title = "Publish a Service"
    
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
    
    // Notifications
    NotificationCenter.default.addObserver(self, selector: #selector(self.shouldDismiss(_:)), name: .publishNetServiceSearchShouldDismiss, object: nil)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    self.navigationItem.rightBarButtonItem = UIBarButtonItem(text: "Create", target: self, action: #selector(self.createButtonSelected(_:)))
    
    if !UIDevice.isPhone {
      self.publishDetailBaseController = PublishDetailBaseViewController.newController()
      self.publishDetailBaseController?.presentControllerIn(self, forMode: .splitDetail)
    }
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    self.publishDetailBaseController?.dismissController()
  }
  
  // MARK: - Actions
  
  @objc private func shouldDismiss(_ notification: Notification) {
    self.dismissController()
  }
  
  @objc private func createButtonSelected(_ sender: UIBarButtonItem) {
    var viewController = PublishDetailCreateViewController.newController()
    if UIDevice.isPhone {
      viewController.presentControllerIn(self, forMode: .navStack)
    } else if let publishDetailBaseController = self.publishDetailBaseController {
      
      // Check if already showing create
      if let _ = publishDetailBaseController.navigationController?.viewControllers.last as? PublishDetailCreateViewController {
        // Already showing, do nothing
      } else {
        viewController.presentControllerIn(publishDetailBaseController, forMode: .navStack, completion: {
          if let navigationController = publishDetailBaseController.navigationController {
            navigationController.viewControllers = [ navigationController.viewControllers.first!, viewController ]
          }
        })
      }
    }
  }
  
  // MARK: - Search Controller
  
  func filterContent(searchText: String? = nil, scope: MyServiceTypeScope = .all) {
    
    self.filteredServiceTypes = self.serviceTypes.filter { (serviceType: MyServiceType) -> Bool in
      
      // Check category match
      let categoryMatch = (scope.isAll) || (scope.isBuiltIn && serviceType.isBuiltIn) || (scope.isCreated && serviceType.isCreated)
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
    var viewController = PublishDetailExistingViewController.newController(serviceType: serviceType)
    if UIDevice.isPhone {
      viewController.presentControllerIn(self, forMode: .navStack)
      
    } else if let publishDetailBaseController = self.publishDetailBaseController {
      
      // Check if already showing a existing publish view controller
      if let existingViewController = publishDetailBaseController.navigationController?.viewControllers.last as? PublishDetailExistingViewController {
        // Currently presenting a form for this service type. Update the content.
        existingViewController.serviceType = serviceType
        existingViewController.updateServiceContent()
        
      } else {
        // Currently on base controller. Push the new controller.
        viewController.presentControllerIn(publishDetailBaseController, forMode: .navStack, completion: {
          if let navigationController = publishDetailBaseController.navigationController {
            navigationController.viewControllers = [ navigationController.viewControllers.first!, viewController ]
          }
        })
      }
    }
  }
}
