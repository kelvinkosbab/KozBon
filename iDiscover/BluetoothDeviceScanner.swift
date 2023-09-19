//
//  MyBluetoothManager.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 1/7/18.
//  Copyright © 2018 Kozinga. All rights reserved.
//

import Foundation
import CoreBluetooth
import Core

// MARK: - BluetoothDeviceScannerDelegate

protocol BluetoothDeviceScannerDelegate : AnyObject {
    func didAdd(device: BluetoothDevice)
    func didRemove(device: BluetoothDevice)
    func didUpdate(state: CBManagerState)
}

// MARK: - BluetoothDeviceScanner

class BluetoothDeviceScanner : NSObject, CBCentralManagerDelegate {
    
    weak var delegate: BluetoothDeviceScannerDelegate?
    private let centralManager: CBCentralManager
    private(set) var state: CBManagerState
    private(set) var devices: Set<BluetoothDevice> = Set<BluetoothDevice>()
    private let logger = SubsystemCategoryLogger(
        subsystem: "KozBon",
        category: "BluetoothDeviceScanner"
    )
    
    override init() {
        let manager = CBCentralManager()
        self.centralManager = manager
        self.state = manager.state
        super.init()
        self.centralManager.delegate = self
    }
    
    // MARK: - Devices
    
    private func clearDevices() {
        for device in self.devices {
            self.remove(device: device)
        }
    }
    
    private func add(device: BluetoothDevice) {
        let contains = self.devices.contains { $0.uuid == device.uuid }
        if !contains, let deviceName = device.name, !deviceName.isEmpty {
            self.devices.insert(device)
            self.delegate?.didAdd(device: device)
        }
    }
    
    private func remove(device: BluetoothDevice) {
        if self.devices.contains(device) {
            self.devices.remove(device)
            self.delegate?.didRemove(device: device)
        }
    }
    
    private func fetchDevice(peripheral: CBPeripheral) -> BluetoothDevice? {
        return self.devices.first { $0.peripheral == peripheral }
    }
    
    // MARK: - Start / Stop Scan
    
    func startScan() {
        if self.state != .unsupported {
            self.centralManager.delegate = self
            if self.centralManager.state == .poweredOn {
                self.centralManager.scanForPeripherals(withServices: nil, options: nil)
            }
        }
    }
    
    func stopScan() {
        if self.state != .unsupported {
            self.centralManager.stopScan()
        }
    }
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        self.logger.debug("State is now \(central.state.string)")
        self.state = central.state
        self.delegate?.didUpdate(state: central.state)
    }
    
    func centralManager(
        _ central: CBCentralManager, 
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String : Any],
        rssi RSSI: NSNumber
    ) {
        self.logger.info("Did discover peripheral \(peripheral) | RSSI \(RSSI) | advertisement data \(advertisementData)")
        
        let device = BluetoothDevice(peripheral: peripheral, lastKnownRSSI: RSSI.intValue)
        self.add(device: device)
    }
    
    // MARK: - Connecting to Devices
    
    func connect(
        device: BluetoothDevice, 
        options: [String : Any]? = nil,
        completion: @escaping (_ error: Error?) -> Void
    ) {
        device.connectCompletion = completion
        self.centralManager.connect(device.peripheral, options: options)
    }
    
    func connectAndConfigure(
        device: BluetoothDevice,
        completion: @escaping (_ error: Error?) -> Void
    ) {
        self.connect(device: device) { error in
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
    
    func disconnect(
        device: BluetoothDevice,
        completion: @escaping (_ error: Error?) -> Void
    ) {
        device.connectCompletion = completion
        self.centralManager.cancelPeripheralConnection(device.peripheral)
    }
    
    func disconnectFromAllDevices(completion: (() -> Void)? = nil) {
        let dispatchGroup = DispatchGroup()
        for device in self.devices {
            dispatchGroup.enter()
            self.disconnect(device: device) { _ in
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion?()
        }
    }
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        self.logger.info("Did connect to peripheral \(peripheral.name ?? "nil")")
        
        let device = self.fetchDevice(peripheral: peripheral)
        device?.connectCompletion?(nil)
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        self.logger.info("Did fail to connect to peripheral \(peripheral.name ?? "nil") with error \(error?.localizedDescription ?? "Unknown Error")")
        
        let device = self.fetchDevice(peripheral: peripheral)
        device?.connectCompletion?(error)
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        self.logger.info("Did disconnect from peripheral \(peripheral.name ?? "nil") with error \(error?.localizedDescription ?? "Unknown Error")")
        
        let device = self.fetchDevice(peripheral: peripheral)
        device?.connectCompletion?(error)
    }
}
