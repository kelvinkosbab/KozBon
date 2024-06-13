//
//  BonjourScanForServicesView.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 8/20/23.
//  Copyright © 2023 Kozinga. All rights reserved.
//

import SwiftUI
import CoreUI

// MARK: - BonjourScanForServicesView

struct BonjourScanForServicesView: View {

    // MARK: - ViewModel

    @StateObject var viewModel = BonjourServicesViewModel()

    // MARK: - Body

    var body: some View {
        List {
            ForEach(self.viewModel.activeServices, id: \.self.service.hashValue) { service in
                TitleDetailChevronView(
                    title: service.service.name,
                    detail: service.serviceType.name
                )
            }
        }
        .overlay {
            if self.viewModel.activeServices.count == 0 {
                EmptyStateOverlayView(
                    image: nil,
                    title: self.viewModel.noActiveServicesString
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                self.renderTrailingToolbarItems()
            }
        }
        .navigationTitle(NSLocalizedString(
            "Bonjour Services",
            comment: "Bonjour Services title"
        ))
        .onAppear {
            self.viewModel.serviceScanner.startScan()
        }
        .onDisappear {
            self.viewModel.serviceScanner.stopScan()
        }
    }

    private func renderTrailingToolbarItems() -> some View {
        HStack {
            BonjourServiceListSortMenu(sortType: self.$viewModel.sortType)

            Button(action: self.addButtonPressed) {
                Label(
                    title: {
                        Text(self.viewModel.createButtonString)
                    },
                    icon: {
                        Image.plusCircleFill
                            .renderingMode(.template)
                            .foregroundColor(.kozBonBlue)
                    }
                )
            }
        }
    }

    // MARK: - Actions

    func addButtonPressed() {
        self.viewModel.addButtonPressed()
    }
}
