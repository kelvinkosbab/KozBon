//
//  MyBluetoothManager.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 1/7/18.
//  Copyright © 2018 Kozinga. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol MyBluetoothManagerDelegate : class {
  func didStartScan(_ manager: MyBluetoothManager)
  func didUpdateDevices(_ manager: MyBluetoothManager)
  func didStopScan(_ manager: MyBluetoothManager)
}

class MyBluetoothManager: NSObject, CBCentralManagerDelegate {
  
  // MARK: - Singleton
  
  static let shared = MyBluetoothManager()
  
  private override init() {
    let dispatchQueue = DispatchQueue(label: "\(MyBluetoothManager.name).centralManagerQueue.\(UUID().uuidString)")
    self.centralManager = CBCentralManager(delegate: nil, queue: dispatchQueue)
    super.init()
    self.centralManager.delegate = self
  }
  
  // MARK: - Properties
  
  weak var delegate: MyBluetoothManagerDelegate? = nil
  private let centralManager: CBCentralManager
  
  var state: CBManagerState {
    return self.centralManager.state
  }
  
  // MARK: - Devices
  
  private(set) var devices: Set<MyBluetoothDevice> = Set<MyBluetoothDevice>() {
    didSet {
      self.delegate?.didUpdateDevices(self)
    }
  }
  
  private func clearDevices() {
    for device in self.devices {
      self.remove(device: device)
    }
  }
  
  private func add(device: MyBluetoothDevice) {
    if !self.devices.contains(device) {
      self.devices.insert(device)
    }
  }
  
  private func remove(device: MyBluetoothDevice) {
    self.devices.remove(device)
  }
  
  private func fetchDevice(peripheral: CBPeripheral) -> MyBluetoothDevice? {
    return self.devices.first(where: { $0.peripheral == peripheral })
  }
  
  // MARK: - Start / Stop Scan
  
  func startScan() {
    if self.state != .unsupported {
      self.scanForDevices()
    }
  }
  
  func stopScan() {
    if self.state != .unsupported {
      self.delegate?.didStopScan(self)
      self.centralManager.stopScan()
    }
  }
  
  // MARK: - CBCentralManagerDelegate
  
  private func scanForDevices() {
    self.centralManager.delegate = self
    if self.centralManager.state == .poweredOn {
      self.delegate?.didStartScan(self)
      self.centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
  }
  
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    Log.log("State is now \(self.state.string)")
    switch self.state {
    case .poweredOn:
      self.scanForDevices()
    case .poweredOff:
      self.stopScan()
    default: break
    }
  }
  
  func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
    Log.log("Did discover peripheral \(peripheral) | RSSI \(RSSI) | advertisement data \(advertisementData)")
    
    let device = MyBluetoothDevice(peripheral: peripheral, lastKnownRSSI: RSSI.intValue)
    self.add(device: device)
  }
  
  // MARK: - Connecting to Devices
  
  func connect(device: MyBluetoothDevice, options: [String : Any]? = nil, completion: @escaping (_ error: Error?) -> Void) {
    
    // Connect to the peripheral
    device.connectCompletion = completion
    self.centralManager.connect(device.peripheral, options: options)
  }
  
  func connectAndConfigure(device: MyBluetoothDevice, completion: @escaping (_ error: Error?) -> Void) {
    self.connect(device: device) { (error) in
      if let error = error {
        completion(error)
      } else {
        device.configure {
          completion(nil)
        }
      }
    }
  }
  
  // MARK: - Disconnecting from Devices
  
  func disconnect(device: MyBluetoothDevice, completion: @escaping (_ error: Error?) -> Void) {
    
    // Disconnect from the peripheral
    device.connectCompletion = completion
    self.centralManager.cancelPeripheralConnection(device.peripheral)
  }
  
  func disconnectFromAllDevices(completion: (() -> Void)? = nil) {
    let dispatchGroup = DispatchGroup()
    for device in self.devices {
      dispatchGroup.enter()
      self.disconnect(device: device, completion: { (_) in
        dispatchGroup.leave()
      })
    }
    
    dispatchGroup.notify(queue: .main) {
      completion?()
    }
  }
  
  // MARK: - Peripheral Connect/Disconnect Delegate Methods
  
  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    Log.log("Did connect to peripheral \(peripheral)")
    
    if let firstDevice = self.fetchDevice(peripheral: peripheral) {
      firstDevice.connectCompletion?(nil)
    }
  }
  
  func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
    Log.log("Did fail to connect to peripheral \(peripheral) with error \(error?.localizedDescription ?? "Unknown Error")")
    
    if let firstDevice = self.fetchDevice(peripheral: peripheral) {
      firstDevice.connectCompletion?(error)
    }
  }
  
  func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
    Log.log("Did disconnect from peripheral \(peripheral) with error \(error?.localizedDescription ?? "Unknown Error")")
    
    if let firstDevice = self.fetchDevice(peripheral: peripheral) {
      firstDevice.connectCompletion?(error)
    }
  }
}
