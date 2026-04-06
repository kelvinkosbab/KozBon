//
//  BlueSectionItemIconTitleDetailView.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - BlueSectionItemIconTitleDetailView

public struct BlueSectionItemIconTitleDetailView: View {

    let imageSystemName: String?
    let title: String
    let detail: String?

    public init(
        imageSystemName: String?,
        title: String,
        detail: String?
    ) {
        self.imageSystemName = imageSystemName
        self.title = title
        self.detail = detail
    }

    public var body: some View {
        HStack(spacing: 10) {
            if let imageSystemName, !imageSystemName.isEmpty {
                Image(systemName: imageSystemName)
                    .font(.title3).bold()
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading) {
                Text(verbatim: title)
                    .font(.headline).bold()

                if let detail {
                    Text(verbatim: detail)
                        .font(.caption).bold()
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

public extension BlueSectionItemIconTitleDetailView {
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
