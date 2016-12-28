//
//  MyBluetoothManager.swift
//  iDiscover
//
//  Created by Kelvin Kosbab on 12/26/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation
import CoreBluetooth

enum MyBluetoothManagerState {
  case poweredOff, poweredOn, resetting, unauthorized, unknown, unsupported
  
  static func convert(cbMManagerState state: CBManagerState) -> MyBluetoothManagerState {
    switch state {
    case .poweredOff: return .poweredOff
      case .poweredOn: return .poweredOn
      case .resetting: return .resetting
      case .unauthorized: return .unauthorized
      case .unknown: return .unknown
      case .unsupported: return .unsupported
    }
  }
  
  var string: String {
    switch self {
    case .poweredOff: return "Powered Off"
    case .poweredOn: return "Powered On"
    case .resetting: return "Resetting"
    case .unauthorized: return "Unauthorized"
    case .unknown: return "Unknown"
    case .unsupported: return "Unsupported"
    }
  }
  
  var isPoweredOn: Bool {
    return self == .poweredOn
  }
}

extension CBCentralManager {
  
  var bluetoothManagerState: MyBluetoothManagerState {
    return MyBluetoothManagerState.convert(cbMManagerState: self.state)
  }
}

class MyBluetoothManager: NSObject, CBCentralManagerDelegate {
  
  // MARK: - Singleton
  
  static let shared = MyBluetoothManager()
  
  private override init() { super.init() }
  
  // MARK: - Properties
  
  var completion: ((_ services: [MyBluetoothDevice]) -> Void)? = nil
  var didStartSearch: (() -> Void)? = nil
  
  private var centralManager: CBCentralManager? = nil
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
    self.centralManager = CBCentralManager(delegate: self, queue: self.centralManagerDispatchQueue)
  }
  
  func stopScan() {
    self.centralManager?.stopScan()
    self.centralManager = nil
  }
  
  // MARK: - CBCentralManagerDelegate
  
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    let state = central.bluetoothManagerState
    print("\(self.className) : State is now \(state.string)")
    if state.isPoweredOn {
      self.didStartSearch?()
      
      // Start the scan
      self.centralManager?.scanForPeripherals(withServices: nil, options: nil)
      
      // Initialise timeout
      DispatchQueue.main.asyncAfter(after: 10.0) {
        self.stopScan()
        self.completion?(self.devices)
      }
    }
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
