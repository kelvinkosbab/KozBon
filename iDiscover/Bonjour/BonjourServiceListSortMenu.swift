//
//  BonjourServiceListSortMenu.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 9/14/23.
//  Copyright © 2023 Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - BonjourServiceListSortMenu

struct BonjourServiceListSortMenu: View {

    @Binding var sortType: BonjourServiceSortType?

    let sortButtonString = NSLocalizedString(
        "Sort",
        comment: "Sort services button string"
    )

    var body: some View {
        Menu {
            ForEach(BonjourServiceSortType.allCases) { sortType in
                Button(sortType.hostOrServiceTitle) {
                    self.didSelect(sortType: sortType)
                }
            }
        } label: {
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
    }

    private func didSelect(sortType: BonjourServiceSortType?) {
        self.sortType = sortType
    }
}
