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
  @IBOutlet weak var hostLabel: UILabel!
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
  var reloadingImageView: UIImageView? = nil
  
  var services: [MyNetService] = []
  
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
    
    self.reloadAllServices()
    
    NotificationCenter.default.addObserver(self, selector: #selector(self.netServiceResolveCompleted(_:)), name: .netServiceResolveAddressComplete, object: nil)
  }
  
  // MARK: - Content
  
  func reloadAllServices() {
    
    // Update the header row button and loading gif
    self.reloadingImageView?.image = UIImage.gif(name: "dotLoadingGif")
    self.reloadingImageView?.isHidden = false
    self.reloadButton?.isHidden = true
    
    // Clear existing services
    let currentServicesCount = self.services.count
    self.services = []
    var indexPathsToDelete: [IndexPath] = []
    for index in 0..<currentServicesCount {
      indexPathsToDelete.append(IndexPath(row: index, section: 0))
    }
    self.tableView.deleteRows(at: indexPathsToDelete, with: .top)
    
    // Start service discovery
    MyBonjourManager.shared.startDiscovery(completion: { (services) in
      
      // Remove the loading row
      let loadingIndexPath = IndexPath(row: 0, section: 0)
      self.tableView.deleteRows(at: [ loadingIndexPath ], with: .top)
      
      // Add disovered services
      if let sortType = self.servicesSortType {
        self.services = sortType.sorted(services: services)
      } else {
        self.services = services
      }
      var indexPathsToInsert: [IndexPath] = []
      for index in 0..<self.services.count {
        indexPathsToInsert.append(IndexPath(row: index, section: 0))
      }
      self.tableView.insertRows(at: indexPathsToInsert, with: .top)
      
      // Update the header row button and loading gif
      self.reloadingImageView?.image = nil
      self.reloadingImageView?.isHidden = true
      self.reloadButton?.isHidden = false
      
    }, didStartDiscovery: {
      let loadingIndexPath = IndexPath(row: 0, section: 0)
      self.tableView.insertRows(at: [ loadingIndexPath ], with: .top)
    })
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
    self.reloadAllServices()
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
  private let publishedServicesTableViewSection: Int = 1
  
  // MARK: - UITableView
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == self.availableServicesTableViewSection {
      if MyBonjourManager.shared.isProcessing {
        return 1
      } else {
        return self.services.count
      }
      
    } else if section == self.publishedServicesTableViewSection {
      return 1
    }
    return 0
  }
  
  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    if section == self.availableServicesTableViewSection {
      let cell = tableView.dequeueReusableCell(withIdentifier: NetServicesTableHeaderCell.name) as! NetServicesTableHeaderCell
      cell.titleLabel.text = "Available Services".uppercased()
      self.reloadButton = cell.reloadButton
      self.reloadButton?.addTarget(self, action: #selector(self.reloadButtonSelected(_:)), for: .touchUpInside)
      self.reloadingImageView = cell.loadingImageView
      if MyBonjourManager.shared.isProcessing {
        cell.loadingImageView.image = UIImage.gif(name: "dotLoadingGif")
        cell.loadingImageView.isHidden = false
        cell.reloadButton.isHidden = true
      } else {
        cell.loadingImageView.isHidden = true
        cell.reloadButton.isHidden = false
      }
      return cell.contentView
      
    } else if section == self.publishedServicesTableViewSection {
      let cell = tableView.dequeueReusableCell(withIdentifier: NetServiceHeaderCell.name) as! NetServiceHeaderCell
      cell.titleLabel.text = "Published Services".uppercased()
      return cell.contentView
    }
    return nil
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    if indexPath.section == self.availableServicesTableViewSection {
      // If services are loading
      if MyBonjourManager.shared.isProcessing {
        let cell = tableView.dequeueReusableCell(withIdentifier: NetServicesTableLoadingCell.name, for: indexPath) as! NetServicesTableLoadingCell
        cell.loadingImageView.image = UIImage.gif(name: "dotLoadingGif")
        return cell
      }
      
      // Configure service cell
      let service = self.services[indexPath.row]
      let cell = tableView.dequeueReusableCell(withIdentifier: NetServicesTableServiceCell.name, for: indexPath) as! NetServicesTableServiceCell
      cell.nameLabel.text = service.serviceType.name
      cell.typeLabel.text = "(\(service.serviceType.fullType))"
      cell.hostLabel.text = service.hostName
      return cell
      
    } else if indexPath.section == self.publishedServicesTableViewSection {
      let cell = tableView.dequeueReusableCell(withIdentifier: NetServicesTableLoadingCell.name, for: indexPath) as! NetServicesTableLoadingCell
      cell.loadingImageView.image = UIImage.gif(name: "dotLoadingGif")
      return cell
    }
    return UITableViewCell()
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    
    if indexPath.section == self.availableServicesTableViewSection {
      if !MyBonjourManager.shared.isProcessing {
        let service = self.services[indexPath.row]
        let viewController = NetServiceDetailViewController.newController(service: service)
        viewController.hidesBottomBarWhenPushed = true
        self.show(viewController, sender: self)
      }
      
    } else if indexPath.section == self.publishedServicesTableViewSection {
      
    }
  }
}
