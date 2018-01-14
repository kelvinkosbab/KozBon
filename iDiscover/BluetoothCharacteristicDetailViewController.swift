//
//  BluetoothCharacteristicDetailViewController.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 1/7/18.
//  Copyright © 2018 Kozinga. All rights reserved.
//

import UIKit
import CoreBluetooth

class BluetoothCharacteristicDetailViewController : MyTableViewController {
  
  // MARK: - Class Accessors
  
  private static func newViewController() -> BluetoothCharacteristicDetailViewController {
    return self.newViewController(fromStoryboard: .bluetooth)
  }
  
  static func newViewController(device: MyBluetoothDevice, characteristic: CBCharacteristic) -> BluetoothCharacteristicDetailViewController {
    let viewController = self.newViewController()
    viewController.device = device
    viewController.characteristic = characteristic
    return viewController
  }
  
  // MARK: - Properties
  
  var device: MyBluetoothDevice!
  var characteristic: CBCharacteristic!
  
  var descriptors: [CBDescriptor] {
    return self.characteristic.descriptors ?? []
  }
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.title = self.device?.name
    
    self.device.discoverCharacteristicDescriptors { [weak self] in
      self?.reloadContent()
    }
  }
  
  // MARK: - Content
  
  func reloadContent() {
    self.tableView.reloadData()
  }
  
  // MARK: - SectionType
  
  enum SectionType {
    case general, properties, descriptors
    
    var title: String {
      switch self {
      case .general:
        return "General"
      case .properties:
        return "Properties"
      case .descriptors:
        return "Descriptors"
      }
    }
  }
  
  private func getSectionType(section: Int) -> SectionType? {
    switch section {
    case 0:
      return .general
    case 1:
      return .properties
    case 2:
      return .descriptors
    default:
      return nil
    }
  }
  
  // MARK: - RowType
  
  enum RowType {
    case uuid, hexValue, isBroadcast, isRead, isWriteWithoutResponse, isWrite, isNotify, isIndicate, isAuthenticatedSignedWrites, isExtendedProperties, isNotifyEncryptionRequired, isIndicateEncryptionRequired, noDescriptors, descriptor(CBDescriptor)
    
    var title: String {
      switch self {
      case .uuid:
        return "UUID"
      case .hexValue:
        return "Hex Value"
      case .isBroadcast:
        return "Broadcast"
      case .isRead:
        return "Read"
      case .isWriteWithoutResponse:
        return "Write W/O Response"
      case .isWrite:
        return "Write"
      case .isNotify:
        return "Notify"
      case .isIndicate:
        return "Indicate"
      case .isAuthenticatedSignedWrites:
        return "Authenticated Signed Writes"
      case .isExtendedProperties:
        return "Extended Properties"
      case .isNotifyEncryptionRequired:
        return "Indicate Notify Encryption"
      case .isIndicateEncryptionRequired:
        return "Indicate Encryption Required"
      case .noDescriptors:
        return "No Descriptors Discovered"
      case .descriptor(let descriptor):
        return descriptor.uuid.uuidString
      }
    }
  }
  
  private func getRowType(at indexPath: IndexPath) -> RowType? {
    
    guard let sectionType = self.getSectionType(section: indexPath.section) else {
      return nil
    }
    
    switch sectionType {
    case .general:
      switch indexPath.row {
      case 0:
        return .uuid
      case 1:
        return .hexValue
      default:
        return nil
      }
    case .properties:
      switch indexPath.row {
      case 0:
        return .isBroadcast
      case 1:
        return .isRead
      case 2:
        return .isWriteWithoutResponse
      case 3:
        return .isWrite
      case 4:
        return .isNotify
      case 5:
        return .isIndicate
      case 6:
        return .isAuthenticatedSignedWrites
      case 7:
        return .isExtendedProperties
      case 8:
        return .isNotifyEncryptionRequired
      case 9:
        return .isIndicateEncryptionRequired
      default:
        return nil
      }
    case .descriptors:
      if self.descriptors.count > 0 {
        let descriptor = self.descriptors[indexPath.row]
        return .descriptor(descriptor)
      } else {
        return .noDescriptors
      }
    }
  }
  
  // MARK: - UITableView
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 3
  }
  
  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    
    guard let sectionType = self.getSectionType(section: section) else {
      return nil
    }
    
    let cell = tableView.dequeueReusableCell(withIdentifier: ServiceDetailButtonHeaderCell.name) as! ServiceDetailButtonHeaderCell
    cell.configure(title: sectionType.title)
    return cell.contentView
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
    guard let sectionType = self.getSectionType(section: section) else {
      return 0
    }
    
    switch sectionType {
    case .general:
      return 2
    case .properties:
      return 10
    case .descriptors:
      let descriptors = self.descriptors
      if descriptors.count > 0 {
        return descriptors.count
      } else {
        return 1
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
    case .uuid:
      let cell = tableView.dequeueReusableCell(withIdentifier: ServiceDetailKeyValueCell.name, for: indexPath) as! ServiceDetailKeyValueCell
      cell.configure(key: rowType.title, value: self.device.uuid)
      return cell
    case .hexValue:
      let cell = tableView.dequeueReusableCell(withIdentifier: ServiceDetailKeyValueCell.name, for: indexPath) as! ServiceDetailKeyValueCell
      cell.configure(key: rowType.title, value: self.characteristic.value?.hexValue ?? "Unknown Value")
      return cell
    case .isBroadcast:
      let cell = tableView.dequeueReusableCell(withIdentifier: ServiceDetailKeyValueCell.name, for: indexPath) as! ServiceDetailKeyValueCell
      cell.configure(key: rowType.title, value: "\(self.characteristic.properties.contains(.broadcast) ? "YES" : "NO")")
      return cell
    case .isRead:
      let cell = tableView.dequeueReusableCell(withIdentifier: ServiceDetailKeyValueCell.name, for: indexPath) as! ServiceDetailKeyValueCell
      cell.configure(key: rowType.title, value: "\(self.characteristic.properties.contains(.read) ? "YES" : "NO")")
      return cell
    case .isWriteWithoutResponse:
      let cell = tableView.dequeueReusableCell(withIdentifier: ServiceDetailKeyValueCell.name, for: indexPath) as! ServiceDetailKeyValueCell
      cell.configure(key: rowType.title, value: "\(self.characteristic.properties.contains(.writeWithoutResponse) ? "YES" : "NO")")
      return cell
    case .isWrite:
      let cell = tableView.dequeueReusableCell(withIdentifier: ServiceDetailKeyValueCell.name, for: indexPath) as! ServiceDetailKeyValueCell
      cell.configure(key: rowType.title, value: "\(self.characteristic.properties.contains(.write) ? "YES" : "NO")")
      return cell
    case .isNotify:
      let cell = tableView.dequeueReusableCell(withIdentifier: ServiceDetailKeyValueCell.name, for: indexPath) as! ServiceDetailKeyValueCell
      cell.configure(key: rowType.title, value: "\(self.characteristic.properties.contains(.notify) ? "YES" : "NO")")
      return cell
    case .isIndicate:
      let cell = tableView.dequeueReusableCell(withIdentifier: ServiceDetailKeyValueCell.name, for: indexPath) as! ServiceDetailKeyValueCell
      cell.configure(key: rowType.title, value: "\(self.characteristic.properties.contains(.indicate) ? "YES" : "NO")")
      return cell
    case .isAuthenticatedSignedWrites:
      let cell = tableView.dequeueReusableCell(withIdentifier: ServiceDetailKeyValueCell.name, for: indexPath) as! ServiceDetailKeyValueCell
      cell.configure(key: rowType.title, value: "\(self.characteristic.properties.contains(.authenticatedSignedWrites) ? "YES" : "NO")")
      return cell
    case .isExtendedProperties:
      let cell = tableView.dequeueReusableCell(withIdentifier: ServiceDetailKeyValueCell.name, for: indexPath) as! ServiceDetailKeyValueCell
      cell.configure(key: rowType.title, value: "\(self.characteristic.properties.contains(.extendedProperties) ? "YES" : "NO")")
      return cell
    case .isNotifyEncryptionRequired:
      let cell = tableView.dequeueReusableCell(withIdentifier: ServiceDetailKeyValueCell.name, for: indexPath) as! ServiceDetailKeyValueCell
      cell.configure(key: rowType.title, value: "\(self.characteristic.properties.contains(.notifyEncryptionRequired) ? "YES" : "NO")")
      return cell
    case .isIndicateEncryptionRequired:
      let cell = tableView.dequeueReusableCell(withIdentifier: ServiceDetailKeyValueCell.name, for: indexPath) as! ServiceDetailKeyValueCell
      cell.configure(key: rowType.title, value: "\(self.characteristic.properties.contains(.indicateEncryptionRequired) ? "YES" : "NO")")
      return cell
    case .noDescriptors:
      let cell = tableView.dequeueReusableCell(withIdentifier: ServiceDetailSimpleCell.name, for: indexPath) as! ServiceDetailSimpleCell
      cell.configure(title: "No Descriptors Discovered")
      return cell
    case .descriptor(let descriptor):
      let cell = tableView.dequeueReusableCell(withIdentifier: ServiceDetailKeyValueCell.name, for: indexPath) as! ServiceDetailKeyValueCell
      cell.configure(key: "Descriptor UUID", value: descriptor.uuid.uuidString)
      return cell
    }
  }
}
