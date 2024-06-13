//
//  BarItemLabel.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 8/21/23.
//  Copyright © 2023 Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - BarItemLabel

struct BarItemLabel: View {

    let item: any BarItem

    var body: some View {
        Label(
            title: {
                Text(self.item.titleString)
            },
            icon: {
                self.item.icon
                    .renderingMode(.template)
            }
        )
    }
}
