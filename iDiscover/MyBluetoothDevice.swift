//
//  MyBluetoothDevice.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 1/7/18.
//  Copyright © 2018 Kozinga. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol MyBluetoothDeviceDelegate : class {
  func didUpdate(_ device: MyBluetoothDevice)
}

protocol MyBluetoothDeviceServicesDelegate : class {
  func didUpdateServices(_ device: MyBluetoothDevice)
}

class MyBluetoothDevice : NSObject, CBPeripheralDelegate {
  
  // MARK: - Hashable
  
  override var hashValue: Int {
    return self.uuid.hashValue
  }
  
  // MARK: - Equatable
  
  static func ==(lhs: MyBluetoothDevice, rhs: MyBluetoothDevice) -> Bool {
    return lhs.uuid == rhs.uuid
  }
  
  // MARK: - Properties and Init
  
  let peripheral: CBPeripheral
  var connectCompletion: ((_ error: Error?) -> Void)? = nil
  weak var delegate: MyBluetoothDeviceDelegate? = nil
  weak var servicesDelegate: MyBluetoothDeviceServicesDelegate? = nil
  
  init(peripheral: CBPeripheral, lastKnownRSSI rssi: Int? = nil) {
    self.peripheral = peripheral
    self.lastKnownRSSI = rssi
    super.init()
    
    peripheral.delegate = self
  }
  
  // MARK: - Helpers
  
  var uuid: String {
    return self.peripheral.identifier.uuidString
  }
  
  var state: CBPeripheralState {
    return self.peripheral.state
  }
  
  // MARK: - Name
  
  var name: String? {
    return self.peripheral.name
  }
  
  // MARK: - RSSI
  
  var lastKnownRSSI: Int? = nil {
    didSet {
      if self.lastKnownRSSI != oldValue {
        self.delegate?.didUpdate(self)
      }
    }
  }
  
  private var readRSSICompletion: ((_ RSSI: Int) -> Void)? = nil
  
  func readRSSI(completion: ((_ RSSI: Int) -> Void)? = nil) {
    self.readRSSICompletion = completion
    self.peripheral.readRSSI()
  }
  
  func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
    Log.log("Did read RSSI \(self.name ?? "Unknown Name")")
    
    self.lastKnownRSSI = RSSI.intValue
    self.readRSSICompletion?(RSSI.intValue)
    self.readRSSICompletion = nil
  }
  
  // MARK: - Configuration
  
  func configure(completion: (() -> Void)? = nil) {
    self.discoverServices { [weak self] in
      self?.discoverCharacteristics {
        completion?()
      }
    }
  }
  
  // MARK: - Services
  
  var services: [CBService] {
    return self.peripheral.services ?? []
  }
  
  private var discoverServicesCompletion: (() -> Void)? = nil
  
  private func discoverServices(serviceUUIDs: [CBUUID]? = nil, completion: (() -> Void)? = nil) {
    self.discoverServicesCompletion = completion
    self.peripheral.discoverServices(serviceUUIDs)
  }
  
  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    Log.log("Did discover services")
    
    self.discoverServicesCompletion?()
    self.discoverServicesCompletion = nil
    self.servicesDelegate?.didUpdateServices(self)
  }
  
  func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
    Log.log("Did modify services")
    
    self.servicesDelegate?.didUpdateServices(self)
  }
  
  // MARK: - Characteristics
  
  private var characteristicDiscoveryHandler: (() -> Void)? = nil
  private var servicesToDiscoverCharacteristics: Set<CBService> = Set<CBService>()
  
  func discoverCharacteristics(characteristicUUIDs: [CBUUID]? = nil, completion: @escaping () -> Void) {
    self.characteristicDiscoveryHandler = completion
    self.servicesToDiscoverCharacteristics = Set(self.services)
    for service in self.services {
      self.peripheral.discoverCharacteristics(characteristicUUIDs, for: service)
    }
  }
  
  func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    Log.log("Did discover \(service.characteristics?.count ?? 0) characteristics for service \(service)")
    
    // No longer discovering characteristics for this service
    self.servicesToDiscoverCharacteristics.remove(service)
    
    // Check if done discovering characteristics
    if self.servicesToDiscoverCharacteristics.count == 0 {
      self.characteristicDiscoveryHandler?()
      self.characteristicDiscoveryHandler = nil
    }
    
    // Store a reference to the data characteristic
    for characteristic in service.characteristics ?? [] {
      self.startNotifications(characteristic: characteristic)
    }
  }
  
  // MARK: - Characteristic Descriptors
  
  private var descriptorDiscoveryHandler: (() -> Void)? = nil
  private var characteristicsToDiscoverDescriptors: Set<CBCharacteristic> = Set<CBCharacteristic>()
  
  func discoverCharacteristicDescriptors(completion: @escaping () -> Void) {
    self.descriptorDiscoveryHandler = completion
    self.characteristicsToDiscoverDescriptors = Set<CBCharacteristic>()
    for service in self.services {
      for characteristic in service.characteristics ?? [] {
        self.characteristicsToDiscoverDescriptors.insert(characteristic)
        self.peripheral.discoverDescriptors(for: characteristic)
      }
    }
  }
  
  func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
    Log.log("Did discover \(characteristic.descriptors?.count ?? 0) descriptors for characteristic \(characteristic)")
    
    // No longer discovering characteristics for this service
    self.characteristicsToDiscoverDescriptors.remove(characteristic)
    
    // Check if done discovering descriptors
    if self.characteristicsToDiscoverDescriptors.count == 0 {
      self.descriptorDiscoveryHandler?()
      self.descriptorDiscoveryHandler = nil
    }
  }
  
  // MARK: - Notifications and Updates to Characteristics
  
  private func startNotifications(characteristic: CBCharacteristic) {
    self.peripheral.setNotifyValue(true, for: characteristic)
  }
  
  func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
    Log.logMethodExecution()
  }
}

// MARK: - Sequence

extension Sequence where Iterator.Element : MyBluetoothDevice {
  
  var nameSorted: [MyBluetoothDevice] {
    return self.sorted { (device1, device2) -> Bool in
      return device1.name ?? "" < device2.name ?? ""
    }
  }
}

// MARK: - CBPeripheralState

extension CBPeripheralState {
  
  var string: String {
    switch self {
    case .connected:
      return "Connected"
    case .connecting:
      return "Connecting"
    case .disconnected:
      return "Disconnected"
    case .disconnecting:
      return "Disconnecting"
    }
  }
}
