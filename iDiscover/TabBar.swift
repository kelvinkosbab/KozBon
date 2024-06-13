//
//  CoreTabBar.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 6/12/24.
//  Copyright © 2024 Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - TabBar

struct TabBar: View {

    @StateObject var viewModel: ViewModel

    init(selectedDestination: Binding<TopLevelDestination>) {
        self._viewModel = StateObject(wrappedValue: ViewModel(selectedDestination: selectedDestination))
    }

    var body: some View {
        TabView {
            ForEach(viewModel.destinations) { item in
                NavigationView {
                    switch viewModel.selectedDestination {
                    case .bonjourScanForActiveServices:
                        BonjourScanForServicesView()

                    case .bonjourSupportedServices:
                        Text(viewModel.selectedDestination.titleString)

                    case .bonjourCreateService:
                        Text(viewModel.selectedDestination.titleString)

                    case .bluetooth:
                        Text(viewModel.selectedDestination.titleString)

                    case .appInformation:
                        Text(viewModel.selectedDestination.titleString)
                    }
                }
                .tabItem {
                    Label {
                        Text(verbatim: item.titleString)
                    } icon: {
                        item.icon
                    }
                }
//                    .onTapGesture {
//                        if item.isSelectable {
//                            self.dataSource.selectedItem = item
//                        }
//                    }
            }
        }
    }

    // MARK: - ViewModel

    class ViewModel: ObservableObject {

        @MainActor @Binding var selectedDestination: TopLevelDestination

        init(selectedDestination: Binding<TopLevelDestination>) {
            self._selectedDestination = selectedDestination
        }

        let destinations: [TopLevelDestination] = [
            .bonjourScanForActiveServices,
            .bluetooth,
            .appInformation
        ]
    }
}
