//
//  BlueSectionItemIconTitleDetailView.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - BlueSectionItemIconTitleDetailView

/// A prominent list row with an SF Symbol icon, title, and optional detail text
/// displayed on a blue-washed material capsule.
///
/// Used as a hero header in detail views to identify a service or service type.
/// An optional accessory (such as an Insights link) sits below the detail text
/// and stays a separate accessibility element from the title and detail.
/// The row sits in the content layer over the ambient mesh, so it uses a
/// standard material rather than Liquid Glass (which the HIG reserves for
/// controls and navigation) — and primary/secondary text instead of white,
/// which stays legible whatever the wash behind it is doing.
public struct BlueSectionItemIconTitleDetailView<Accessory: View>: View {

    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    @ScaledMetric private var iconSize: CGFloat = 20
    @ScaledMetric private var horizontalSpacing: CGFloat = 10
    @ScaledMetric private var verticalSpacing: CGFloat = 4

    let imageSystemName: String?
    let title: String
    let detail: String?
    let accessory: Accessory

    /// Creates a header row with an optional icon, title, optional detail, and an accessory.
    ///
    /// - Parameters:
    ///   - imageSystemName: The SF Symbol name for the icon, or `nil` to omit.
    ///   - title: The primary text.
    ///   - detail: The secondary text displayed below the title, or `nil` to omit.
    ///   - accessory: A view shown below the detail text, such as a link.
    public init(
        imageSystemName: String?,
        title: String,
        detail: String?,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.imageSystemName = imageSystemName
        self.title = title
        self.detail = detail
        self.accessory = accessory()
    }

    public var body: some View {
        HStack(spacing: horizontalSpacing) {
            if let imageSystemName, !imageSystemName.isEmpty {
                Image(systemName: imageSystemName)
                    .font(.system(size: iconSize, weight: .bold))
                    .foregroundStyle(Color.kozBonBlue)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: verticalSpacing) {
                VStack(alignment: .leading, spacing: verticalSpacing) {
                    Text(verbatim: title)
                        .font(.headline).bold()
                        .foregroundStyle(.primary)

                    if let detail {
                        Text(verbatim: detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(detail.map { "\(title), \($0)" } ?? title)

                accessory
            }
            Spacer()
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
        .listRowBackground(
            Capsule()
                .fill(.regularMaterial)
                .overlay(Capsule().fill(Color.kozBonBlue.opacity(0.15)))
                .overlay(
                    Capsule().strokeBorder(
                        Color.kozBonBlue.opacity(colorSchemeContrast == .increased ? 0.8 : 0.35),
                        lineWidth: colorSchemeContrast == .increased ? 1.5 : 0.5
                    )
                )
        )
    }
}

public extension BlueSectionItemIconTitleDetailView where Accessory == EmptyView {
    /// Creates a header row with an optional icon, title, and optional detail.
    ///
    /// - Parameters:
    ///   - imageSystemName: The SF Symbol name for the icon, or `nil` to omit.
    ///   - title: The primary text.
    ///   - detail: The secondary text displayed below the title, or `nil` to omit.
    init(
        imageSystemName: String?,
        title: String,
        detail: String?
    ) {
        self.init(
            imageSystemName: imageSystemName,
            title: title,
            detail: detail,
            accessory: { EmptyView() }
        )
    }

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
