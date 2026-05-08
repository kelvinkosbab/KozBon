//
//  BlueSectionItemIconTitleDetailView.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - BlueSectionItemIconTitleDetailView

/// A prominent list row with an SF Symbol icon, title, and optional detail text
/// displayed on a tinted capsule background.
///
/// Used as a hero header in detail views to identify a service or service type.
public struct BlueSectionItemIconTitleDetailView: View {

    @ScaledMetric private var iconSize: CGFloat = 20
    @ScaledMetric private var horizontalSpacing: CGFloat = 10
    @ScaledMetric private var verticalSpacing: CGFloat = 4

    let imageSystemName: String?
    let title: String
    let detail: String?

    /// Creates a header row with an optional icon, title, and optional detail.
    ///
    /// - Parameters:
    ///   - imageSystemName: The SF Symbol name for the icon, or `nil` to omit.
    ///   - title: The primary text.
    ///   - detail: The secondary text displayed below the title, or `nil` to omit.
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
        HStack(spacing: horizontalSpacing) {
            if let imageSystemName, !imageSystemName.isEmpty {
                Image(systemName: imageSystemName)
                    .font(.system(size: iconSize, weight: .bold))
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: verticalSpacing) {
                Text(verbatim: title)
                    .font(.headline).bold()
                    .foregroundStyle(.white)

                if let detail {
                    Text(verbatim: detail)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(detail.map { "\(title), \($0)" } ?? title)
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
        .listRowBackground(
            Color.kozBonBlue
                .clipShape(.capsule)
        )
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
