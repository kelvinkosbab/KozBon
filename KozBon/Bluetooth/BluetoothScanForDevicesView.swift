//
//  BluetoothScanForDevicesView.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 8/20/23.
//  Copyright © 2023 Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - BluetoothScanForDevicesView

struct BluetoothScanForDevicesView: View {

    // MARK: - ViewModel

    @StateObject var viewModel = ViewModel()

    // MARK: - Body

    var body: some View {
        List {
            ForEach(self.viewModel.devices) { device in
                if let deviceName = device.name {
                    TitleDetailStackView(
                        title: deviceName,
                        detail: "Last known RSSI: \(device.lastKnownRSSI ?? -1)"
                    )
                }
            }
        }
        .contentMarginsBasedOnSizeClass()
        .overlay {
            if self.viewModel.scannerState == .unsupported {
                EmptyStateOverlayView(
                    image: nil,
                    title: viewModel.bluetoothUnsupportedString
                )
            } else if self.viewModel.devices.count == 0 {
                EmptyStateOverlayView(
                    image: nil,
                    title: viewModel.noDevicesString
                )
            }
        }
        .navigationTitle("Nearby devices")
        .task {
            if viewModel.isInitialLoad {
                viewModel.deviceScanner.startScan()
                viewModel.isInitialLoad = false
            }

        }
        .onDisappear {
            viewModel.deviceScanner.stopScan()
        }
    }
}
