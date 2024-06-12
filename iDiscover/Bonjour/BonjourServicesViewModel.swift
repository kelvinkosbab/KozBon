//
//  BonjourScanForServicesViewModel.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 9/8/23.
//  Copyright © 2023 Kozinga. All rights reserved.
//

import Foundation

// MARK: - BonjourServicesViewModel

class BonjourServicesViewModel : ObservableObject, BonjourServiceScannerDelegate {
    
    @MainActor @Published var activeServices: [BonjourService] = []
    
    @MainActor @Published var sortType: BonjourServiceSortType? {
        didSet {
            if let sortType = self.sortType {
                self.sort(sortType: sortType)
            }
        }
    }
    
    let serviceScanner = BonjourServiceScanner()
    
    init() {
        self.serviceScanner.delegate = self
    }
    
    // MARK: - Strings
    
    let createButtonString = NSLocalizedString(
        "Create",
        comment: "Create service button string"
    )
    
    let noActiveServicesString = NSLocalizedString(
        "No active Bonjour services",
        comment: "No active Bonjour services string"
    )
    
    // MARK: - Actions
    
    func addButtonPressed() {
        print("KAK addButtonPressed")
    }
    
    @MainActor
    func sort(sortType: BonjourServiceSortType) {
        switch sortType {
        case .hostNameAsc:
            self.activeServices = self.activeServices.sorted { service1, service2 -> Bool in
                return service1.service.name < service2.service.name
            }
        
        case .hostNameDesc:
            self.activeServices = self.activeServices.sorted { service1, service2 -> Bool in
            return service1.service.name > service2.service.name
        }
        
        case .serviceNameAsc:
            self.activeServices = self.activeServices.sorted { service1, service2 -> Bool in
            return service1.serviceType.name < service2.serviceType.name
        }
        
        case .serviceNameDesc:
            self.activeServices = self.activeServices.sorted { service1, service2 -> Bool in
                return service1.serviceType.name > service2.serviceType.name
            }
        }
    }
    
    // MARK: - BonjourServiceScannerDelegate
    
    func didAdd(service: BonjourService) {
        Task {
            await MainActor.run {
                self.activeServices.append(service)
            }
        }
    }
    
    func didRemove(service: BonjourService) {
        Task {
            await MainActor.run {
                for index in 0..<self.activeServices.count {
                    self.activeServices.remove(at: index)
                }
            }
        }
    }
    
    func didReset() {
        Task {
            await MainActor.run {
                self.activeServices = []
            }
        }
    }
}
