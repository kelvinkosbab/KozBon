//
//  PublishedServicesViewController.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 2/4/17.
//  Copyright © 2017 Kozinga. All rights reserved.
//

import Foundation
import UIKit

class PublishedServicesViewController : MyCollectionViewController {
  
  // MARK: - Class Accessors
  
  static func newViewController() -> PublishedServicesViewController {
    return self.newViewController(fromStoryboard: .services)
  }
  
  // MARK: - Edit Mode Properties
  
  override var defaultViewTitle: String? {
    return "Publish"
  }
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.navigationItem.rightBarButtonItem = UIBarButtonItem(text: "Sort", target: self, action: #selector(self.sortButtonSelected(_:)))
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    MyBonjourPublishManager.shared.delegate = self
    self.reloadData()
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
  
  var publishedServices: [MyNetService] {
    return MyBonjourPublishManager.shared.publishedServices
  }
  
  // MARK: - UICollectionView
  
  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }
  
  override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    switch kind {
      
    case UICollectionElementKindSectionHeader:
      let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: PublishedServicesHeaderView.name, for: indexPath) as! PublishedServicesHeaderView
      headerView.configure(title: "Your Published Services")
      return headerView
      
    case UICollectionElementKindSectionFooter:
      let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: PublishedServicesFooterView.name, for: indexPath) as! PublishedServicesFooterView
      footerView.delegate = self
      return footerView
      
    default:
      return super.collectionView(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath)
    }
    
  }
  
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return self.publishedServices.count
  }
  
  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PublishedServiceCell.name, for: indexPath) as! PublishedServiceCell
    let service = self.publishedServices[indexPath.row]
    cell.configure(service: service)
    return cell
  }
  
  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let service = self.publishedServices[indexPath.row]
    let viewController = ServiceDetailTableViewController.newViewController(publishedService: service)
    viewController.presentControllerIn(self, forMode: UIDevice.isPhone ? .navStack : .modal)
  }
}

extension PublishedServicesViewController : MyBonjourPublishManagerDelegate {
  
  func publishedServicesUpdated(_ publishedServices: [MyNetService]) {
    self.reloadData()
  }
}

extension PublishedServicesViewController : PublishedServicesFooterViewDelegate {
  
  func publishedServicesFooterPublishButtonSelected() {
    let viewController = PublishNetServiceSearchViewController.newViewController()
    viewController.presentControllerIn(self, forMode: UIDevice.isPhone ? .navStack : .modal)
  }
}
