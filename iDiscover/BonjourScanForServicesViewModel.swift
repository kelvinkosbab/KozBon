//
//  BonjourScanForServicesViewModel.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 9/8/23.
//  Copyright © 2023 Kozinga. All rights reserved.
//

import Foundation

// MARK: - BonjourScanForServicesViewModel

extension BonjourScanForServicesView {
    
    class ViewModel : ObservableObject, BonjourServiceScannerDelegate {
        
        @Published var isLoading: Bool = false
        @Published var activeServices: [BonjourService] = []
        let serviceScanner = BonjourServiceScanner()
        
        var sortType: BonjourServiceSortType? {
            didSet {
                if let sortType = self.sortType {
                    self.activeServices = sortType.sorted(services: self.activeServices)
                }
            }
        }
        
        init() {
            self.serviceScanner.delegate = self
        }
        
        // MARK: - Actions
        
        func addButtonPressed() {
            print("KAK addButtonPressed")
        }
        
        func sortButtonPressed() {
            print("KAK sortButtonPressed")
        }
        
        // MARK: - BonjourServiceScannerDelegate
        
        func didAdd(service: BonjourService) {
            self.activeServices.append(service)
        }
        
        func didRemove(service: BonjourService) {
            for index in 0..<self.activeServices.count {
                self.activeServices.remove(at: index)
            }
        }
        
        func didReset() {
            self.activeServices = []
        }
    }
}
