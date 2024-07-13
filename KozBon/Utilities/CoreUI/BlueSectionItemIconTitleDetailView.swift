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

    let imageSystemName: String?
    let title: String
    let detail: String?

    init(
        imageSystemName: String?,
        title: String,
        detail: String?
    ) {
        self.imageSystemName = imageSystemName
        self.title = title
        self.detail = detail
    }

    var body: some View {
        HStack(spacing: 10) {
            if let imageSystemName, !imageSystemName.isEmpty {
                Image(systemName: imageSystemName)
                    .font(.system(.title3).bold())
            }

            VStack(alignment: .leading) {
                Text(verbatim: title)
                    .font(.system(.headline).bold())

                if let detail {
                    Text(verbatim: detail)
                        .font(.system(.caption).bold())
                }
            }
            Spacer()
        }
        .padding(.vertical, 10)
        .listRowBackground(
            Color.kozBonBlue
                .opacity(0.4)
                .clipShape(.capsule)
        )
    }
}

extension BlueSectionItemIconTitleDetailView {
    init(
        imageSystemName: String,
        title: String
    ) {
        self.init(
            imageSystemName: imageSystemName,
            title: title,
            detail: nil
        )
    }

    init(
        title: String,
        detail: String
    ) {
        self.init(
            imageSystemName: nil,
            title: title,
            detail: detail
        )
    }

    init(title: String) {
        self.init(
            imageSystemName: nil,
            title: title,
            detail: nil
        )
    }
}
