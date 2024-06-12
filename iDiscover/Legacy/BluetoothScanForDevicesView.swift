//
//  BluetoothScanForDevicesView.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 8/20/23.
//  Copyright © 2023 Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - BluetoothScanForDevicesView

struct BluetoothScanForDevicesView : View {
    
    // MARK: - ViewModel
    
    @StateObject var viewModel = ViewModel()
    
    // MARK: - Body
    
    var body: some View {
        List {
            ForEach(self.viewModel.devices, id: \.self.uuid) { device in
                if let deviceName = device.name {
                    TitleDetailChevronView(
                        title: deviceName,
                        detail: "Last known RSSI: \(device.lastKnownRSSI ?? -1)"
                    )
                }
            }
        }
        .overlay {
            if self.viewModel.scannerState == .unsupported {
                EmptyStateOverlayView(
                    image: nil,
                    title: self.viewModel.bluetoothUnsupportedString
                )
            } else if self.viewModel.devices.count == 0 {
                EmptyStateOverlayView(
                    image: nil,
                    title: self.viewModel.noDevicesString
                )
            }
        }
        .navigationTitle(NSLocalizedString(
            "Bluetooth Devices",
            comment: "Bluetooth Devices title"
        ))
        .onAppear {
            self.viewModel.deviceScanner.startScan()
        }
        .onDisappear {
            self.viewModel.deviceScanner.stopScan()
        }
    }
}
