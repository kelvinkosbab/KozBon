//
//  BluetoothDeviceDetailViewController.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 1/7/18.
//  Copyright © 2018 Kozinga. All rights reserved.
//

import UIKit
import CoreBluetooth

class BluetoothDeviceDetailViewController : MyTableViewController {
  
  // MARK: - Class Accessors
  
  private static func newViewController() -> BluetoothDeviceDetailViewController {
    return self.newViewController(fromStoryboard: .bluetooth)
  }
  
  static func newViewController(device: BluetoothDevice) -> BluetoothDeviceDetailViewController {
    let viewController = self.newViewController()
    viewController.device = device
    return viewController
  }
  
  // MARK: - Properties
  
  var device: BluetoothDevice!
  
  let bluetoothManager = BluetoothDeviceScanner()
  
  var services: [CBService] = []
  var serviceCharacteristics: [CBService : [CBCharacteristic]] = [:]
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.title = self.device.name
    
    if self.navigationController?.viewControllers.first == self {
      self.navigationItem.leftBarButtonItem = UIBarButtonItem(text: "Done", target: self, action: #selector(self.doneButtonSelected(_:)))
    }
    
    // Connect to the device
    self.bluetoothManager.connect(device: self.device) { [weak self] _ in
      self?.reloadContent()
      self?.device.discoverServices { [weak self] in
        self?.reloadContent()
        self?.device.discoverCharacteristics { [weak self] in
          self?.reloadContent()
        }
      }
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    self.device.delegate = self
    self.device.servicesDelegate = self
  }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.bluetoothManager.disconnect(device: self.device, completion: { _ in })
    }
  
  // MARK: - Content
  
  func reloadContent() {
    self.services = self.device.services
    self.serviceCharacteristics = [:]
    for service in self.services {
      self.serviceCharacteristics[service] = service.characteristics ?? []
    }
    self.tableView.reloadData()
  }
  
  // MARK: - Actions
  
  @objc private func doneButtonSelected(_ sender: UIBarButtonItem) {
    self.dismissController()
  }
  
  // MARK: - SectionType
  
  enum SectionType {
    case info, service(CBService)
  }
  
  private func getSectionType(section: Int) -> SectionType? {
    switch section {
    case 0:
      return .info
    default:
      let serviceIndex = section - 1
      if self.services.count > serviceIndex {
        let service = self.services[serviceIndex]
        return .service(service)
      } else {
        return nil
      }
    }
  }
  
  // MARK: - RowType
  
  enum RowType {
    case name, connectionState, lastKnownRssi, totalServices, noCharacteristics, characteristic(CBCharacteristic)
  }
  
  private func getRowType(at indexPath: IndexPath) -> RowType? {
    
    guard let sectionType = self.getSectionType(section: indexPath.section) else {
      return nil
    }
    
    switch sectionType {
    case .info:
      switch indexPath.row {
      case 0:
        return .name
      case 1:
        return .connectionState
      case 2:
        return .lastKnownRssi
      case 3:
        return .totalServices
      default:
        return nil
      }
        
    case .service(let service):
      let characteristics = self.serviceCharacteristics[service] ?? []
      if characteristics.count == 0 {
        return .noCharacteristics
      } else {
        let characteristic = characteristics[indexPath.row]
        return .characteristic(characteristic)
      }
    }
  }
  
  // MARK: - UITableView
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1 + self.device.services.count
  }
  
  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    
    guard let sectionType = self.getSectionType(section: section) else {
      return nil
    }
    
    let cell = tableView.dequeueReusableCell(withIdentifier: ServiceDetailSimpleHeaderCell.name) as! ServiceDetailSimpleHeaderCell
    cell.contentView.backgroundColor = .systemBackground
    switch sectionType {
    case .info:
      cell.configure(title: "Information")
    case .service(let service):
      cell.configure(title: "#\(section): \(service.uuid.uuidString)")
    }
    return cell.contentView
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
    guard let sectionType = self.getSectionType(section: section) else {
      return 0
    }
    
    switch sectionType {
    case .info:
      return 4
    case .service(let service):
      let characteristics = service.characteristics ?? []
      if characteristics.count == 0 {
        return 1
      } else {
        return characteristics.count
      }
    }
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    guard let rowType = self.getRowType(at: indexPath) else {
      let cell = UITableViewCell()
      cell.backgroundColor = tableView.backgroundColor
      return cell
    }
    
    switch rowType {
    case .name:
      let cell = tableView.dequeueReusableCell(withIdentifier: ServiceDetailAddressCell.name, for: indexPath) as! ServiceDetailAddressCell
        cell.contentView.backgroundColor = .secondarySystemBackground
        cell.configure(title: "Name", detail: self.device.name ?? "")
      return cell
    case .connectionState:
      let cell = tableView.dequeueReusableCell(withIdentifier: ServiceDetailAddressCell.name, for: indexPath) as! ServiceDetailAddressCell
        cell.contentView.backgroundColor = .secondarySystemBackground
      cell.configure(title: "State", detail: self.device.state.string)
      return cell
    case .lastKnownRssi:
      let cell = tableView.dequeueReusableCell(withIdentifier: ServiceDetailAddressCell.name, for: indexPath) as! ServiceDetailAddressCell
        cell.contentView.backgroundColor = .secondarySystemBackground
      if let lastKnownRSSI = self.device.lastKnownRSSI {
        cell.configure(title: "RSSI", detail: "\(lastKnownRSSI)")
      } else {
        cell.configure(title: "RSSI", detail: "Unknown")
      }
      return cell
    case .totalServices:
      let cell = tableView.dequeueReusableCell(withIdentifier: ServiceDetailAddressCell.name, for: indexPath) as! ServiceDetailAddressCell
        cell.contentView.backgroundColor = .secondarySystemBackground
      cell.configure(title: "Total Services", detail: "\(self.device.services.count) services")
      return cell
    case .noCharacteristics:
      let cell = tableView.dequeueReusableCell(withIdentifier: ServiceDetailSimpleCell.name, for: indexPath) as! ServiceDetailSimpleCell
        cell.contentView.backgroundColor = .secondarySystemBackground
      cell.configure(title: "No Characteristics Discovered")
      return cell
    case .characteristic(let characteristic):
      let cell = tableView.dequeueReusableCell(withIdentifier: BluetoothDeviceCell.name, for: indexPath) as! BluetoothDeviceCell
        cell.contentView.backgroundColor = .secondarySystemBackground
      cell.configure(title: characteristic.uuid.uuidString, detail: characteristic.value?.hexValue ?? "Unknown Value")
      return cell
    }
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    
    guard let rowType = self.getRowType(at: indexPath) else {
      return
    }
    
    switch rowType {
    case .characteristic(let characteristic):
      let viewController = BluetoothCharacteristicDetailViewController.newViewController(device: self.device, characteristic: characteristic)
      viewController.presentControllerIn(self, forMode: .navStack)
    default: break
    }
  }
}

// MARK: - BluetoothDeviceDelegate

extension BluetoothDeviceDetailViewController : BluetoothDeviceDelegate {
  
  func didUpdate(_ device: BluetoothDevice) {
    self.reloadContent()
  }
}

// MARK: - BluetoothDeviceDelegate

extension BluetoothDeviceDetailViewController : BluetoothDeviceServicesDelegate {
  
  func didUpdateServices(_ device: BluetoothDevice) {
    self.reloadContent()
  }
}
