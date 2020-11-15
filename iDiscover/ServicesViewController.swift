//
//  ServicesViewController.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 2/4/17.
//  Copyright © 2017 Kozinga. All rights reserved.
//

import UIKit

class ServicesViewController : MyCollectionViewController {
  
  // MARK: - Class Accessors
  
  static func newViewController() -> ServicesViewController {
    return self.newViewController(fromStoryboard: .services)
  }
  
  // MARK: - Edit Mode Properties
  
  override var defaultViewTitle: String? {
    return "Bonjour"
  }
    
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.navigationItem.title = "Bonjour Services"
    
    let plusBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "plus.circle.fill"), style: .done, target: self, action: #selector(self.addButtonSelected(_:)))
    let sortBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "arrow.up.arrow.down.circle.fill"), style: .done, target: self, action: #selector(self.sortButtonSelected(_:)))
    self.navigationItem.rightBarButtonItems = [plusBarButtonItem, sortBarButtonItem]
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    NotificationCenter.default.addObserver(self, selector: #selector(self.reloadBrowsingServices), name: UIApplication.willEnterForegroundNotification, object: nil)
    
    MyBonjourManager.shared.delegate = self
    self.reloadBrowsingServices()
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    
    NotificationCenter.default.removeObserver(self)
  }
  
  // MARK: - Content
  
  var isBrowsingForServces: Bool? {
    didSet {
        guard let isBrowsingForServces = self.isBrowsingForServces else {
            return
        }
        
        if isBrowsingForServces != oldValue {
            if isBrowsingForServces {
                let spinner = UIActivityIndicatorView()
                spinner.startAnimating()
                self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: spinner)
            } else {
                self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "arrow.clockwise.circle.fill"), style: .done, target: self, action: #selector(self.reloadBrowsingServices))
            }
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
    
    @objc private func addButtonSelected(_ sender: UIBarButtonItem) {
        let viewController = PublishedServicesViewController.newViewController()
        viewController.presentControllerIn(self, forMode: .modal)
    }
  
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
  
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return self.services.count
  }
  
  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ServicesServiceCell.name, for: indexPath) as! ServicesServiceCell
    let service = self.services[indexPath.row]
    cell.configure(service: service)
    if UIDevice.isPad {
        cell.contentView.layer.cornerRadius = 20
        cell.contentView.layer.masksToBounds = true
    }
    return cell
  }
  
  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let service = self.services[indexPath.row]
    let viewController = ServiceDetailTableViewController.newViewController(browsedService: service)
    viewController.presentControllerIn(self, forMode: UIDevice.isPhone ? .navStack : .modal)
  }
}

// MARK: - MyBonjourManagerDelegate

extension ServicesViewController : MyBonjourManagerDelegate {
  
  func servicesDidUpdate(_ services: [MyNetService]) {
    self.reloadData()
  }
}

// MARK: - ServicesFooterViewDelegate

extension ServicesViewController{
  
  func servicesFooterSpecifyButtonSelected() {
    let viewController = CreateServiceTypeTableViewController.newViewController()
    viewController.presentControllerIn(self, forMode: .modal)
  }
}
