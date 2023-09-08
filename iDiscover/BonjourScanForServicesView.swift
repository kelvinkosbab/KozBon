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
    
    let sortButtonString = NSLocalizedString(
        "Sort",
        comment: "Sort services button string"
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
                    Text("Hi")
                }
            }
        }
        .navigationTitle(NSLocalizedString(
            "Bonjour Services",
            comment: "Bonjour Services title"
        ))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                self.renderLeadingToolbarItems()
            }
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
    
    private func renderLeadingToolbarItems() -> some View {
        HStack {
//            if self.viewModel.isLoading {
                Button(action: {}) {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
                .disabled(true)
//            } else {
//                Button(action: self.reloadButtonPressed) {
//                    Label(
//                        title: {
//                            Text(self.reloadButtonString)
//                        },
//                        icon: {
//                            Image.arrowClockwiseCircleFill
//                                .renderingMode(.template)
//                                .foregroundColor(.kozBonBlue)
//                        }
//                    )
//                }
//            }
        }
    }
    
    private func renderTrailingToolbarItems() -> some View {
        HStack {
            Button(action: self.sortButtonPressed) {
                Label(
                    title: {
                        Text(self.sortButtonString)
                    },
                    icon: {
                        Image.arrowUpArrowDownCircleFill
                            .renderingMode(.template)
                            .foregroundColor(.kozBonBlue)
                    }
                )
            }
            
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
    
    func sortButtonPressed() {
        self.viewModel.sortButtonPressed()
    }
}
