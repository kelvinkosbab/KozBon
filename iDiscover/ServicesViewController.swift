//
//  ServicesViewController.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 2/4/17.
//  Copyright © 2017 Kozinga. All rights reserved.
//

import Foundation
import UIKit

protocol ServicesViewControllerBrowsingDelegate {
  func servicesViewControllerDidUpdateBrowsing(isBrowsing: Bool)
}

class ServicesViewController : MyCollectionViewController {
  
  // MARK: - Class Accessors
  
  static func newViewController() -> ServicesViewController {
    return self.newViewController(fromStoryboard: .services)
  }
  
  // MARK: - Edit Mode Properties
  
  override var defaultViewTitle: String? {
    return "Bonjour"
  }
  
  // MARK: - Properties
  
  var browsingDelegate: ServicesViewControllerBrowsingDelegate? = nil
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.navigationItem.rightBarButtonItem = UIBarButtonItem(text: "Sort", target: self, action: #selector(self.sortButtonSelected(_:)))
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    NotificationCenter.default.addObserver(self, selector: #selector(self.reloadBrowsingServices), name: .UIApplicationWillEnterForeground, object: nil)
    
    MyBonjourManager.shared.delegate = self
    self.reloadBrowsingServices()
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    
    NotificationCenter.default.removeObserver(self)
  }
  
  // MARK: - Content
  
  var isBrowsingForServces: Bool = false {
    didSet {
      if self.isBrowsingForServces != oldValue {
        self.browsingDelegate?.servicesViewControllerDidUpdateBrowsing(isBrowsing: self.isBrowsingForServces)
      }
    }
  }
  
  @objc func reloadBrowsingServices() {
    
    // Update the browsing for services flag
    self.isBrowsingForServces = true
    
    // Start service discovery
    MyBonjourManager.shared.startDiscovery(completion: { (services) in
      
      // Update the browsing for services flag
      self.isBrowsingForServces = false
    })
  }
  
  // MARK: - Button Actions
  
  @objc private func sortButtonSelected(_ sender: UIBarButtonItem) {
    
    // Construct sort message
    let message: String?
    if let sortType = MyBonjourManager.shared.sortType {
      message = "Currently: \(sortType.string)"
    } else {
      message = nil
    }
    
    // Construct action sheet
    let sortMenuController = UIAlertController(title: "Sort By", message: message, preferredStyle: .actionSheet)
    for sortType in MyNetServiceSortType.all {
      sortMenuController.addAction(UIAlertAction(title: sortType.string, style: .default, handler: { (_) in
        MyBonjourManager.shared.sortType = sortType
      }))
    }
    sortMenuController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    
    if UIDevice.isPhone {
      self.present(sortMenuController, animated: true, completion: nil)
      
    } else {
      sortMenuController.modalPresentationStyle = .popover
      if let popoverPresenter = sortMenuController.popoverPresentationController {
        popoverPresenter.sourceView = self.view
        popoverPresenter.sourceRect = CGRect(x: self.view.frame.width - 50, y: -10, width: 40, height: 1)
        self.present(sortMenuController, animated: true, completion: nil)
      }
    }
  }
  
  // MARK: - UICollectionView Helpers
  
  var services: [MyNetService] {
    return MyBonjourManager.shared.services
  }
  
  private let availableServicesTableViewSection: Int = 0
  private let publishedServicesTableViewSection: Int = 1
  
  // MARK: - UICollectionView
  
  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }
  
  override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    switch kind {
      
    case UICollectionElementKindSectionHeader:
      let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ServicesHeaderView.name, for: indexPath) as! ServicesHeaderView
      headerView.configure(self, title: "Discovered Services", isBrowsing: self.isBrowsingForServces)
      self.browsingDelegate = headerView
      return headerView
      
    case UICollectionElementKindSectionFooter:
      let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ServicesFooterView.name, for: indexPath) as! ServicesFooterView
      footerView.delegate = self
      return footerView
      
    default:
      return super.collectionView(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath)
    }
    
  }
  
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return self.services.count
  }
  
  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ServicesServiceCell.name, for: indexPath) as! ServicesServiceCell
    let service = self.services[indexPath.row]
    cell.configure(service: service)
    return cell
  }
  
  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let service = self.services[indexPath.row]
    let viewController = ServiceDetailTableViewController.newViewController(browsedService: service)
    viewController.presentControllerIn(self, forMode: UIDevice.isPhone ? .navStack : .modal)
  }
  
  // MARK: - UICollectionViewDelegateFlowLayout
  
  override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
    return CGSize(width: collectionView.bounds.width, height: 75)
  }
}

extension ServicesViewController : MyBonjourManagerDelegate {
  
  func servicesDidUpdate(_ services: [MyNetService]) {
    self.reloadData()
  }
}

extension ServicesViewController : ServicesHeaderViewDelegate {
  
  func servicesHeaderReloadButtonSelected() {
    self.reloadBrowsingServices()
  }
}

extension ServicesViewController : ServicesFooterViewDelegate {
  
  func servicesFooterSpecifyButtonSelected() {
    let viewController = CreateServiceTypeTableViewController.newViewController()
    viewController.presentControllerIn(self, forMode: UIDevice.isPhone ? .navStack : .modal)
  }
}
