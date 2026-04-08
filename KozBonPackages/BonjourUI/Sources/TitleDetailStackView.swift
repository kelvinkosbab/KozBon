//
//  TitleDetailStackView.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import CoreUI

// MARK: - TitleDetailStackView

/// A list row displaying a title and detail in a vertical stack, with an optional trailing view.
///
/// Commonly used throughout the app for key-value style rows (e.g., hostname, type, IP address).
public struct TitleDetailStackView<Trailing>: View where Trailing: View {

    let title: String
    let detail: String
    let trailing: (() -> Trailing)?

    /// Creates a title-detail row with a trailing view.
    ///
    /// - Parameters:
    ///   - title: The primary text displayed in body font.
    ///   - detail: The secondary text displayed in caption font.
    ///   - trailing: A view builder for content displayed on the trailing edge.
    public init(
        title: String,
        detail: String,
        trailing: @escaping () -> Trailing
    ) {
        self.title = title
        self.detail = detail
        self.trailing = trailing
    }

    public var body: some View {
        HStack(alignment: .center) {
            VStack(
                alignment: .leading,
                spacing: Spacing.small
            ) {
                Text(self.title)
                    .font(.body)
                    .foregroundColor(.primary)
                Text(self.detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            trailing?()
        }
        .accessibilityElement(children: .combine)
        #if os(iOS) || os(visionOS)
        .hoverEffect(.highlight)
        #endif
    }
}

public extension TitleDetailStackView where Trailing == EmptyView {
    init(
        title: String,
        detail: String
    ) {
        self.title = title
        self.detail = detail
        self.trailing = nil
    }
}

// MARK: - Preview

struct BonjourServiceCardView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            TitleDetailStackView(
                title: "title",
                detail: "detail"
            )
        }
    }
}
