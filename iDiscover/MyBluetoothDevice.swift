//
//  MyBluetoothDevice.swift
//  iDiscover
//
//  Created by Kelvin Kosbab on 12/26/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol MyBluetoothDeviceProtocol {
  func didUpdate(_ device: MyBluetoothDevice)
  func didUpdateServices(_ device: MyBluetoothDevice)
  func didInvalidateService(_ device: MyBluetoothDevice, service: MyBluetoothService)
  func didDiscoverCharacteristicsFor(_ device: MyBluetoothDevice, service: MyBluetoothService)
}

class MyBluetoothDevice : NSObject, CBPeripheralDelegate {
  
  // MARK: Equatable
  
  static func ==(lhs: MyBluetoothDevice, rhs: MyBluetoothDevice) -> Bool {
    return lhs.peripheral == rhs.peripheral
  }
  
  // MARK: - Properties and Init
  
  var delegate: MyBluetoothDeviceProtocol? = nil
  
  let manager: MyBluetoothManager
  private let peripheral: CBPeripheral
  
  init(manager: MyBluetoothManager, peripheral: CBPeripheral, lastKnownRSSI rssi: Int? = nil) {
    self.manager = manager
    self.peripheral = peripheral
    self.lastKnownRSSI = rssi
    super.init()
    
    self.connect { (_) in
      self.readRSSI()
      self.discoverServices()
    }
  }
  
  // MARK: - Helpers
  
  var uuid: String {
    return self.peripheral.identifier.uuidString
  }
  
  var state: CBPeripheralState {
    return self.peripheral.state
  }
  
  // MARK: - Name
  
  var name: String {
    if let name = self.peripheral.name {
      return name
    }
    return "Unnamed Device"
  }
  
  func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
    print("\(self.className) : Did update name \(self.name)")
    
    self.delegate?.didUpdate(self)
  }
  
  // MARK: - Connecting
  
  internal var connectCompletion: ((_ error: Error?) -> Void)? = nil
  
  func connect(options: [String : Any]? = nil, completion: @escaping (_ error: Error?) -> Void) {
    self.connectCompletion = completion
    
    guard self.state.isConnected else {
      self.didConnect(device: self)
      return
    }
    
    guard self.state.isConnecting else {
      return
    }
    
    // Connect to the peripheral
    self.manager.centralManager?.connect(self.peripheral, options: options)
  }
  
  // MARK: - Disconnecting
  
  internal var disconnectCompletion: (() -> Void)? = nil
  
  func disconnect(completion: @escaping () -> Void) {
    self.disconnectCompletion = completion
    
    guard self.state.isDisconnected else {
      self.didConnect(device: self)
      return
    }
    
    guard self.state.isDisconnecting else {
      return
    }
    
    // Disconnect from the peripheral
    self.manager.centralManager?.cancelPeripheralConnection(self.peripheral)
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
    
    guard self.state.isConnected else {
      print("\(self.className) : \(self.name) : Cannot perform operation device not connected")
      return
    }
    
    self.readRSSICompletion = completion
    self.peripheral.readRSSI()
  }
  
  func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
    print("\(self.className) : Did read RSSI \(peripheral.name)")
    
    let newRSSI = Int(RSSI)
    self.lastKnownRSSI = newRSSI
    
    self.readRSSICompletion?(newRSSI)
    self.readRSSICompletion = nil
  }
  
  // MARK: - Services
  
  var services: [MyBluetoothService] {
    var services: [MyBluetoothService] = []
    for service in self.peripheral.services ?? [] {
      services.append(MyBluetoothService(device: self, service: service))
    }
    return services
  }
  
  private var discoverServicesCompletion: ((_ services: [MyBluetoothService]) -> Void)? = nil
  
  func discoverServices(serviceUUIDs: [CBUUID]? = nil, completion: ((_ services: [MyBluetoothService]) -> Void)? = nil) {
    
    guard self.state.isConnected else {
      print("\(self.className) : \(self.name) : Cannot perform operation device not connected")
      return
    }
    
    self.discoverServicesCompletion = completion
    self.peripheral.discoverServices(serviceUUIDs)
  }
  
  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    print("\(self.className) : Did discover services")
    
    self.discoverServicesCompletion?(self.services)
    self.discoverServicesCompletion = nil
    self.delegate?.didUpdateServices(self)
    self.delegate?.didUpdate(self)
  }
  
  func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
    print("\(self.className) : Did modify services")
    
    for service in invalidatedServices {
      let invalidatedService = MyBluetoothService(device: self, service: service)
      self.delegate?.didInvalidateService(self, service: invalidatedService)
    }
    self.delegate?.didUpdateServices(self)
    self.delegate?.didUpdate(self)
  }
}

extension MyBluetoothDevice : MyBluetoothManagerDeviceProtocol {
  
  func didConnect(device: MyBluetoothDevice) {
    self.connectCompletion?(nil)
    self.connectCompletion = nil
    self.delegate?.didUpdate(self)
  }
  
  func didFailToConnect(device: MyBluetoothDevice, error: Error) {
    self.connectCompletion?(error)
    self.connectCompletion = nil
    self.delegate?.didUpdate(self)
  }
  
  func didDisconnect(device: MyBluetoothDevice) {
    self.disconnectCompletion?()
    self.disconnectCompletion = nil
    self.delegate?.didUpdate(self)
  }
}
