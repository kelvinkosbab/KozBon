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

public struct EmptyStateOverlayView: View {

    let image: Image?
    let title: String

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
