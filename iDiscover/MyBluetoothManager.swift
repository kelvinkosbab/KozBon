//
//  MyBluetoothManager.swift
//  iDiscover
//
//  Created by Kelvin Kosbab on 12/26/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol MyBluetoothManagerProtocol {
  func didStartScan(_ manager: MyBluetoothManager)
  func didAddDevice(_ manager: MyBluetoothManager, device: MyBluetoothDevice)
  func didRemoveDevice(_ manager: MyBluetoothManager, device: MyBluetoothDevice)
  func didClearDevices(_ manager: MyBluetoothManager)
  func didStopScan(_ manager: MyBluetoothManager)
}

class MyBluetoothManager: NSObject, CBCentralManagerDelegate {
  
  // MARK: - Singleton
  
  static let shared = MyBluetoothManager()
  
  private override init() {
    super.init()
    
    self.centralManager = CBCentralManager(delegate: self, queue: self.centralManagerDispatchQueue)
  }
  
  // MARK: - Properties
  
  var delegate: MyBluetoothManagerProtocol? = nil
  
  private var centralManager: CBCentralManager!
  private let centralManagerDispatchQueue: DispatchQueue = DispatchQueue(label: "\(MyBluetoothManager.name).centralManagerQueue")
  private let concurrentDevicesQueue: DispatchQueue = DispatchQueue(label: "\(MyBluetoothManager.name).concurrentDevicesQueue", attributes: .concurrent)
  
  var state: MyBluetoothManagerState {
    return self.centralManager.bluetoothManagerState
  }
  
  // MARK: - Devices
  
  private var _devices: [MyBluetoothDevice] = []
  
  var devices: [MyBluetoothDevice] {
    var copy: [MyBluetoothDevice]!
    self.concurrentDevicesQueue.sync {
      copy = self._devices
    }
    return copy
  }
  
  private func clearDevices() {
    self.concurrentDevicesQueue.async(flags: .barrier, execute: { () -> Void in
      DispatchQueue.main.async {
        self.delegate?.didClearDevices(self)
      }
    })
  }
  
  private func add(device: MyBluetoothDevice) {
    self.concurrentDevicesQueue.async(flags: .barrier, execute: { () -> Void in
      if !self._devices.contains(device) {
        self._devices.append(device)
        DispatchQueue.main.async {
          self.delegate?.didAddDevice(self, device: device)
        }
      }
    })
  }
  
  private func remove(device: MyBluetoothDevice) {
    self.concurrentDevicesQueue.async(flags: .barrier, execute: { () -> Void in
      if let index = self._devices.index(of: device) {
        self._devices.remove(at: index)
        DispatchQueue.main.async {
          self.delegate?.didRemoveDevice(self, device: device)
        }
      }
    })
  }
  
  // MARK: - Start / Stop Scan
  
  func startScan() {
    self.stopScan()
    self.clearDevices()
  }
  
  func stopScan() {
    if !self.state.isUnsupported {
      self.centralManager.stopScan()
    }
    self.delegate?.didStopScan(self)
  }
  
  // MARK: - CBCentralManagerDelegate
  
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    let state = central.bluetoothManagerState
    print("\(self.className) : State is now \(state.string)")
    if state.isPoweredOn {
      
      // Start the scan
      self.delegate?.didStartScan(self)
      self.centralManager.scanForPeripherals(withServices: nil, options: nil)
      
      // Initialise timeout
      DispatchQueue.main.asyncAfter(after: 10.0) {
        self.stopScan()
      }
      
    } else if state.isUnsupported {
      self.stopScan()
    }
  }
  
  func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
    print("\(self.className) : Did discover peripheral \(peripheral) | RSSI \(RSSI) | advertisement data \(advertisementData)")
    
    let device = MyBluetoothDevice(peripheral: peripheral)
    self.add(device: device)
  }
  
  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    print("\(self.className) : Did connect to peripheral \(peripheral)")
  }
  
  func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
    print("\(self.className) : Did fail to connect to peripheral \(peripheral) with error \(error?.localizedDescription)")
  }
  
  func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
    print("\(self.className) : Did disconnect from peripheral \(peripheral) with error \(error?.localizedDescription)")
  }
}
