//
//  BluetoothViewController.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 1/17/17.
//  Copyright © 2017 Kozinga. All rights reserved.
//

import Foundation
import UIKit

class BluetoothViewController : MyCollectionViewController {
  
  // MARK: - Class Accessors
  
  static func newViewController() -> BluetoothViewController {
    return self.newViewController(fromStoryboard: .bluetooth)
  }
  
  // MARK: - Properties
  
  weak var loadingActivityIndicator: UIActivityIndicatorView? = nil
  
  var bluetoothManager: MyBluetoothManager {
    return MyBluetoothManager.shared
  }
  
  internal var devices: [MyBluetoothDevice] = [] {
    didSet {
      if self.isViewLoaded {
        self.collectionView?.reloadData()
      }
    }
  }
  
  // MARK: - Edit Mode Properties
  
  override var defaultViewTitle: String? {
    return "Bluetooth"
  }
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.title = "Bluetooth"
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    self.collectionView?.reloadData()
    self.bluetoothManager.delegate = self
    self.bluetoothManager.startScan()
    self.updateLoading()
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    
    self.bluetoothManager.stopScan()
    self.bluetoothManager.disconnectFromAllDevices()
  }
  
  // MARK: - Loading
  
  func updateLoading() {
    if self.bluetoothManager.state.isScanning {
      self.loadingActivityIndicator?.startAnimating()
      self.loadingActivityIndicator?.isHidden = false
    } else {
      self.loadingActivityIndicator?.stopAnimating()
      self.loadingActivityIndicator?.isHidden = true
    }
  }
  
  // MARK: - SectionType
  
  enum SectionType {
    case bluetoothUnsupported, devices
  }
  
  func getSectionType(section: Int) -> SectionType? {
    
    guard self.bluetoothManager.state != .unsupported else {
      return .bluetoothUnsupported
    }
    
    switch section {
    case 0:
      return .devices
    default:
      return nil
    }
  }
  
  // MARK: - RowType
  
  enum RowType {
    case bluetoothUnsupported, device(MyBluetoothDevice)
  }
  
  func getRowType(at indexPath: IndexPath) -> RowType? {
    
    guard let sectionType = self.getSectionType(section: indexPath.section) else {
      return nil
    }
    
    switch sectionType {
    case .bluetoothUnsupported:
      return .bluetoothUnsupported
    case .devices:
      let device = self.devices[indexPath.row]
      return .device(device)
    }
  }
  
  // MARK: - UICollectionView
  
  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }
  
  override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    switch kind {
    case UICollectionElementKindSectionHeader:
      
      guard let sectionType = self.getSectionType(section: indexPath.section) else {
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ServicesHeaderView.name, for: indexPath) as! ServicesHeaderView
        headerView.configure(nil, title: "")
        headerView.hideButtonAndSpinner()
        return headerView
      }
      
      switch sectionType {
      case .bluetoothUnsupported:
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ServicesHeaderView.name, for: indexPath) as! ServicesHeaderView
        headerView.configure(nil, title: "")
        headerView.hideButtonAndSpinner()
        return headerView
      case .devices:
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ServicesHeaderView.name, for: indexPath) as! ServicesHeaderView
        headerView.configure(nil, title: "Scanning for Bluetooth Services")
        headerView.hideButtonAndSpinner()
        return headerView
      }
      
    case UICollectionElementKindSectionFooter:
      let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "BluetoothFooterView", for: indexPath)
      footerView.backgroundColor = collectionView.backgroundColor
      return footerView
      
    default:
      return super.collectionView(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath)
    }
  }
  
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    
    guard let sectionType = self.getSectionType(section: section) else {
      return 0
    }
    
    switch sectionType {
    case .bluetoothUnsupported:
      return 1
    case .devices:
      return self.devices.count
    }
  }
  
  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
    guard let rowType = self.getRowType(at: indexPath) else {
      let cell = UICollectionViewCell()
      cell.backgroundColor = collectionView.backgroundColor
      return cell
    }
    
    switch rowType {
    case .bluetoothUnsupported:
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BluetoothUnsupportedCell.name, for: indexPath) as! BluetoothUnsupportedCell
      return cell
    case .device(let device):
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ServicesServiceCell.name, for: indexPath) as! ServicesServiceCell
      cell.configure(title: device.name, detail: device.uuid)
      return cell
    }
  }
  
  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    
    guard let rowType = self.getRowType(at: indexPath) else {
      return
    }
    
    switch rowType {
    case .device(let device):
      let viewController = BluetoothDeviceDetailViewController.newViewController(device: device)
      viewController.presentControllerIn(self, forMode: UIDevice.isPhone ? .navStack : .modal)
    default: break
    }
  }
  
  // MARK: - UICollectionViewDelegateFlowLayout
  
  override func sizeForItemAt(indexPath: IndexPath, collectionView: UICollectionView) -> CGSize {
    
    let defaultSize = super.sizeForItemAt(indexPath: indexPath, collectionView: collectionView)
    guard let rowType = self.getRowType(at: indexPath) else {
      return defaultSize
    }
    
    
    switch rowType {
    case .bluetoothUnsupported:
      return CGSize(width: collectionView.bounds.width, height: defaultSize.height)
    default:
      return defaultSize
    }
  }
}

// MARK: - MyBluetoothManagerDelegate

extension BluetoothViewController : MyBluetoothManagerDelegate {
  
  func didStartScan(_ manager: MyBluetoothManager) {
    self.updateLoading()
  }
  
  func didUpdateDevices(_ manager: MyBluetoothManager) {
    self.devices = manager.devices.nameSorted
  }
  
  func didStopScan(_ manager: MyBluetoothManager) {
    self.updateLoading()
  }
}

// MARK: - Collection View Cells

class BluetoothUnsupportedCell : UICollectionViewCell {
  @IBOutlet weak var titleLabel: UILabel!
}
