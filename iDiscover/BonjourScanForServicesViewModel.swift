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
        
        @Published var sortType: BonjourServiceSortType? {
            didSet {
                if let sortType = self.sortType {
                    self.sort(sortType: sortType)
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
