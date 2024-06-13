//
//  SidebarNavigationView.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 8/21/23.
//  Copyright © 2023 Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - SidebarNavigationView

struct SidebarNavigationView : View {
    
    @ObservedObject var dataSource: SidebarDataSource
    
    init(selectedItem: Binding<(any BarItem)?>) {
        self.dataSource = SidebarDataSource()
    }
    
    var body: some View {
        NavigationView {
            Sidebar(dataSource: self.dataSource)
            
//            if let selectedItem = self.dataSource.selectedItem, selectedItem.isSelectable {
//                selectedItem.destination
//            }
        }
    }
}

// MARK: - Sidebar

struct Sidebar : View {
    
    @ObservedObject var dataSource: SidebarDataSource
    
    var body: some View {
        List {
//            ForEach(self.dataSource.items, id: \.self.id) { item in
//                NavigationLink(destination: item.destination) {
//                    item.content
//                }
//                .onTapGesture {
//                    if item.isSelectable {
//                        self.dataSource.selectedItem = item
//                    }
//                }
//            }
            Text(verbatim: "... remove this")
        }
        .listStyle(.sidebar)
        .navigationTitle("KozBon")
    }
}

// MARK: - SidebarDataSource

class SidebarDataSource : ObservableObject {
    
//    @MainActor @Binding var selectedItem: (any BarItem)
//    
//    init(selectedItem: Binding<(any BarItem)>) {
//        self._selectedItem = selectedItem
//    }
    
//    let items: [any BarItem] = [
//        SidebarItem.bonjourScanForActiveServices,
//        SidebarItem.bonjourSupportedServices,
//        SidebarItem.bonjourCreateService,
//        SidebarItem.bluetooth,
//        SidebarItem.appInformation
//    ]
}