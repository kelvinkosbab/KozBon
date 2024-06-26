//
//  BlueSectionItemIconTitleDetailView.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 6/26/24.
//  Copyright © 2024 Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - BlueSectionItemIconTitleDetailView

struct BlueSectionItemIconTitleDetailView: View {
    
    let imageSystemName: String
    let title: String
    let detail: String
    
    init(
        imageSystemName: String,
        title: String,
        detail: String
    ) {
        self.imageSystemName = imageSystemName
        self.title = title
        self.detail = detail
    }
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: imageSystemName)
                .font(.system(.title3).bold())

            VStack(alignment: .leading) {
                Text(verbatim: title)
                    .font(.system(.headline).bold())

                Text(verbatim: detail)
                    .font(.system(.caption).bold())
            }
            Spacer()
        }
        .padding(.vertical, 10)
        .listRowBackground(
            Color.kozBonBlue
                .opacity(0.4)
        )
    }
}
