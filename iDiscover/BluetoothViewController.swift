//
//  BluetoothViewController.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 1/17/17.
//  Copyright © 2017 Kozinga. All rights reserved.
//

import Foundation
import UIKit

class BluetoothViewController : MyTableViewController, MyBluetoothManagerProtocol {
  
  // MARK: - Class Accessors
  
  static func newViewController() -> BluetoothViewController {
    return self.newController(fromStoryboard: .main, withIdentifier: self.name) as! BluetoothViewController
  }
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.title = "Bluetooth"
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    MyBluetoothManager.shared.startScan()
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    
    MyBluetoothManager.shared.stopScan()
  }
  
  // MARK: - MyBluetoothManagerProtocol
  
  func didStartScan(_ manager: MyBluetoothManager) {
    
  }
  
  func didAddDevice(_ manager: MyBluetoothManager, device: MyBluetoothDevice) {
    self.tableView.reloadData()
  }
  
  func didRemoveDevice(_ manager: MyBluetoothManager, device: MyBluetoothDevice) {
    self.tableView.reloadData()
  }
  
  func didClearDevices(_ manager: MyBluetoothManager) {
    self.tableView.reloadData()
  }
  
  func didStopScan(_ manager: MyBluetoothManager) {
    
  }
  
  // MARK: - UITableView
  
  let bluetoothDevicesSection: Int = 0
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    if section == self.bluetoothDevicesSection && !MyBluetoothManager.shared.state.isUnsupported {
      let cell = tableView.dequeueReusableCell(withIdentifier: NetServicesTableHeaderCell.name) as! NetServicesTableHeaderCell
      cell.titleLabel.text = "Scanning".uppercased()
      cell.loadingActivityIndicator.startAnimating()
      cell.loadingActivityIndicator.isHidden = false
      cell.reloadButton.isHidden = true
      cell.reloadButton.isUserInteractionEnabled = false
      return cell.contentView
    }
    return super.tableView(tableView, viewForHeaderInSection: section)
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == self.bluetoothDevicesSection {
      if MyBluetoothManager.shared.state.isUnsupported {
        return 1
      }
      return MyBluetoothManager.shared.devices.count + 1
    }
    return 0
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    if indexPath.section == self.bluetoothDevicesSection {
      
      if MyBluetoothManager.shared.state.isUnsupported {
        let cell = tableView.dequeueReusableCell(withIdentifier: MyBasicCenterLabelCell.name, for: indexPath) as! MyBasicCenterLabelCell
        cell.titleLabel.text = "Bluetooth is Unsupported"
        return cell
        
      } else if indexPath.row == MyBluetoothManager.shared.devices.count {
        // Loading cell
        let cell = tableView.dequeueReusableCell(withIdentifier: NetServicesTableLoadingCell.name, for: indexPath) as! NetServicesTableLoadingCell
        cell.loadingActivityIndicator.startAnimating()
        return cell
      }
      
      // Device
      let device = MyBluetoothManager.shared.devices[indexPath.row]
      let cell = tableView.dequeueReusableCell(withIdentifier: NetServicesTableServiceCell.name, for: indexPath) as! NetServicesTableServiceCell
      cell.nameLabel.text = device.peripheral.name ?? "Unnamaed"
      cell.hostLabel.text = device.peripheral.identifier.uuidString
      return cell
    }
    
    return UITableViewCell()
  }
}
