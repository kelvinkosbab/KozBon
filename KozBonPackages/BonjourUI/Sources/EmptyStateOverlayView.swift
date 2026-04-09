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

/// A centered overlay view for empty states, displaying an optional image, title, and action button.
///
/// - Parameters:
///   - image: An optional decorative image shown above the title.
///   - title: The primary message describing the empty state.
///   - actionTitle: Optional title for an action button shown below the title.
///   - action: Optional closure invoked when the action button is tapped.
public struct EmptyStateOverlayView: View {

    let image: Image?
    let title: String
    let actionTitle: String?
    let action: (() -> Void)?

    public init(
        image: Image? = nil,
        title: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.image = image
        self.title = title
        self.actionTitle = actionTitle
        self.action = action
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

            if let actionTitle, let action {
                Button {
                    action()
                } label: {
                    Text(actionTitle)
                }
                .buttonStyle(.borderedProminent)
                .tint(.kozBonBlue)
            }
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
            title: "Some title saying something",
            actionTitle: "Start Scanning",
            action: {}
        )
    }
}
