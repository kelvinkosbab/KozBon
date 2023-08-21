//
//  TabBar.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 8/21/23.
//  Copyright © 2023 Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - TabBar

struct TabBar : View {
    
    @ObservedObject var dataSource: DataSource
    
    init(selectedItem: Binding<(any BarItem)?>) {
        self.dataSource = DataSource(selectedItem: selectedItem)
    }
    
    var body: some View {
        TabView {
            ForEach(self.dataSource.items, id: \.self.id) { item in
                NavigationView { item.destination }
                    .tabItem {
                        item.content
                            .foregroundColor(.kozBonBlue)
                    }
                    .onTapGesture {
                        self.dataSource.selectedItem = item
                    }
            }
        }
        .accentColor(.kozBonBlue)
    }
    
    // MARK: - DataSource
    
    class DataSource : ObservableObject {
        
        @Binding var selectedItem: (any BarItem)?
        
        init(selectedItem: Binding<(any BarItem)?>) {
            self._selectedItem = selectedItem
        }
        
        let items: [any BarItem] = [
            TabBarItem.bonjour,
            TabBarItem.bluetooth,
            TabBarItem.information
        ]
    }
}
