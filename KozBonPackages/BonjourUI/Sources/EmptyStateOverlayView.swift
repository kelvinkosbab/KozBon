//
//  EmptyStateOverlayView.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourCore
import CoreUI

// MARK: - EmptyStateOverlayView

/// An overlay view shown when a list has no content, displaying an optional image and a title message.
public struct EmptyStateOverlayView: View {

    let image: Image?
    let title: String

    /// Creates an empty state overlay.
    ///
    /// - Parameters:
    ///   - image: An optional image displayed above the title, or `nil` to show text only.
    ///   - title: The message explaining why the list is empty.
    public init(
        image: Image?,
        title: String
    ) {
        self.image = image
        self.title = title
    }

    public var body: some View {
        VStack(spacing: Spacing.base) {
            if let image {
                image
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(.secondary)
                    .frame(width: 100, height: 100)
                    .accessibilityHidden(true)
            }
            Text(self.title)
                .font(.headline).bold()
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Preview

struct EmptyStateOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyStateOverlayView(
            image: nil,
            title: "Some title saying something"
        )

        EmptyStateOverlayView(
            image: Image(systemName: Iconography.antenna),
            title: "Some title saying something"
        )
    }
}
