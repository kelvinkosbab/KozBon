//
//  BlueSectionItemIconTitleDetailView.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
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
                    .accessibilityHidden(true)
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
        .accessibilityElement(children: .combine)
        .padding(.vertical, 10)
        #if os(visionOS)
        .listRowBackground(
            EmptyView()
                .glassBackgroundEffect()
                .clipShape(.capsule)
        )
        #else
        .listRowBackground(
            Color.kozBonBlue
                .opacity(0.4)
                .clipShape(.capsule)
        )
        #endif
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
