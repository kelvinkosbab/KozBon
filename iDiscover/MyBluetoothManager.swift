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
  func didUpdateDevices(_ manager: MyBluetoothManager)
  func didStopScan(_ manager: MyBluetoothManager)
}

protocol MyBluetoothManagerDeviceProtocol {
  func didConnect(device: MyBluetoothDevice)
  func didFailToConnect(device: MyBluetoothDevice, error: Error)
  func didDisconnect(device: MyBluetoothDevice)
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
  
  var centralManager: CBCentralManager? = nil
  private let centralManagerDispatchQueue: DispatchQueue = DispatchQueue(label: "\(MyBluetoothManager.name).centralManagerQueue")
  private let concurrentDevicesQueue: DispatchQueue = DispatchQueue(label: "\(MyBluetoothManager.name).concurrentDevicesQueue", attributes: .concurrent)
  
  var state: CBManagerState {
    return self.centralManager?.state ?? .unknown
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
    for device in self.devices {
      self.remove(device: device)
    }
  }
  
  private func add(device: MyBluetoothDevice) {
    self.concurrentDevicesQueue.async(flags: .barrier, execute: { () -> Void in
      if !self._devices.contains(device) {
        self._devices.append(device)
        DispatchQueue.main.async {
          self.delegate?.didUpdateDevices(self)
        }
      }
    })
  }
  
  private func remove(device: MyBluetoothDevice) {
    self.concurrentDevicesQueue.async(flags: .barrier, execute: { () -> Void in
      if let index = self._devices.index(of: device) {
        self._devices.remove(at: index)
        DispatchQueue.main.async {
          self.delegate?.didUpdateDevices(self)
        }
      }
    })
  }
  
  // MARK: - Start / Stop Scan
  
  func startScan() {
    if !self.state.isUnsupported {
      self.delegate?.didStartScan(self)
      self.centralManager?.scanForPeripherals(withServices: nil, options: nil)
    }
  }
  
  func stopScan() {
    if !self.state.isUnsupported {
      self.centralManager?.stopScan()
    }
    self.delegate?.didStopScan(self)
  }
  
  // MARK: - CBCentralManagerDelegate
  
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    let state = self.state
    Log.log("State is now \(state.string)")
    if state.isPoweredOn {
      
      // Start the scan
      self.delegate?.didStartScan(self)
      self.centralManager?.scanForPeripherals(withServices: nil, options: nil)
      
      // Initialise timeout
      DispatchQueue.main.asyncAfter(after: 10.0) {
        self.stopScan()
      }
      
    } else if state.isUnsupported {
      self.stopScan()
    }
  }
  
  func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
    Log.log("Did discover peripheral \(peripheral) | RSSI \(RSSI) | advertisement data \(advertisementData)")
    
    let device = MyBluetoothDevice(manager: self, peripheral: peripheral, lastKnownRSSI: RSSI.intValue)
    self.add(device: device)
  }
  
  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    Log.log("Did connect to peripheral \(peripheral)")
  }
  
  func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
    Log.log("Did fail to connect to peripheral \(peripheral) with error \(error?.localizedDescription ?? "Unknown Error")")
  }
  
  func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
    Log.log("Did disconnect from peripheral \(peripheral) with error \(error?.localizedDescription ?? "Unknown Error")")
  }
}
