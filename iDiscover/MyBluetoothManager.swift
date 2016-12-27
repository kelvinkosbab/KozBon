//
//  MyBluetoothManager.swift
//  iDiscover
//
//  Created by Kelvin Kosbab on 12/26/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation
import CoreBluetooth

class MyBluetoothManager: NSObject, CBCentralManagerDelegate {
  
  // MARK: - Singleton
  
  static let shared = MyBluetoothManager()
  
  private override init() {
    self.centralManager = CBCentralManager(delegate: nil, queue: self.centralManagerDispatchQueue)
    super.init()
    self.centralManager.delegate = self
  }
  
  // MARK: - Properties
  
  var completion: ((_ services: [MyBluetoothDevice]) -> Void)? = nil
  var didStartSearch: (() -> Void)? = nil
  
  private let centralManager: CBCentralManager
  private let centralManagerDispatchQueue: DispatchQueue = DispatchQueue(label: "\(MyBluetoothManager.name).centralManagerQueue")
  private let concurrentDevicesQueue: DispatchQueue = DispatchQueue(label: "\(MyBluetoothManager.name).concurrentDevicesQueue", attributes: .concurrent)
  
  // MARK: - Devices
  
  private var _devices: [MyBluetoothDevice] = []
  
  private var devices: [MyBluetoothDevice] {
    var copy: [MyBluetoothDevice]!
    self.concurrentDevicesQueue.sync {
      copy = self._devices
    }
    return copy
  }
  
  private func clearDevices() {
    self.concurrentDevicesQueue.async(flags: .barrier, execute: { () -> Void in
      self._devices = []
    })
  }
  
  private func add(device: MyBluetoothDevice) {
    self.concurrentDevicesQueue.async(flags: .barrier, execute: { () -> Void in
      if !self._devices.contains(device) {
        self._devices.append(device)
      }
    })
  }
  
  private func remove(device: MyBluetoothDevice) {
    self.concurrentDevicesQueue.async(flags: .barrier, execute: { () -> Void in
      if let index = self._devices.index(of: device) {
        self._devices.remove(at: index)
      }
    })
  }
  
  // MARK: - Start / Stop Scan
  
  func startScan(completion: @escaping (_ devices: [MyBluetoothDevice]) -> Void, didStartSearch: (() -> Void)? = nil) {
    self.stopScan()
    self.clearDevices()
    self.completion = completion
    self.didStartSearch = didStartSearch
    
    // Start the scan
    self.centralManager.scanForPeripherals(withServices: nil, options: nil)
    
    // Initialise timeout
    DispatchQueue.main.asyncAfter(after: 10.0) { 
      self.stopScan()
      self.completion?(self.devices)
    }
  }
  
  func stopScan() {
    self.centralManager.stopScan()
  }
  
  // MARK: - CBCentralManagerDelegate
  
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    print("\(self.className) : State is now \(central.state)")
    if central.state == .poweredOn {
      self.didStartSearch?()
    }
  }
  
  func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
    print("\(self.className) : Will restore state \(dict)")
  }
  
  func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
    print("\(self.className) : Did discover peripheral \(peripheral) wih RSSI \(RSSI)")
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
