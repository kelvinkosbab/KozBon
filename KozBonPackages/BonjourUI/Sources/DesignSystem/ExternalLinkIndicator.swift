//
//  ExternalLinkIndicator.swift
//  BonjourUI
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI

// MARK: - ExternalLinkIndicator

/// The trailing glyph on a row that leaves KozBon for another app or
/// a website, where an in-app row shows a push chevron.
///
/// Every such row uses this view so the glyph, size, and colour stay
/// the same. It is decorative: the row's own label and hint say where
/// the tap goes.
public struct ExternalLinkIndicator: View {

    public init() {}

    public var body: some View {
        Image.externalLink
            .imageScale(.medium)
            // `Color.secondary`, not `.secondary`: inside a `Link` the
            // hierarchical style takes the link's tint.
            .foregroundStyle(Color.secondary)
            .accessibilityHidden(true)
    }
}

// MARK: - Preview

#Preview {
    List {
        Link(destination: URL(filePath: "/")) {
            HStack {
                Text(verbatim: "Example")
                Spacer()
                ExternalLinkIndicator()
            }
        }
    }
}
