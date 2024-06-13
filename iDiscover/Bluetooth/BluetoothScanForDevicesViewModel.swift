//
//  BluetoothScanForDevicesViewModel.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 9/14/23.
//  Copyright © 2023 Kozinga. All rights reserved.
//

import Foundation
import CoreBluetooth
import SwiftUI

// MARK: - BluetoothScanForDevicesViewModel

extension BluetoothScanForDevicesView {

    class ViewModel: ObservableObject, BluetoothDeviceScannerDelegate {

        @MainActor @Published var devices: [BluetoothDevice] = []
        @MainActor @Published var scannerState: CBManagerState = .unknown

        let deviceScanner: BluetoothDeviceScanner
        var isInitialLoad = true

        init() {
            self.deviceScanner = BluetoothDeviceScanner()
            self.deviceScanner.delegate = self
        }

        // MARK: - Strings

        let noDevicesString = NSLocalizedString(
            "No Bluetooth devices found",
            comment: "No Bluetooth devices found string"
        )

        let bluetoothUnsupportedString = NSLocalizedString(
            "Bluetooth is unsupported on this device",
            comment: "Bluetooth unsupported string"
        )

        // MARK: - BluetoothDeviceScannerDelegate

        func didAdd(device: BluetoothDevice) {
            Task { @MainActor in
                withAnimation {
                    if let index = self.devices.firstIndex(of: device) {
                        self.devices[index] = device
                    } else {
                        self.devices.append(device)
                    }
                }
            }
        }

        func didRemove(device: BluetoothDevice) {
            Task { @MainActor in
                withAnimation {
                    if let index = self.devices.firstIndex(of: device) {
                        self.devices.remove(at: index)
                    }
                }
            }
        }

        func didUpdate(state: CBManagerState) {
            Task { @MainActor in
                withAnimation {
                    scannerState = state
                }
            }
        }
    }
}
