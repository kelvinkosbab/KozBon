//
//  BluetoothViewController.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 1/17/17.
//  Copyright © 2017 Kozinga. All rights reserved.
//

import Foundation
import UIKit

class BluetoothViewController : MyTableViewController {
  
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
        self.tableView.reloadData()
      }
    }
  }
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.title = "Bluetooth"
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    self.tableView.reloadData()
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
  
  // MARK: - UITableView
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    
    guard let sectionType = self.getSectionType(section: section) else {
      return nil
    }
    
    switch sectionType {
    case .bluetoothUnsupported:
      return super.tableView(tableView, viewForHeaderInSection: section)
    case .devices:
      let cell = tableView.dequeueReusableCell(withIdentifier: NetServicesTableHeaderCell.name) as! NetServicesTableHeaderCell
      cell.titleLabel.text = "Scanning".uppercased()
      cell.loadingActivityIndicator.startAnimating()
      self.loadingActivityIndicator = cell.loadingActivityIndicator
      cell.loadingActivityIndicator.isHidden = false
      cell.reloadButton.isHidden = true
      cell.reloadButton.isUserInteractionEnabled = false
      return cell.contentView
    }
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
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
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    guard let rowType = self.getRowType(at: indexPath) else {
      let cell = UITableViewCell()
      cell.backgroundColor = tableView.backgroundColor
      return cell
    }
    
    switch rowType {
    case .bluetoothUnsupported:
      let cell = tableView.dequeueReusableCell(withIdentifier: MyBasicCenterLabelCell.name, for: indexPath) as! MyBasicCenterLabelCell
      cell.titleLabel.text = "Bluetooth is Unsupported"
      return cell
    case .device(let device):
      let cell = tableView.dequeueReusableCell(withIdentifier: BluetoothDeviceCell.name, for: indexPath) as! BluetoothDeviceCell
      cell.configure(device: device)
      return cell
    }
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    
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
