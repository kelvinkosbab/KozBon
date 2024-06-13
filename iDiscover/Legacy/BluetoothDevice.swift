//
//  BluetoothDevice.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 1/7/18.
//  Copyright © 2018 Kozinga. All rights reserved.
//

import Foundation
import CoreBluetooth
import Core

// MARK: - BluetoothDeviceDelegate

protocol BluetoothDeviceDelegate: AnyObject {
    func didUpdate(_ device: BluetoothDevice)
}

// MARK: - BluetoothDeviceServicesDelegate

protocol BluetoothDeviceServicesDelegate: AnyObject {
    func didUpdateServices(_ device: BluetoothDevice)
}

// MARK: - BluetoothDevice

class BluetoothDevice: NSObject, CBPeripheralDelegate {

    // MARK: - Equatable

    static func ==(lhs: BluetoothDevice, rhs: BluetoothDevice) -> Bool {
        return lhs.uuid == rhs.uuid
    }

    // MARK: - Properties and Init

    let peripheral: CBPeripheral
    let uuid: UUID

    weak var delegate: BluetoothDeviceDelegate?
    weak var servicesDelegate: BluetoothDeviceServicesDelegate?
    var connectCompletion: ((_ error: Error?) -> Void)?
    private let logger: Loggable = Logger(category: "BluetoothDevice")

    var name: String? {
        return self.peripheral.name
    }

    var state: CBPeripheralState {
        return self.peripheral.state
    }

    init(
        peripheral: CBPeripheral,
        lastKnownRSSI rssi: Int?
    ) {
        self.peripheral = peripheral
        self.uuid = peripheral.identifier
        self.lastKnownRSSI = rssi
        super.init()
        peripheral.delegate = self
    }

    // MARK: - RSSI

    var lastKnownRSSI: Int? {
        didSet {
            if self.lastKnownRSSI != oldValue {
                self.delegate?.didUpdate(self)
            }
        }
    }

    private var readRSSICompletion: ((_ RSSI: Int) -> Void)?

    func readRSSI(completion: ((_ RSSI: Int) -> Void)? = nil) {
        self.readRSSICompletion = completion
        self.peripheral.readRSSI()
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didReadRSSI RSSI: NSNumber,
        error: Error?
    ) {
        self.logger.info("Did read RSSI \(self.name ?? "Unknown Name")")

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

    private var discoverServicesCompletion: (() -> Void)?

    func discoverServices(serviceUUIDs: [CBUUID]? = nil, completion: (() -> Void)? = nil) {
        self.discoverServicesCompletion = completion
        self.peripheral.discoverServices(serviceUUIDs)
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverServices error: Error?
    ) {
        self.logger.info("Did discover services for bluetooth peripheral", censored: uuid.uuidString)

        self.discoverServicesCompletion?()
        self.discoverServicesCompletion = nil
        self.servicesDelegate?.didUpdateServices(self)
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didModifyServices invalidatedServices: [CBService]
    ) {
        self.logger.info("Did modify services for bluetooth peripheral", censored: uuid.uuidString)

        self.servicesDelegate?.didUpdateServices(self)
    }

    // MARK: - Characteristics

    private var characteristicDiscoveryHandler: (() -> Void)?
    private var servicesToDiscoverCharacteristics: Set<CBService> = Set<CBService>()

    func discoverCharacteristics(characteristicUUIDs: [CBUUID]? = nil, completion: @escaping () -> Void) {
        self.characteristicDiscoveryHandler = completion
        self.servicesToDiscoverCharacteristics = Set(self.services)
        for service in self.services {
            self.peripheral.discoverCharacteristics(characteristicUUIDs, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        self.logger.info("Did discover \(service.characteristics?.count ?? 0) characteristics for service \(service)", censored: uuid.uuidString)

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

    private var descriptorDiscoveryHandler: (() -> Void)?
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
        self.logger.info("Did discover \(characteristic.descriptors?.count ?? 0) descriptors for characteristic \(characteristic)", censored: uuid.uuidString)

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

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        self.logger.info("Did update value for characteristic", censored: uuid.uuidString)
    }
}

// MARK: - Identifiable

extension BluetoothDevice: Identifiable {
    var id: UUID {
        uuid
    }
}

// MARK: - Sequence

extension Sequence where Iterator.Element: BluetoothDevice {

    var nameSorted: [BluetoothDevice] {
        return self.sorted { (device1, device2) -> Bool in
            return device1.name ?? "" < device2.name ?? ""
        }
    }
}
