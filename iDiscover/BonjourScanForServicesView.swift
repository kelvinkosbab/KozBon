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

struct BonjourScanForServicesView : View {
    
    @StateObject var viewModel = ViewModel()
    
    // MARK: - Strings
    
    let createButtonString = NSLocalizedString(
        "Create",
        comment: "Create service button string"
    )
    
    let reloadButtonString = NSLocalizedString(
        "Reload",
        comment: "Reload services button string"
    )
    
    
    
    let noActiveServicesString = NSLocalizedString(
        "No active Bonjour services",
        comment: "No active Bonjour services string"
    )
    
    // MARK: - Body
    
    var body: some View {
        List {
            if self.viewModel.activeServices.count == 0 {
                Text(self.noActiveServicesString)
                    .headingStyle()
            } else {
                ForEach(self.viewModel.activeServices, id: \.self.service.hashValue) { service in
                    TitleDetailChevronView(
                        title: service.service.name,
                        detail: service.serviceType.name
                    )
                }
            }
        }
        .navigationTitle(NSLocalizedString(
            "Bonjour Services",
            comment: "Bonjour Services title"
        ))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                self.renderTrailingToolbarItems()
            }
        }
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
                        Text(self.createButtonString)
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
