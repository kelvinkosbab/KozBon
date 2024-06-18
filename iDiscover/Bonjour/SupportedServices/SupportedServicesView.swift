//
//  SupportedServicesView.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 6/18/24.
//  Copyright © 2024 Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - SupportedServicesView

struct SupportedServicesView: View {
    
    @StateObject private var viewModel = ViewModel()
    
    var body: some View {
        List {
            ForEach(viewModel.filteredServiceTypes, id: \.fullType) { serviceType in
                NavigationLink {
                    Text("\(serviceType.name) (\(serviceType.fullType))")
                } label: {
                    TitleDetailStackView(
                        title: serviceType.name,
                        detail: serviceType.fullType
                    ) {
                        Image(systemName: serviceType.imageSystemName)
                            .font(.system(.body).bold())
                    }
                }
            }
        }
        .navigationTitle("Supported services")
        .task {
            if viewModel.isInitialLoad {
                await viewModel.load()
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search for ...")
    }
    
    // MARK: - ViewModel
    
    class ViewModel: ObservableObject {
        
        @MainActor @Published private var serviceTypes: [BonjourServiceType] = []
        @MainActor @Published var searchText: String = ""
        
        @MainActor var filteredServiceTypes: [BonjourServiceType] {
            if searchText.isEmpty {
                serviceTypes
            } else {
                serviceTypes.filter { serviceType in
                    let isInName = serviceType.name.containsIgnoreCase(searchText)
                    let isInType = serviceType.fullType.containsIgnoreCase(searchText)
                    var isInDetail = false
                    if let detail = serviceType.detail {
                        isInDetail = detail.containsIgnoreCase(searchText)
                    }
                    return isInName || isInType || isInDetail
                }
            }
        }
        
        private(set) var isInitialLoad = true
        
        func load() async {
            let sortedServiceTypes = BonjourServiceType.fetchAll().sorted { lhs, rhs -> Bool in
                lhs.name < rhs.name
            }
            
            await MainActor.run {
                self.serviceTypes = sortedServiceTypes
            }
            
            self.isInitialLoad = false
        }
    }
}
